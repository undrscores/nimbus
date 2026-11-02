import re
import shutil
import subprocess
import time
from argparse import Namespace
from datetime import datetime
from pathlib import Path

from nimbus.utils import niri
from nimbus.utils.notify import close_notification, notify
from nimbus.utils.paths import get_config, recording_notif_path, recording_path, recordings_dir

RECORDER = "gpu-screen-recorder"
# Software fallback for machines where gpu-screen-recorder cannot encode (e.g. NVENC/driver mismatch)
FALLBACK = "wf-recorder"
FLATPAK_APP = "com.dec05eba.gpu_screen_recorder"

# Handles the "Recording stopped" notification actions in a tiny detached shell
# process, so `nimbus record` can exit as soon as the recording is saved.
_STOPPED_NOTIF_HANDLER = r"""
path=$1
uri=$2
directory=$3

action=$(notify-send -a nimbus \
    --action=watch=Watch \
    --action=open=Open \
    --action=delete=Delete \
    "Recording stopped" \
    "Recording saved in $path") || exit 0

case "$action" in
    watch)
        exec xdg-open "$path"
        ;;
    open)
        if ! dbus-send --session \
            --dest=org.freedesktop.FileManager1 \
            --type=method_call \
            /org/freedesktop/FileManager1 \
            org.freedesktop.FileManager1.ShowItems \
            "array:string:$uri" \
            "string:"; then
            exec xdg-open "$directory"
        fi
        ;;
    delete)
        rm -f -- "$path"
        ;;
esac
"""


class Command:
    args: Namespace

    def __init__(self, args: Namespace) -> None:
        self.args = args

    def run(self) -> None:
        if self.args.pause:
            subprocess.run(["pkill", "-USR2", "-f", RECORDER], stdout=subprocess.DEVNULL)
        elif self.proc_running():
            self.stop()
        else:
            self.start()

    def flatpak_installed(self) -> bool:
        return (
            shutil.which("flatpak") is not None
            and subprocess.run(["flatpak", "info", "--system", FLATPAK_APP], capture_output=True).returncode == 0
        )

    def proc_running(self) -> bool:
        return subprocess.run(["pidof", RECORDER, FALLBACK], stdout=subprocess.DEVNULL).returncode == 0

    def intersects(self, a: tuple[int, int, int, int], b: tuple[int, int, int, int]) -> bool:
        return a[0] < b[0] + b[2] and a[0] + a[2] > b[0] and a[1] < b[1] + b[3] and a[1] + a[3] > b[1]

    def start(self) -> None:
        args = ["-w"]
        # 30 fps: software AV1 at 1440p cannot keep up with (or accept) a 240+ Hz monitor rate
        fb_args = ["-c", "libsvtav1", "-x", "yuv420p", "-r", "30"]

        monitors = niri.monitors()
        if self.args.region:
            if self.args.region == "slurp":
                region = subprocess.check_output(
                    ["slurp", "-f", "%wx%h+%x+%y"],
                    text=True,
                    stdin=subprocess.DEVNULL,
                )
            else:
                region = self.args.region.strip()
            args += ["region", "-region", region]

            m = re.match(r"(\d+)x(\d+)\+(-?\d+)\+(-?\d+)", region)
            if not m:
                raise ValueError(f"Invalid region: {region}")

            w, h, x, y = map(int, m.groups())
            r = x, y, w, h
            max_rr = 0
            for monitor in monitors:
                if self.intersects((monitor["x"], monitor["y"], monitor["width"], monitor["height"]), r):
                    rr = round(monitor["refreshRate"])
                    max_rr = max(max_rr, rr)
            args += ["-f", str(max_rr)]
            fb_args += ["-g", f"{x},{y} {w}x{h}"]
        else:
            focused_monitor = next((monitor for monitor in monitors if monitor["focused"]), None)
            if focused_monitor:
                args += [
                    focused_monitor["name"],
                    "-f",
                    str(round(focused_monitor["refreshRate"])),
                ]
                fb_args += ["-o", focused_monitor["name"]]

        if self.args.sound:
            args += ["-a", "default_output"]
            fb_args += ["-a"]

        config = get_config()
        try:
            if "record" in config and "extraArgs" in config["record"]:
                args += config["record"]["extraArgs"]
        except TypeError as e:
            raise ValueError(f"Config option 'record.extraArgs' should be an array: {e}")

        recording_path.parent.mkdir(parents=True, exist_ok=True)
        out = str(recording_path)

        # Candidates, tried in order until one stays running:
        #  1. Flatpak gpu-screen-recorder via the screencast portal (bundles NVENC-capable ffmpeg; the
        #     permission is remembered after the first approval). Whole-monitor capture only.
        #  2. System gpu-screen-recorder (KMS capture)
        #  3. wf-recorder software encoding
        candidates = []
        if not self.args.region and self.flatpak_installed():
            fp = [
                "flatpak", "run", "--system", "--command=gpu-screen-recorder", FLATPAK_APP,
                "-w", "portal", "-restore-portal-session", "yes",
                "-portal-session-token-filepath", str(recording_path.parent / "portal-token"),
            ]  # fmt: skip
            if focused := next((m for m in monitors if m["focused"]), None):
                fp += ["-f", str(round(focused["refreshRate"]))]
            if self.args.sound:
                fp += ["-a", "default_output"]
            candidates.append([*fp, "-o", out])
        if shutil.which(RECORDER):
            candidates.append([RECORDER, *args, "-o", out])
        if shutil.which(FALLBACK):
            candidates.append([FALLBACK, *fb_args, "-f", out])

        notif = notify("-p", "Recording started", "Recording...")
        recording_notif_path.write_text(notif)

        failed = ""
        for cmd in candidates:
            # The recorder outlives this command, so it must not inherit our stdio
            proc = subprocess.Popen(
                cmd,
                stdin=subprocess.DEVNULL,
                stdout=subprocess.DEVNULL,
                stderr=subprocess.DEVNULL,
                start_new_session=True,
            )
            try:
                if proc.wait(5) == 0:
                    return
                failed = f"Command `{' '.join(cmd)}` failed with exit code {proc.returncode}"
            except subprocess.TimeoutExpired:
                return  # still running after 5s: started fine

        close_notification(notif)
        notify("Recording failed", failed or "No screen recorder is installed (gpu-screen-recorder or wf-recorder).")

    def stop(self) -> None:
        # Start killing recording process
        subprocess.run(["pkill", "-INT", "-x", FALLBACK], stdout=subprocess.DEVNULL)
        subprocess.run(["pkill", "-INT", "-f", RECORDER], stdout=subprocess.DEVNULL)  # SIGINT: the Flatpak build ignores SIGTERM

        # Wait for recording to finish to avoid corrupted video file
        while self.proc_running():
            time.sleep(0.1)

        # Move to recordings folder
        new_path = recordings_dir / f"recording_{datetime.now().strftime('%Y%m%d_%H-%M-%S')}.mp4"
        recordings_dir.mkdir(exist_ok=True, parents=True)
        shutil.move(recording_path, new_path)

        # Close start notification
        try:
            close_notification(recording_notif_path.read_text())
        except IOError:
            pass

        if self.args.clipboard:
            file_uri = Path(new_path).resolve().as_uri() + "\n"
            subprocess.run(["wl-copy", "--type", "text/uri-list"], input=file_uri.encode())

        recording = new_path.resolve()

        # The action notification's lifetime is the user's interaction with it,
        # not this command's, so hand it off to a detached lightweight handler
        subprocess.Popen(
            [
                "sh",
                "-c",
                _STOPPED_NOTIF_HANDLER,
                "sh",
                str(recording),
                recording.as_uri(),
                str(recording.parent),
            ],
            stdin=subprocess.DEVNULL,
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
            start_new_session=True,
            cwd="/",
        )

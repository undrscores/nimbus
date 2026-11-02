import argparse

from caelestia.subcommands import record, scheme, theme, wallpaper
from caelestia.utils.paths import wallpapers_dir
from caelestia.utils.scheme import get_scheme_names, scheme_variants
from caelestia.utils.wallpaper import get_wallpaper


def parse_args() -> tuple[argparse.ArgumentParser, argparse.Namespace]:
    parser = argparse.ArgumentParser(
        prog="nimbus", description="Helper CLI for the Nimbus shell on niri (wallpaper, scheme, record)"
    )

    command_parser = parser.add_subparsers(
        title="subcommands", description="valid subcommands", metavar="COMMAND", help="the subcommand to run"
    )

    # scheme
    scheme_parser = command_parser.add_parser("scheme", help="manage the colour scheme")
    scheme_command_parser = scheme_parser.add_subparsers(title="subcommands")

    list_parser = scheme_command_parser.add_parser("list", help="list available schemes")
    list_parser.set_defaults(cls=scheme.List)
    list_parser.add_argument("-n", "--names", action="store_true", help="list scheme names")
    list_parser.add_argument("-f", "--flavours", action="store_true", help="list scheme flavours")
    list_parser.add_argument("-m", "--modes", action="store_true", help="list scheme modes")
    list_parser.add_argument("-v", "--variants", action="store_true", help="list scheme variants")

    get_parser = scheme_command_parser.add_parser("get", help="get scheme properties")
    get_parser.set_defaults(cls=scheme.Get)
    get_parser.add_argument("-n", "--name", action="store_true", help="print the current scheme name")
    get_parser.add_argument("-f", "--flavour", action="store_true", help="print the current scheme flavour")
    get_parser.add_argument("-m", "--mode", action="store_true", help="print the current scheme mode")
    get_parser.add_argument("-v", "--variant", action="store_true", help="print the current scheme variant")

    set_parser = scheme_command_parser.add_parser("set", help="set the current scheme")
    set_parser.set_defaults(cls=scheme.Set)
    set_parser.add_argument("--notify", action="store_true", help="send a notification on error")
    set_parser.add_argument("-r", "--random", action="store_true", help="switch to a random scheme")
    set_parser.add_argument("-n", "--name", choices=get_scheme_names(), help="the name of the scheme to switch to")
    set_parser.add_argument("-f", "--flavour", help="the flavour to switch to")
    set_parser.add_argument("-m", "--mode", choices=["dark", "light"], help="the mode to switch to")
    set_parser.add_argument("-v", "--variant", choices=scheme_variants, help="the variant to switch to")

    # theme
    theme_parser = command_parser.add_parser("theme", help="apply the scheme to other apps (alacritty, niri, gtk, qt, zed)")
    theme_command_parser = theme_parser.add_subparsers(title="subcommands")

    theme_apply_parser = theme_command_parser.add_parser("apply", help="re-apply the current scheme to all apps")
    theme_apply_parser.set_defaults(cls=theme.Apply)
    theme_apply_parser.add_argument(
        "-o", "--opacity", type=float, metavar="0-1", help="window opacity for themed apps (default: shell setting)"
    )

    theme_setup_parser = theme_command_parser.add_parser(
        "setup", help="one-time wiring of alacritty/niri/zed configs to the generated colours"
    )
    theme_setup_parser.set_defaults(cls=theme.Setup)

    # record
    record_parser = command_parser.add_parser("record", help="start a screen recording")
    record_parser.set_defaults(cls=record.Command)
    record_parser.add_argument("-r", "--region", nargs="?", const="slurp", help="record a region")
    record_parser.add_argument("-s", "--sound", action="store_true", help="record audio")
    record_parser.add_argument("-p", "--pause", action="store_true", help="pause/resume the recording")
    record_parser.add_argument("-c", "--clipboard", action="store_true", help="copy recording path to clipboard")

    # wallpaper
    wallpaper_parser = command_parser.add_parser("wallpaper", help="manage the wallpaper")
    wallpaper_parser.set_defaults(cls=wallpaper.Command)
    wallpaper_parser.add_argument(
        "-p", "--print", nargs="?", const=get_wallpaper(), metavar="PATH", help="print the scheme for a wallpaper"
    )
    wallpaper_parser.add_argument(
        "-r", "--random", nargs="?", const=wallpapers_dir, metavar="DIR", help="switch to a random wallpaper"
    )
    wallpaper_parser.add_argument("-f", "--file", help="the path to the wallpaper to switch to")
    wallpaper_parser.add_argument("-n", "--no-filter", action="store_true", help="do not filter by size")
    wallpaper_parser.add_argument(
        "-t",
        "--threshold",
        default=0.8,
        help="the minimum percentage of the largest monitor size the image must be greater than to be selected",
    )
    wallpaper_parser.add_argument(
        "-N",
        "--no-smart",
        action="store_true",
        help="do not automatically change the scheme mode based on wallpaper colour",
    )

    return parser, parser.parse_args()

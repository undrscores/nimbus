from caelestia.parser import parse_args
from caelestia.utils.io import log


def main() -> None:
    try:
        parser, args = parse_args()
        if "cls" in args:
            args.cls(args).run()
        else:
            parser.print_help()
    except KeyboardInterrupt:
        log("Exiting...")

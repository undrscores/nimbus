from argparse import Namespace

from caelestia.utils.scheme import get_scheme
from caelestia.utils.theme import apply_colours, set_opacity_override, setup


class Apply:
    args: Namespace

    def __init__(self, args: Namespace) -> None:
        self.args = args

    def run(self) -> None:
        if self.args.opacity is not None:
            set_opacity_override(self.args.opacity)
        scheme = get_scheme()
        apply_colours(scheme.colours, scheme.mode)


class Setup:
    args: Namespace

    def __init__(self, args: Namespace) -> None:
        self.args = args

    def run(self) -> None:
        scheme = get_scheme()
        setup(scheme.colours, scheme.mode)

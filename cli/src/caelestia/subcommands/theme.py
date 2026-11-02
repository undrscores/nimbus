from argparse import Namespace

from caelestia.utils.scheme import get_scheme
from caelestia.utils.theme import apply_colours, setup


class Apply:
    args: Namespace

    def __init__(self, args: Namespace) -> None:
        self.args = args

    def run(self) -> None:
        scheme = get_scheme()
        apply_colours(scheme.colours, scheme.mode)


class Setup:
    args: Namespace

    def __init__(self, args: Namespace) -> None:
        self.args = args

    def run(self) -> None:
        scheme = get_scheme()
        setup(scheme.colours, scheme.mode)

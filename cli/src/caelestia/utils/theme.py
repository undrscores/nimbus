def apply_colours(colours: dict[str, str], mode: str) -> None:
    """Hook for applying a scheme to other apps.

    The upstream CLI templates terminals, GTK, Discord etc. here. This niri port only
    maintains the scheme state the shell reads (see utils/scheme.py), so there is nothing to do.
    """

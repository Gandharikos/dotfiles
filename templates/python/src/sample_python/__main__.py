"""Command-line entry point for the example application."""

import argparse

from sample_python import __version__, greeting


def main() -> None:
    parser = argparse.ArgumentParser(description="Print a greeting")
    parser.add_argument("name", default="Nix", nargs="?", help="name to greet")
    parser.add_argument("--version", action="version", version=f"%(prog)s {__version__}")
    args = parser.parse_args()
    print(greeting(args.name))


if __name__ == "__main__":
    main()

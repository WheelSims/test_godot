#!/usr/bin/env python
"""
Check code quality before creating a code request.

You must install gdtoolkit beforehand:

pip install gdtoolkit

"""

import subprocess


def _run_and_print(command: list[str]) -> None:
    """Run command and print the result in console."""
    try:
        output = subprocess.check_output(command).decode()
        print(output)
    except subprocess.CalledProcessError as e:
        error_output: str = (e.output or b"").decode()
        for line in error_output.split("\n"):
            print(line)


def run_style_formatter() -> None:  # pragma: no cover
    """Run style formatter (gdformat)."""
    print("========================================")
    print("Running gdformat...")
    _run_and_print(["gdformat", "src"])


def run_linter() -> None:  # pragma: no cover
    """Run code quality review (gdlint)."""
    print("========================================")
    print("Code Quality Review (gdlint)")
    _run_and_print(["gdlint", "src"])


if __name__ == "__main__":  # pragma: no cover
    run_style_formatter()
    run_linter()
    print("========================================")
    print("Completed.")
    print("Do not forget to merge main into your")
    print("branch and run these checks again.")
    print("========================================")

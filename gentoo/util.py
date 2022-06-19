from getpass import getpass
import sys


class fmt:
    ENDC = "\033[0m"
    BOLD = "\033[1m"
    RED = "\033[91m"
    GREEN = "\033[92m"
    YELLOW = "\033[93m"


class sym:
    SYM = f"{fmt.BOLD}::{fmt.ENDC}"
    WARN = f"{fmt.YELLOW}{SYM}"
    ERR = f"{fmt.RED}{SYM}"
    OK = f"{fmt.GREEN}{SYM}"


def list(list: list, selection: str):
    list_iter = enumerate(list)
    while True:
        for i, item in list_iter:
            print(f"  {i}) {item}")

        try:
            choice = list[int(input(f"{sym.SYM} select {selection}: "))]
        except (IndexError, ValueError):
            print(f"{sym.WARN} select a valid index")
            continue
        break

    return choice


def getrootpasswd() -> str:
    while True:
        rootpasswd = getpass(f"{sym.SYM} root password?: ")
        if getpass(f"{sym.SYM} again: ") == rootpasswd:
            break
        print(f"{sym.WARN} passwords do not match, try again")

    return rootpasswd


def promptyn(msg: str) -> bool:
    while True:
        match input(f"{sym.SYM} {msg}? [y/n]: ").lower():
            case "y" | "yes":
                return True
            case "n" | "no":
                return False
            case _:
                print(f"{sym.WARN} invalid response")


def ok(msg: str) -> None:
    print(f"{sym.OK} {msg}")


def fail(msg: str) -> None:
    sys.exit(f"{sym.ERR} {msg}")

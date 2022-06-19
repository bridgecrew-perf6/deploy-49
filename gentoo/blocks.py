import subprocess
from dataclasses import dataclass


@dataclass
class BlockDevice:
    path: str
    string: str

    def __str__(self):
        return self.string


def get_block_devices() -> list[BlockDevice]:
    blockdevices = []

    infos = subprocess.run(
        "lsblk -ldpno NAME,SIZE,MODEL".split(), capture_output=True, text=True
    ).stdout.splitlines()

    for info in infos:
        blockdevices.append(BlockDevice(info.split()[0], info))

    return blockdevices

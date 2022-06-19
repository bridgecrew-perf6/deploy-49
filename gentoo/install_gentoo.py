#!/usr/bin/env python

import os
import subprocess

from glob import glob

import blocks
import util


TARBALL_PATH = "files/stage3/"
MAKE_CONF_PATH = "files/portage/make.conf"


if __name__ == "__main__":
    if os.geteuid() != 0:
        util.fail("you must run this script as root")

    if not glob(TARBALL_PATH + "stage3-*.tar.xz"):
        util.fail("no tarballs found")

    if not os.path.exists("files/portage/make.conf"):
        util.fail("no make.conf found")

    device = util.list(blocks.get_block_devices(), "disk")
    tarball = util.list(os.listdir(TARBALL_PATH), "tarball")
    root_passwd = util.getrootpasswd()

    if not util.promptyn(f"format {device.path}"):
        util.fail("exiting script")

    subprocess.run(
        f"./install.sh {device.path} {TARBALL_PATH + tarball} {root_passwd}".split()
    )
    util.ok("installation complete")

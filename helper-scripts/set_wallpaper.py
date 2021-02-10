#!/usr/bin/env python

"""set-wallpaper.py
A script to set the desktop wallpaper on macOS.
"""

###############################################################################
#
#   DESCRIPTION:
#
#
#       Uses Cocoa classes via PyObjC to set a desktop picture on all screens.
#       Tested on Mountain Lion and Mavericks. Inspired by Greg Neagle's work:
#
#           https://gist.github.com/gregneagle/6957826
#
#       Modified from @gramhamgilbert's script:
#
#       https://github.com/grahamgilbert/macscripts/blob/master/set_desktops/
#       set_desktops.py
#
#       Removed the ability to define a file path via argparse. Defines the
#       path to the image dynamically in the script. The image should live in
#       the same location where the script is being executed.
#
#       The onlythings hardcoded in the script are the name of the image and
#       the image location. In this case the PICTURE_NAME is set to
#       "stock_wallpaper.png"
#
#   SEE:
#
#       https://developer.apple.com/documentation/appkit/nsworkspace
#
#       https://developer.apple.com/documentation/foundation/nsurl
#
#       https://developer.apple.com/documentation/appkit/nsscreen
#
###############################################################################


import sys
import os

from AppKit import NSWorkspace, NSScreen
from Foundation import NSURL

__version__ = "2.0.1"

HERE = os.path.abspath(os.path.dirname(__file__))
PICTURE_NAME = "stock_wallpaper.png"
PICTURE_PATH = os.path.join("/Library", "Desktop Pictures", PICTURE_NAME)


def verify_file_extension():
    """Verify that file extension is set to png"""
    if not PICTURE_NAME.endswith(".png"):
        print("ERROR: Make sure that you are using a PNG file for your desktop image.")
        print(f"Picture Name: {PICTURE_PATH}")
        sys.exit(1)


def gen_file_url(path):
    """generate a fileURL for the desktop picture"""
    file_url = NSURL.fileURLWithPath_(path)
    return file_url


def get_shared_workspace():
    """get shared workspace"""
    work_space = NSWorkspace.sharedWorkspace()
    return work_space


def apply_desktop_wallpaper(work_space, url):
    """Apply desktop wallpaper"""

    # make image options dictionary
    # we just make an empty one because the defaults are fine
    options = {}

    # iterate over all screens
    for screen in NSScreen.screens():
        # tell the workspace to set the desktop picture
        result = work_space.setDesktopImageURL_forScreen_options_error_(
            url, screen, options, None
        )

        for item in result:

            if item is True:
                print("Wallpaper applied!")
                break


def main():
    """The main event."""

    workspace = get_shared_workspace()
    file_url = gen_file_url(path=PICTURE_PATH)

    verify_file_extension()
    apply_desktop_wallpaper(work_space=workspace, url=file_url)


if __name__ == "__main__":
    main()

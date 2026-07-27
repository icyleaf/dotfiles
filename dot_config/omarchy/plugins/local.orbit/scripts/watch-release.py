#!/usr/bin/env python3
"""Watch evdev for a mouse-button release and tell Orbit to release.

Hyprland's release binds are reliable for keyboard keys, but extra mouse
buttons exposed through some Logitech receivers do not always fire a release
bind after Orbit's layer-shell overlay appears. This small helper listens at
input-device level instead. It is started by orbit-press.sh before the overlay
is summoned, then exits on the first matching release or after a timeout.
"""

from __future__ import annotations

import argparse
import os
import select
import subprocess
import sys
import time
from contextlib import suppress

from evdev import InputDevice, ecodes, list_devices


def key_codes_for(device: InputDevice) -> set[int]:
    try:
        keys = device.capabilities().get(ecodes.EV_KEY, [])
    except OSError:
        return set()
    return {int(code[0] if isinstance(code, tuple) else code) for code in keys}


def main() -> int:
    parser = argparse.ArgumentParser(description="watch for an evdev button release")
    parser.add_argument("button", type=int, help="evdev/Wayland button code, e.g. 278")
    parser.add_argument("--timeout", type=float, default=12.0)
    args = parser.parse_args()

    devices: list[InputDevice] = []
    for path in list_devices():
        with suppress(Exception):
            device = InputDevice(path)
            if args.button in key_codes_for(device):
                devices.append(device)

    if not devices:
        return 2

    poller = select.poll()
    fd_to_device = {}
    for device in devices:
        try:
            poller.register(device.fd, select.POLLIN)
            fd_to_device[device.fd] = device
        except OSError:
            with suppress(Exception):
                device.close()

    deadline = time.monotonic() + max(0.1, args.timeout)
    try:
        while True:
            remaining = deadline - time.monotonic()
            if remaining <= 0:
                return 1

            for fd, _event_mask in poller.poll(int(remaining * 1000)):
                device = fd_to_device.get(fd)
                if not device:
                    continue

                with suppress(OSError):
                    for event in device.read():
                        if event.type == ecodes.EV_KEY and event.code == args.button and event.value == 0:
                            subprocess.run(
                                ["omarchy-shell", "shell", "call", "local.orbit", "release", ""],
                                stdout=subprocess.DEVNULL,
                                stderr=subprocess.DEVNULL,
                                check=False,
                                env=os.environ.copy(),
                            )
                            return 0
    finally:
        for device in devices:
            with suppress(Exception):
                device.close()


if __name__ == "__main__":
    sys.exit(main())

# Divisé

---------

## arm64 Dualbooting

Divisé is able to install a second iOS/iPadOS version alongside your device's existing iOS/iPadOS install. It does this by creating two new APFS volumes, SystemB and DataB, then uses rsync to restore a downloaded root filesystem image to the new volumes and finally Divisé IDK WRITE SOMETHING HERE. 

The actual process is more complicated then this but this README will not go into that much detail. If you would like to learn more about dualbooting arm64 devices, you can read this applications source code, you can read [this mini-writeup](https://moski.fun/dualboot/) written by me about ramdiskless arm64 dualboots or you can read [the original arm64 dualbooting guide](https://dualbootfun.github.io/dualboot/) written by [@mcg29_ ](https://twitter.com/mcg29_) and [@Ralph0045](https://twitter.com/Ralph0045).

## arm64 Tethered Downgrades

Divisé performs a tethered downgrade on arm64 devices by overwriting the currently installed iOS/iPadOS install with a downloaded root filesystem image. This differs from a dualboot as the main iOS/iPadOS install is not modified in any way during a dualboot, allowing the device to continue to boot the main OS untethered, whereas in a tethered downgrade the main OS is completly gone preventing any untethered boot until a signed iOS/iPadOS version is restored.

## Booting after dualbooting/tethered downgrading

arm64 dualboots/tethered downgrades are tethered, as the only current way to boot into the second OS is via the checkm8 bootrom exploit which supports A7-A11 devices. There is no way to boot other then via a computer (or iOS/iPadOS device via an OTG cable) and there are currently 3 options for tether booting from said computer. The first way is via manually patching and preparing the required files (Advanced users only), PyBoot which is a python CLI script made by me which automates the entire process (Moderate difficultly) and there is Ramiel which is a GUI based applicaiton for checkm8 related tasks/actions (Easiest/Best choice). 

## Compiling

*I really dont anticipate that anyone will ever attempt to compile this project... but... here goes* ¯\\\_(ツ)_/¯

Requires macOS, and probably a fairly recent version of it. 

Requires `fakeroot`, `ldid`, and `dpkg`. If you dont have them already, they can be easily installed using [homebrew](https://brew.sh):

`brew install fakeroot`

`brew install ldid`

`brew install dpkg`

You may need to edit "succdatroot/Makefile" and change the theos directory from "~/.theos" to "$THEOS" or where ever you have Theos setup. Also edit "compile" and change the IP address to your device's. 

You will need a fairly recent version of theos set up, you can follow their install tutorial [here](https://github.com/theos/theos/wiki/Installation-macOS)

To compile and install Divisé to your device, simply run `make package install THEOS_DEVICE_IP=192.168.1.100`, swapping in your devices IP address. Then enter your computers password, then the devices root password when prompted and, after a respring, Divisé will be installed!

***Note**: The install part will only work if you have OpenSSH installed on your iOS device.*

## License
This project is licensed under the GNU General Public License v3.0, with accordance to [rsync](https://rsync.samba.org/) and [Zebra](https://github.com/wstyres/Zebra). If you'd like to support the project or my development, you can donate [here](https://paypal.me/SamGardner4). **Donations are not a requirement, but highly appreciated!**

Special thanks to [PsychoTea](https://twitter.com/iBSparkes), [Pwn20wnd](https://twitter.com/Pwn20wnd), [Cryptiiic](https://github.com/Cryptiiiic), and [Nobbele](https://github.com/nobbele) for their respective contributions to this project.

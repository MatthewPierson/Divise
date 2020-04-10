# SuccessionDown

---------

## Tethered Downgrades

Either compile and install yourself or [add my repo](http://matthewpierson.github.io) and install it from there

This fork is purely for tethered downgrades! This is likely very unstable, probably won't work and might damage your device. It will probably be fine but be warned. 

To perform a tethered downgrade using this, simply open the app, click "Download clean filesystem", enter what iOS version you wish to downgrade to and let it do it's stuff!

You are still restricted by SEP compatibility, which the app will check after you input an iOS version. The app will also not let non-checkm8 devices nuke their iOS install by running this.

Apple is still blocking older IPSW downloads, seemingly at random, so if you are unable to download one iOS version either try again, wait a few hours and try again or pick a different iOS version. 

DO NOT, I repeat, DO NOT annoy/message/spam/question Samg_is_a_Ninja about any issues that occur with this fork, please direct all of them to me as I don't want him to have to deal with the various issues this fork will likely have. Either on [twitter](https://twitter.com/mosk_i) or here on GitHub.

-------------

Alternative to Cydia Eraser that is much easier to update. Downloads and mounts rootfilesystem DMG for your iOS version. Then moves files from mounted DMG to the main filesystem.

Special thanks to @pwn20wndstuff, @PsychoTea, @Cryptiiic, @4ppleCracker for their respective contributions to this project.

This project is free (and always will be), donations are never required but highly appreciated: https://paypal.me/SamGardner4

*rsync used in accordance with gpl3*

*attach generously provided by comex*

## Device Support

A8(x) and A9(x) support will come when checkm8 supports them

- iPhone 5s
- iPhone 7/7 Plus
- iPhone 8/8 Plus
- iPhone X

- iPad 6th Gen
- iPad 7th Gen
- iPad Mini 2/3
- iPad Air
- iPad Pro (Whichever ones are A10(x)/A11(x) should work fine c: )

- iPod 7th Gen

If you want a full list/more details, download [this plist](http://matthewpierson.github.io/sep.plist) and look through it!

## Compiling
*I really don't anticipate anyone ever attempting to compile this project... but here it goes* ¯\\\_(ツ)_/¯

In order to compile Succession, you'll need a fairly recent version of macOS with `fakeroot`, `ldid`, and `dpkg` installed. If you do not have these dependencies, you can easily installed them by using [Homebrew](https://brew.sh):
```
$ brew install fakeroot
$ brew install ldid
$ brew install dpkg
```

As of Succession 1.4.12, you will need a fairly recent version of theos set up, you can follow their install tutorial [here](https://github.com/theos/theos/wiki/Installation-macOS)

Once you have these dependencies, clone Succession using [Git](https://git-scm.com/downloads):
```
$ git clone https://github.com/Samgisaninja/SuccessionRestore.git
```
Compiling is fairly simple afterwards, thanks to the `compile` and `install` scripts provided in the root directory of the project. You can use them to compile and install Succession directly onto your device.

***Note**: The `install` script will only work if you have OpenSSH installed on your iOS device.*

## License
This project is licensed under the GNU General Public License v3.0, with accordance to [rsync](https://rsync.samba.org/) and [Zebra](https://github.com/wstyres/Zebra). If you'd like to support the project or my development, you can donate [here](https://paypal.me/SamGardner4). **Donations are not a requirement, but highly appreciated!**

You may need to edit "succdatroot/Makefile" and change the theos directory from "~/.theos" to "$THEOS" or where ever you have Theos setup. Also edit "compile" and change the IP address to your device's. 

You will need a fairly recent version of theos set up, you can follow their install tutorial [here](https://github.com/theos/theos/wiki/Installation-macOS)

Compiling is fairly simple afterwards, thanks to the `compile` script provided in the root directory of the project. You can use it to compile and install Succession directly onto your device.

***Note**: The install part of the `compile` script will only work if you have OpenSSH installed on your iOS device.*

## License
This project is licensed under the GNU General Public License v3.0, with accordance to [rsync](https://rsync.samba.org/) and [Zebra](https://github.com/wstyres/Zebra). If you'd like to support the project or my development, you can donate [here](https://paypal.me/SamGardner4). **Donations are not a requirement, but highly appreciated!**

Special thanks to [PsychoTea](https://twitter.com/iBSparkes), [Pwn20wnd](https://twitter.com/Pwn20wnd), [Cryptiiic](https://github.com/Cryptiiiic), and [Nobbele](https://github.com/nobbele) for their respective contributions to this project.

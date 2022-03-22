<<<<<<< HEAD
# Nextcloud Desktop Client

The :computer: Nextcloud Desktop Client is a tool to synchronize files from Nextcloud Server
with your computer.

<p align="center">
    <img src="doc/images/main_dialog_christine.png" alt="Desktop Client on Windows" width="450">
</p>

## :blue_heart: :tada: Contributing

### :hammer_and_wrench: How to compile the desktop client

:building_construction: [System requirements](https://github.com/nextcloud/desktop/wiki/System-requirements-for-compiling-the-desktop-client) includes OpenSSL 1.1.x, QtKeychain, Qt 5.x.x and zlib.

#### :memo: Step by step instructions

##### Clone the repo and create build directory
```
$ git clone https://github.com/nextcloud/desktop.git
$ cd desktop
$ mkdir build
$ cd build
```
##### Compile and install

:warning: For development reasons it is better to **install the client on user space** instead on the global system. Mixing up libs/dll's of different version can lead to undefined behavior and crashes:

* You could use the **cmake flag** ```CMAKE_INSTALL_PREFIX``` as ```~/.local/``` in a **Linux** system. If you want to install system wide you could use ```/usr/local``` or ```/opt/nextcloud/```.

* On **Windows 10** [```$USERPROFILE```](https://docs.microsoft.com/en-us/windows/deployment/usmt/usmt-recognized-environment-variables#a-href-idbkmk-2avariables-that-are-recognized-only-in-the-user-context) refers to ```C:\Users\<USERNAME>```.

##### Linux & Mac OS

```
$ cmake .. -DCMAKE_INSTALL_PREFIX=~/nextcloud-desktop-client -DCMAKE_BUILD_TYPE=Debug
$ make install
```

##### Windows

```
$ cmake -G "Visual Studio 15 2017 Win64" .. -DCMAKE_INSTALL_PREFIX=$USERPROFILE\nextcloud-desktop-client -DCMAKE_BUILD_TYPE=Debug
$ cmake --build . --config Debug --target install
```

:information_source: More detailed instructions can be found at the [Desktop Client Wiki](https://github.com/nextcloud/desktop/wiki).

### :inbox_tray: Where to find binaries to download

#### :high_brightness: Daily builds

- Daily builds based on the latest master are available for Linux :penguin:, Mac, and Windows
[in the desktop/daily folder of our download server](https://download.nextcloud.com/desktop/daily).
For more info: [Wiki/Daily Builds](https://github.com/nextcloud/desktop/wiki/Daily-Builds).

#### :rocket: Releases

- Refer to the [download page https://nextcloud.com/install/#install-clients](https://nextcloud.com/install/#install-clients)

### :bomb: Reporting issues

- If you find any bugs or have any suggestion for improvement, please
file an issue at https://github.com/nextcloud/desktop/issues. Do not
contact the authors directly by mail, as this increases the chance
of your report being lost. :boom:

### :smiley: :trophy: Pull requests

- If you created a patch :heart_eyes:, please submit a [Pull
Request](https://github.com/nextcloud/desktop/pulls).
- How to create a pull request? This guide will help you get started: [Opening a pull request](https://opensource.guide/how-to-contribute/#opening-a-pull-request) :heart:


## :satellite: Contact us

If you want to contact us, e.g. before starting a more complex feature, for questions :question:
you can join us at
[#nextcloud-client](https://webchat.freenode.net/?channels=nextcloud-client).

## :v: Code of conduct

The Nextcloud community has core values that are shared between all members during conferences, hackweeks and on all interactions in online platforms including [Github](https://github.com/nextcloud) and [Forums](https://help.nextcloud.com). If you contribute, participate or interact with this community, please respect [our shared values](https://nextcloud.com/code-of-conduct/). :relieved:

## :memo: Source code

The Nextcloud Desktop Client is developed in Git. Since Git makes it easy to
fork and improve the source code and to adapt it to your need, many copies
can be found on the Internet, in particular on GitHub. However, the
authoritative repository maintained by the developers is located at
https://github.com/nextcloud/desktop.

## :scroll: License

    This program is free software; you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation; either version 2 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful, but
    WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
    or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License
    for more details.
=======
libcrashreporter-qt
===================

This library is supposed to provide an easy integration of Google Breakpad crash reporting into a Qt application

#### Features
* Cross-platform (Linux and Windows currently, macOS)
* Simple API to launch an external crash reporter GUI

#### License

The library itself is licensed LGPLv2.1, but the drkonqi integration for Linux is licensed GPL.
If you need the drkonqi integration, you need to use this lib as GPLv2.

#### TODO
* Add documentation/examples
* Make lib installable/packagable
* Tell me!

#### FAQ

###### Is this stable?
Nope.

###### Does it work?
It does for me.

###### Why don't you write a CMake script to link against an external BreakPad release?
BreakPad release?!

###### Why is the code so ugly?
Because I'm waiting for your pull request to clean it up.

###### Do you actually know what you're doing with all the string conversions?
No.

###### How do I install it?
Not at all right now. It's used as a submodule for now.


#### Contact
\#tomahawk on Freenode
>>>>>>> libcrashreporter/master

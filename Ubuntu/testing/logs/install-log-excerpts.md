# Install log excerpts

Failure lines before the fixes and milestone lines after them, from the runs
described in ../../REPORT-Ubuntu-25.04-and-above.md (full logs are 25,000+ lines each).

```text

## A-release-25.04
Detected Ubuntu Version: 
Unsupported Ubuntu version: 25.04 ()
EXIT=1

## B-head-dispatcher-25.04
EXIT=2
./install-eSim.sh: line 70: syntax error near unexpected token `}'
./install-eSim.sh: line 70: `}'

## N-nghdl-head-25.04 (installers-branch NGHDL)
is only available from another source

Error: Package 'libcanberra-gtk-module' has no installation candidate


Error! Kindly resolve above error(s) and try again.

## N1-nghdl-25.04 (canberra skipped)
Build machine is: x86_64-linux-gnu
Unhandled version llvm 20.1.2


Error! Kindly resolve above error(s) and try again.


## C-head-25.04-script (Launchpad 503)
E: Failed to fetch https://ppa.launchpadcontent.net/kicad/kicad-8.0-releases/ubuntu/pool/main/k/kicad-library-symbols/kicad-symbols_8.0.9%7eubuntu25.04.1_all.deb  503  Service Unavailable [IP: 185.125.189.186 443]
E: Unable to fetch some archives, maybe run apt-get update or try with --fix-missing?


## KiCad PPA build without the pin (25.04)
The following packages have unmet dependencies:
 kicad : Depends: libgit2-1.8 (>= 1.8.0) but it is not installable
E: Unable to correct problems, you have held broken packages.
   1. kicad:amd64=8.0.9-0~ubuntu25.04.1 is selected for install
   2. kicad:amd64=8.0.9-0~ubuntu25.04.1 Depends libgit2-1.8 (>= 1.8.0)
      but none of the choices are installable:

## GHDL with llvm-config-18 but default CXX (25.04)
clang++ -c `/usr/bin/llvm-config-18 --cxxflags` -g -Wall -g -o llvm-cbindings.o src/ortho/llvm6/llvm-cbindings.cpp
/bin/sh: 1: clang++: not found
make[1]: *** [src/ortho/llvm6/Makefile:20: llvm-cbindings.o] Error 127

## KiCad 8 PPA on 25.10 (before the PPA fallback)
Err:5 https://ppa.launchpadcontent.net/kicad/kicad-8.0-releases/ubuntu questing Release
  404  Not Found
E: The repository 'https://ppa.launchpadcontent.net/kicad/kicad-8.0-releases/ubuntu questing Release' does not have a Release file.

## issue6-rerun-old-25.04
Installing KiCad...........................
Ubuntu 25.04 detected.
KiCad 8.0 is already installed.
INSTALLER_EXIT=0

## F-fixed-25.10 (GCC 15, before -std=gnu17)
../../../src/include/ngspice/bool.h:6:13: error: 'bool' cannot be defined via 'typedef'
    6 | typedef int bool;
      |             ^~~~
../../../src/include/ngspice/bool.h:6:13: note: 'bool' is a keyword with '-std=c23' onwards

## F-final-25.04 (all fixes)
Detected Ubuntu Version: 25.04
Installing KiCad 8 from the Ubuntu archive (no PPA needed).
Setting up kicad (8.0.8+dfsg-1) ...
Using updated NGHDL installer: /home/esim/eSim-2.5/install-eSim-scripts/nghdl/install-nghdl.sh
Installing LLVM 18 (newest version supported by ghdl-4.1.0)...
GHDL installed successfully
Verilator installed successfully
NGHDL installed sucessfully
-----------------eSim Installed Successfully-----------------
INSTALLER_EXIT=0

## F-final-25.10 (all fixes)
Detected Ubuntu Version: 25.10
Setting up kicad (9.0.3+dfsg-1) ...
WARNING: KiCad 9 installed (eSim 2.5 is tested with KiCad 8).
Using updated NGHDL installer: /home/esim/eSim-2.5/install-eSim-scripts/nghdl/install-nghdl.sh
Installing LLVM 18 (newest version supported by ghdl-4.1.0)...
GHDL installed successfully
Verilator installed successfully
NGHDL installed sucessfully
-----------------eSim Installed Successfully-----------------
INSTALLER_EXIT=0

## F-final-26.04 (all fixes)
Detected Ubuntu Version: 26.04
Setting up kicad (9.0.8+dfsg-1) ...
WARNING: KiCad 9 installed (eSim 2.5 is tested with KiCad 8).
Using updated NGHDL installer: /home/esim/eSim-2.5/install-eSim-scripts/nghdl/install-nghdl.sh
Installing LLVM 18 (newest version supported by ghdl-4.1.0)...
GHDL installed successfully
Verilator installed successfully
NGHDL installed sucessfully
-----------------eSim Installed Successfully-----------------
INSTALLER_EXIT=0
```

# Installing eSim 2.5 on Ubuntu 25.04 and newer: problems and fixes

Screening Task 4 (eSim Upgradation), eSim Winter Internship 2026
Author: Mahim Agarwal (GitHub: Mahim56207)
Date: 23 November 2026

## Contents

1. [Summary](#1-summary)
2. [Test setup](#2-test-setup)
3. [List of problems](#3-list-of-problems)
4. [Details of each problem and fix](#4-details-of-each-problem-and-fix)
5. [Files changed](#5-files-changed)
6. [Results after the fixes](#6-results-after-the-fixes)
7. [Open points](#7-open-points)
8. [How to repeat the tests](#8-how-to-repeat-the-tests)
9. [References](#9-references)

## 1. Summary

eSim 2.5 did not install on Ubuntu 25.04.

- The eSim-2.5.zip from the website stops at once with
  "Unsupported Ubuntu version: 25.04".
- The `install-eSim.sh` file on the `installers` branch does not run at all,
  because of a syntax error.

After fixing these two, I found 14 more problems. In total I found
**16 problems** and fixed **15**. The last one needs no code change.

With the fixes, eSim 2.5 installs fully on **Ubuntu 25.04, 25.10 and 26.04**.
On all three, eSim and NGHDL start, GHDL compiles and runs a VHDL file, and
ngspice runs a simulation.

## 2. Test setup

| Item | Details |
| --- | --- |
| Ubuntu 25.04 | Clean system, Python 3.13, GCC 14, default LLVM 20, KiCad 8.0.8 in Ubuntu's own repository |
| Ubuntu 25.10 | Clean system, GCC 15, default LLVM 20, KiCad 9.0.3 in Ubuntu's own repository |
| Ubuntu 26.04 LTS | Clean system, GCC 15, default LLVM 21, KiCad 9.0.8 in Ubuntu's own repository |
| User | Normal user with `sudo`, as on a desktop install |
| eSim package | eSim-2.5.zip from the eSim website (released 3 July 2025), and the same package built from the eSim and NGHDL GitHub repositories |

Each Ubuntu system was made with `debootstrap` and run in Docker, so every
test started from a fresh system.

For each test I ran:

```bash
unzip eSim-2.5.zip
cd eSim-2.5
./install-eSim.sh --install
```

I answered `n` to the proxy question and saved the full output. After every
fix, I ran the whole installation again on a fresh system.

## 3. List of problems

| No. | Problem | Effect | Fixed |
| --- | --- | --- | --- |
| 1 | Installer does not know Ubuntu 25.04 | Install stops at the start | Yes |
| 2 | Syntax error in `install-eSim.sh` (installers branch) | Install stops at the start | Yes |
| 3 | `apt install` without `-y` | Install stops when run from a script | Yes |
| 4 | `hdlparse` from PyPI fails on Python 3.13 | Only if the GitHub install fails | No change needed |
| 5 | KiCad 8 from the PPA cannot be installed on 25.04 | KiCad install fails or mixes versions | Yes |
| 6 | Second run of the installer skips NGHDL | NGHDL, SKY130 and shortcut missing | Yes |
| 7 | Launchpad server error 503 | Install stops | Yes |
| 8 | KiCad symbol table copied to the wrong folder | eSim symbols missing in KiCad | Yes |
| 9 | KiCad 8 PPA has no packages for 25.10 and 26.04 | Install stops | Yes |
| 10 | Desktop folder name differs by language | Install stops at the last step | Yes |
| 11 | `nghdl.zip` contains the old NGHDL installer | Problems 12 to 16 appear | Yes |
| 12 | `libcanberra-gtk-module` removed from Ubuntu | NGHDL install stops | Yes |
| 13 | GHDL 4.1.0 does not accept LLVM 20 | NGHDL install stops | Yes |
| 14 | `clang++` not found | NGHDL install stops | Yes |
| 15 | ngspice does not compile with GCC 15 | NGHDL install stops on 25.10 and 26.04 | Yes |
| 16 | Small bugs in the NGHDL script | Uninstall does not remove LLVM | Yes |

## 4. Details of each problem and fix

### Main installer: `install-eSim.sh`

#### Problem 1: Ubuntu 25.04 is not supported

Error:

```
Detected Ubuntu Version:
Unsupported Ubuntu version: 25.04 ()
```

Cause:

- The installer only knows Ubuntu 22.04, 23.04 and 24.04.
- It reads the version with the pattern `\d+\.\d+\.\d+`, which needs three
  numbers (like 22.04.4). Ubuntu 25.04 has only two, so the version is empty.

Fix:

- Ubuntu 25.04, 25.10 and 26.04 now use `install-eSim-25.04.sh`.
- Newer versions also use it, with a warning.
- The version pattern now accepts two or three numbers.

#### Problem 2: Syntax error in `install-eSim.sh`

Error:

```
./install-eSim.sh: line 70: syntax error near unexpected token `}'
```

Cause:

- A merge on 29 May 2026 (commit `52d77f6`) mixed two versions of the file.
- Even the version before it (`5224460`) was broken: the function that picks
  the script for each Ubuntu version had lost its `case` block.
- I found this by running `bash -n` on each old version of the file.

Fix:

- I rewrote `install-eSim.sh` as a short, clean script that only detects the
  Ubuntu version and runs the matching script. This fixes problems 1 and 2.

### Script for Ubuntu 25.04: `install-eSim-scripts/install-eSim-25.04.sh`

#### Problem 3: `apt install` asks for confirmation

Error:

```
Continue? [Y/n] Abort.
```

Cause: `sudo apt install python3-virtualenv` has no `-y`. When the input
does not come from a keyboard, apt stops.

Fix: added `-y`.

#### Problem 4: `hdlparse` does not install from PyPI on Python 3.13

Error (only if the earlier GitHub install fails):

```
error in hdlparse setup command: use_2to3 is invalid.
```

Cause: the PyPI version (1.0.4) uses an old setup option that new setuptools
removed. The GitHub version (1.0.7) installs fine.

Fix: no change needed. The script already installs the GitHub version first.

#### Problem 5: KiCad 8 from the PPA cannot be installed on 25.04

Error (without the version pin in the script):

```
kicad : Depends: libgit2-1.8 (>= 1.8.0) but it is not installable
```

Cause:

- The KiCad 8 PPA package for Ubuntu 25.04 needs `libgit2-1.8`.
  Ubuntu 25.04 only has `libgit2-1.9`.
- The script avoided this by pinning `kicad=8.0.8+dfsg-1`, which is Ubuntu's
  own KiCad package. But the pin was only on `kicad`. The other four KiCad
  packages still came from the PPA as version 8.0.9, so the install had mixed
  versions.

Fix:

- If Ubuntu's own repository already has KiCad 8 (true for 25.04), the script
  uses it and does not add the PPA.
- If an older run added the PPA, the script removes it.
- All five KiCad packages now come from the same place.

#### Problem 6: Running the installer again skips NGHDL

Output of the second run:

```
Installing KiCad...........................
KiCad 8.0 is already installed.
```

The installer then ends with success, but NGHDL, the SKY130 PDK and the
desktop shortcut are never installed.

Cause: `exit 0` inside the KiCad function stops the whole installer.
Users often run the installer again after an error, so this is common.

Fix: changed `exit 0` to `return 0`.

#### Problem 7: Launchpad server error 503

Error:

```
E: Failed to fetch https://ppa.launchpadcontent.net/... 503 Service Unavailable
```

Cause: the Launchpad server often answers with error 503, and apt does not
try again by default.

Fix: apt now tries up to 5 times (`-o Acquire::Retries=5`). The PPA check
also tries again and only treats "404 Not Found" as "not available".

#### Problem 8: eSim symbols missing in KiCad 8

Cause: the symbol table was copied to `~/.config/kicad/6.0`. KiCad 8 reads
`~/.config/kicad/8.0`.

Fix: the script reads the installed KiCad version and copies the file to the
matching folder.

#### Problem 9: KiCad 8 PPA does not exist for 25.10 and 26.04

Error:

```
E: The repository 'https://ppa.launchpadcontent.net/kicad/kicad-8.0-releases/ubuntu questing Release' does not have a Release file.
```

Cause: the KiCad 8 PPA only has packages up to Ubuntu 25.04.

Fix:

- The script checks the PPA before adding it.
- If the PPA has no packages for this Ubuntu version, or `apt update` fails
  after adding it, the script removes it again.
- It then installs KiCad from Ubuntu's own repository (KiCad 9 on 25.10 and
  26.04) and prints a warning.

#### Problem 10: Desktop folder name differs by language

Cause: the script copies the shortcut to `$HOME/Desktop`. On a German or
Spanish desktop this folder has another name, so the copy fails at the very
last step.

Fix: the script asks the system for the real folder name with
`xdg-user-dir DESKTOP`, and creates the folder if it is missing.

#### Problem 11: `nghdl.zip` contains the old NGHDL installer

Cause: the official eSim-2.5.zip contains `nghdl.zip`, and the NGHDL
installer inside it has problems 12 to 16.

Fix: after unzipping `nghdl.zip`, the eSim script replaces its
`install-nghdl.sh` with the fixed copy in `install-eSim-scripts/nghdl/`.
So the official zip works without being rebuilt.

### NGHDL installer: `install-eSim-scripts/nghdl/install-nghdl.sh`

#### Problem 12: `libcanberra-gtk-module` removed

Error:

```
Error: Package 'libcanberra-gtk-module' has no installation candidate
```

Cause: Ubuntu 25.04 removed this GTK2 package.

Fix: install `libcanberra-gtk3-module`. Install the GTK2 package only if it
is still available.

#### Problem 13: GHDL 4.1.0 does not accept LLVM 20

Error:

```
Unhandled version llvm 20.1.2
```

Cause: GHDL 4.1.0 works with LLVM versions 3.5 to 18. The default LLVM is
version 20 on Ubuntu 25.04 and 25.10, and version 21 on 26.04. LLVM 18 is
still available on all three.

Fix: the script installs the newest LLVM that is 18 or lower
(`llvm-18`, `llvm-18-dev`, `clang-18`) and builds GHDL with
`--with-llvm-config=/usr/bin/llvm-config-18`. The old step that removed the
`llvm` package is no longer needed.

#### Problem 14: `clang++` not found

Error (seen after fixing problem 13):

```
/bin/sh: 1: clang++: not found
```

Cause: GHDL uses `clang++` by default, but the `clang-18` package only
installs `clang++-18`.

Fix: the script passes `CXX=clang++-18` to GHDL's `configure`.

#### Problem 15: ngspice does not compile with GCC 15

Error (Ubuntu 25.10 and 26.04):

```
src/include/ngspice/bool.h:6:13: error: 'bool' cannot be defined via 'typedef'
note: 'bool' is a keyword with '-std=c23' onwards
```

Cause: GCC 15 uses the C23 standard by default. In C23, `bool` is a keyword,
so the old ngspice code no longer compiles.

Fix: ngspice is built with `CC="gcc -std=gnu17"`. This is the default of
GCC 14, so nothing changes on Ubuntu 25.04.

#### Problem 16: Small bugs in the NGHDL script

- `libncurses5-dev` is now only an alias; the script uses `libncurses-dev`.
- `else [[ ... ]]` was written where `elif` was meant.
- `--uninstall` tried to remove `llvm-${llvm_version}`, but this variable was
  never set. The LLVM version is now saved in `~/.nghdl/config.ini` and read
  back during uninstall.

Note: problems 12 and 13 are also mentioned in the older `Ubuntu/REPORT.md`,
but that fix was never added to the NGHDL repository. It also used
`llvm-config-18` without the matching `clang++-18`, so problem 14 would still
appear.

## 5. Files changed

| File | What changed | Problems |
| --- | --- | --- |
| `Ubuntu/install-eSim.sh` | Rewritten | 1, 2 |
| `Ubuntu/install-eSim-scripts/install-eSim-25.04.sh` | KiCad, apt, desktop and NGHDL changes | 3, 5 to 11 |
| `Ubuntu/install-eSim-scripts/nghdl/install-nghdl.sh` | Fixed NGHDL installer | 12 to 16 |
| `Ubuntu/install-eSim-scripts/nghdl/install-nghdl-ubuntu-25.04.patch` | Same NGHDL fix as a patch for the FOSSEE/nghdl repository | 12 to 16 |
| `Ubuntu/testing/` | Scripts to repeat all tests | – |
| `Ubuntu/README.md` | How to use the fixed scripts | – |

### How to use the fix with the official eSim-2.5.zip

```bash
unzip eSim-2.5.zip
cd eSim-2.5
cp /path/to/this/repo/Ubuntu/install-eSim.sh .
cp -r /path/to/this/repo/Ubuntu/install-eSim-scripts .
./install-eSim.sh --install
```

## 6. Results after the fixes

Every test below was run on a fresh system.

| Test | Ubuntu 25.04 | Ubuntu 25.10 | Ubuntu 26.04 |
| --- | --- | --- | --- |
| Official zip, no changes | Fails (version not supported) | Fails | Fails |
| installers branch, no changes | Fails (syntax error) | Fails | Fails |
| With the fixed scripts | **Installs fully** | **Installs fully** | **Installs fully** |
| KiCad version installed | 8.0.8 | 9.0.3 (with warning) | 9.0.8 (with warning) |
| GHDL compiles and runs a VHDL file | Pass | Pass | Pass |
| Verilator builds | Pass | Pass | Pass |
| ngspice simulation (1 V across 1 kΩ gives 1 mA) | Pass | Pass | Pass |
| eSim window starts without errors | Pass | Pass | Pass |
| NGHDL window starts without errors | Pass | Pass | Pass |
| eSim symbols copied to KiCad's folder | Pass (8.0) | Pass (9.0) | Pass (9.0) |

I also ran the old 25.04 script a second time on an installed system. It
stopped after "KiCad 8.0 is already installed.", which confirms problem 6.

Short log extracts are in
[testing/logs/install-log-excerpts.md](testing/logs/install-log-excerpts.md).

## 7. Open points

- **KiCad 9 on 25.10 and 26.04.** KiCad 8 is not available for these
  versions. KiCad 9 opens KiCad 8 files, but eSim 2.5 was only tested by the
  eSim team with KiCad 8, so the full schematic-to-simulation flow should be
  checked on a real desktop.
- **KiCad 8 PPA package for 25.04 is broken** (it needs `libgit2-1.8`). This
  should be reported to the KiCad PPA team.
- **GHDL 4.1.0 needs LLVM 18 or lower.** This works up to Ubuntu 26.04. When
  LLVM 18 is removed from Ubuntu, NGHDL should move to GHDL 5.
- **NGHDL repository.** The fixed NGHDL installer should also be added to the
  FOSSEE/nghdl repository. The patch file in this branch applies cleanly.
- **Not tested:** a real desktop session (the windows were tested without a
  screen), other Ubuntu flavours, and ARM64 computers.
- **Test environment note:** my test machine could not download GitHub
  tarballs, so the `hdlparse` install was run with the `git+https://` form of
  the same address. The scripts keep the original address.

## 8. How to repeat the tests

```bash
git clone -b installers https://github.com/Mahim56207/eSim.git
cd eSim/Ubuntu/testing

# 1. Make a clean Ubuntu 25.04 image
sudo ./build-image.sh plucky 25.04

# 2. Build the eSim-2.5 package from the eSim and NGHDL repositories
./make-package.sh /tmp/pkg /path/to/FOSSEE-eSim /path/to/FOSSEE-nghdl

# 3. Install it and run the checks
./run-install.sh esim-base:25.04 /tmp/pkg/eSim-2.5.zip install-25.04.log
```

Use `questing 25.10` or `resolute 26.04` in step 1 for the other versions.

## 9. References

- eSim downloads: https://esim.fossee.in/downloads
- eSim installers branch: https://github.com/FOSSEE/eSim/tree/installers
- NGHDL installers branch: https://github.com/FOSSEE/nghdl/tree/installers
- KiCad 8 PPA: https://launchpad.net/~kicad/+archive/ubuntu/kicad-8.0-releases
- GHDL: https://github.com/ghdl/ghdl
- GCC 15 changes (C23 default): https://gcc.gnu.org/gcc-15/porting_to.html

# eSim 2.5 on Ubuntu 25.04 and above: installation problems and fixes

Screening Task 4 (eSim Semester Long Internship, Autumn 2026) – report date 23 November 2026.

**Result:** eSim-2.5 did not install on Ubuntu 25.04 at all: the downloadable
zip rejects the release, and the `installers` branch script has a syntax error.
After the 16 fixes below, the official eSim-2.5 package installs completely on
Ubuntu 25.04, and installs on 25.10 and 26.04 LTS (with KiCad 9, see
"Remaining issues"). eSim and NGHDL start, GHDL compiles and runs VHDL,
ngspice simulates.

## 1. Test environment

| Item | Value |
| --- | --- |
| Ubuntu 25.04 (plucky) | clean root filesystem from `debootstrap` (archive.ubuntu.com), run as a Docker container: Python 3.13.3, GCC 14.2, default LLVM 20.1.2, KiCad 8.0.8 in universe |
| Ubuntu 25.10 (questing) | same method: GCC 15.2, default LLVM 20.1.8, KiCad 9.0.3 in universe |
| Ubuntu 26.04 LTS (resolute) | same method: GCC 15, default LLVM 21.1, KiCad 9.0.8 in universe |
| User | normal user `esim` with sudo, `~/Desktop`, `lsb-release`, `unzip`, `wget`, `software-properties-common`, `gio` (as on Ubuntu Desktop) |
| eSim package | eSim-2.5.zip (96.2 MB, released 03/07/2025, listed for Ubuntu 22.04/23.04/24.04) and the same package rebuilt from Git with `testing/make-package.sh` (eSim tag `v2.5`, NGHDL `master` + NGHDL `installers/Ubuntu`) |
| Run | `unzip eSim-2.5.zip; cd eSim-2.5; ./install-eSim.sh --install`, answer `n` to the proxy question, keep the full log, repeat in a fresh container after every fix |

`testing/build-image.sh` builds the images with `debootstrap` from the Ubuntu
archive instead of Docker Hub, so the same method works for any release. A
container is not a full desktop, but the installer only uses apt, pip, sudo and
the user's home folder, which behave the same. See [testing/](testing/) to
reproduce every run.

## 2. Problems found

In the order the installer reaches them.

### Main installer (`install-eSim.sh`)

**1. Released zip: "Unsupported Ubuntu version: 25.04 ()"**

```
$ ./install-eSim.sh --install
Detected Ubuntu Version:
Unsupported Ubuntu version: 25.04 ()
```

* Cause: the dispatcher in eSim-2.5 only knows 22.04, 23.04 and 24.04. The
  version regex `\d+\.\d+\.\d+` needs three numbers; `lsb_release -d` on 25.04
  prints "Ubuntu 25.04", so the detected version is empty.
* Fix: new dispatcher. 25.04, 25.10 and 26.04 (and, with a warning, any newer
  release) run `install-eSim-25.04.sh`. Regex accepts 2 or 3 numbers. The
  dispatcher `cd`s to its own folder (the version scripts use `pwd` as eSim
  home) and returns the script's exit code.

**2. `installers` branch: syntax error, nothing runs**

```
./install-eSim.sh: line 70: syntax error near unexpected token `}'
```

* Cause: merge commit `52d77f6` (29 May 2026) mixed the short dispatcher with
  the old monolithic installer. Its parent `5224460` was already broken:
  `run_version_script` had no `case` and wrote to an undefined `$config_dir`.
  Found with `bash -n` on each revision of the file.
* Fix: the clean dispatcher from fix 1 replaces the file.

### `install-eSim-scripts/install-eSim-25.04.sh`

**3. `Continue? [Y/n] Abort.`** – `sudo apt install python3-virtualenv` has no
`-y`; with input not from a terminal (pipes, CI, the proxy answer piped in) apt
aborts and the installer stops. Fix: `-y`.

**4. hdlparse on Python 3.13** – `pip install hdlparse` (PyPI 1.0.4) fails:

```
error in hdlparse setup command: use_2to3 is invalid.
```

Only the GitHub fork (`hdl/pyhdlparser`, 1.0.7) installs, so the GitHub line
must keep running before the PyPI line. No code change; documented.

**5. KiCad from the PPA cannot be installed on 25.04**

```
The following packages have unmet dependencies:
 kicad : Depends: libgit2-1.8 (>= 1.8.0) but it is not installable
```

* Cause: the `kicad-8.0-releases` PPA build for plucky (`8.0.9-0~ubuntu25.04.1`)
  was linked against `libgit2-1.8`; Ubuntu 25.04 only has `libgit2-1.9`. The
  script works around it with `kicad=8.0.8+dfsg-1` (the Ubuntu-archive build),
  but the pin only covers `kicad`: footprints, symbols and templates still come
  from the PPA as 8.0.9, giving a mixed installation.
* Fix: if the Ubuntu archive already provides KiCad 8 (25.04: 8.0.8), do not add
  the PPA (and remove one left by an earlier run); install all five KiCad
  packages from one source, no pin.

**6. Re-running the installer silently skips everything after KiCad**

```
Installing KiCad...........................
KiCad 8.0 is already installed.
INSTALLER_EXIT=0            <- NGHDL, SKY130 and desktop icon never installed
```

* Cause: `exit 0` inside `installKicad` ends the whole script. Any second run
  (normal after a failure) stops here and reports success.
* Fix: `return 0`.

**7. Launchpad "503 Service Unavailable" aborts the install**

```
E: Failed to fetch https://ppa.launchpadcontent.net/.../kicad-symbols_8.0.9~ubuntu25.04.1_all.deb  503  Service Unavailable
```

Fix: `-o Acquire::Retries=5` on apt update/install; the PPA check retries and
only treats a definite 404 as "not published".

**8. eSim symbols not visible in KiCad 8** – `sym-lib-table` was copied to
`~/.config/kicad/6.0`; KiCad 8 reads `~/.config/kicad/8.0`. Fix: use the
installed KiCad major version (`dpkg-query`).

**9. 25.10 / 26.04: "does not have a Release file"**

```
E: The repository 'https://ppa.launchpadcontent.net/kicad/kicad-8.0-releases/ubuntu questing Release' does not have a Release file.
```

* Cause: the KiCad 8 PPA publishes builds up to plucky (25.04) only.
* Fix: check the PPA first; if it has no build (or Launchpad cannot be reached,
  or `apt-get update` fails after adding it) remove it and install KiCad from
  the Ubuntu archive with a warning (KiCad 9 on 25.10/26.04).

**10. Desktop shortcut on non-English desktops** – `cp esim.desktop
$HOME/Desktop/` fails at the last step when the folder is localised
("Escritorio", "Schreibtisch"). Fix: `xdg-user-dir DESKTOP`, create if missing.

**11. Old NGHDL installer inside `nghdl.zip`** – the official eSim-2.5 zip
carries the NGHDL installer that fails with problems 12–15. Fix:
`installNghdl` copies `install-eSim-scripts/nghdl/install-nghdl.sh` over the
unzipped one, so the official zip works without being rebuilt.

### NGHDL installer (`install-eSim-scripts/nghdl/install-nghdl.sh`)

**12. `libcanberra-gtk-module` removed**

```
Error: Package 'libcanberra-gtk-module' has no installation candidate
```

Fix: install `libcanberra-gtk3-module`; the GTK2 module only if apt still has it.

**13. GHDL 4.1.0 refuses LLVM 20**

```
Unhandled version llvm 20.1.2
```

* Cause: GHDL 4.1.0 `configure` accepts LLVM 3.5–18.1. The default `llvm` is
  20 on 25.04/25.10 and 21 on 26.04. `llvm-18` is still in universe on all three.
* Fix: install the newest `llvm-N`, `llvm-N-dev`, `clang-N` with N ≤ 18 and run
  `./configure --with-llvm-config=/usr/bin/llvm-config-18`. The old step that
  removed the `llvm` meta package is dropped.

**14. `clang++: not found`** (appears after fix 13)

```
clang++ -c `/usr/bin/llvm-config-18 --cxxflags` ... llvm-cbindings.cpp
/bin/sh: 1: clang++: not found
```

GHDL's `configure` defaults to `CXX=clang++`, but `clang-18` installs
`clang++-18`. Fix: `./configure ... CXX=clang++-18`.

**15. ngspice does not compile with GCC 15 (25.10, 26.04)**

```
src/include/ngspice/bool.h:6:13: error: 'bool' cannot be defined via 'typedef'
note: 'bool' is a keyword with '-std=c23' onwards
```

GCC 15 defaults to C23. Fix: configure ngspice with `CC="gcc -std=gnu17"`
(the GCC 14 default, so 25.04 builds are unchanged).

**16. Smaller NGHDL script bugs** – `libncurses5-dev` is only a virtual package
now (use `libncurses-dev`); `else [[ ... ]]` should be `elif`; `--uninstall`
purged `llvm-${llvm_version}` without ever setting it (now saved in
`~/.nghdl/config.ini`).

Problems 12 and 13 are also described in the existing `Ubuntu/REPORT.md`, but
the matching NGHDL change was never committed to `FOSSEE/nghdl`; the fix there
also hard-coded `llvm-config-18`, which would miss problem 14.

## 3. Files changed

| File | Change |
| --- | --- |
| `Ubuntu/install-eSim.sh` | rewritten dispatcher (problems 1, 2) |
| `Ubuntu/install-eSim-scripts/install-eSim-25.04.sh` | problems 3, 5–11 |
| `Ubuntu/install-eSim-scripts/nghdl/install-nghdl.sh` | fixed NGHDL installer (problems 12–16) |
| `Ubuntu/install-eSim-scripts/nghdl/install-nghdl-ubuntu-25.04.patch` | same change as a patch for `FOSSEE/nghdl` `installers` |
| `Ubuntu/testing/` | debootstrap image builder, package builder, install runner, smoke test |
| `Ubuntu/README.md` | how to use the fixed scripts with the official zip |

## 4. Verification

Every row is a fresh container. "Fork scripts" = the official package layout
with this branch's `install-eSim.sh` and `install-eSim-scripts/` copied in,
installer answered only with `n` (no proxy).

| Check | Ubuntu 25.04 | Ubuntu 25.10 | Ubuntu 26.04 LTS |
| --- | --- | --- | --- |
| Released zip, unchanged | fails: unsupported version | fails: unsupported version | fails: unsupported version |
| `installers` branch, unchanged | fails: syntax error | fails: syntax error | fails: syntax error |
| Fork scripts | `eSim Installed Successfully`, exit 0 | `eSim Installed Successfully`, exit 0 | `eSim Installed Successfully`, exit 0 |
| KiCad | 8.0.8 (archive) | 9.0.3 (archive, warning) | 9.0.8 (archive, warning) |
| GHDL 4.1.0 + LLVM 18: compile and run a VHDL test | pass | pass | pass |
| Verilator 4.210 | builds | builds | builds |
| ngspice batch run (1 V over 1 kΩ → 1 mA) | pass | pass | pass |
| eSim GUI starts (Qt offscreen, 25 s, no traceback) | pass | pass | pass |
| NGHDL GUI starts | pass | pass | pass |
| eSim symbol libraries / `sym-lib-table` location | 15 / `~/.config/kicad/8.0` | 15 / `~/.config/kicad/9.0` | 15 / `~/.config/kicad/9.0` |

Re-running the old 25.04 script on an installed system reproduced problem 6
(stopped at "KiCad 8.0 is already installed.", exit 0). The official package's
NGHDL builds ngspice 35; NGHDL `master` (ngspice 45.2) was also built on 25.04
with the same fixes.

Test-sandbox note: GitHub tarball downloads were blocked in the test sandbox,
so `pip3 install https://github.com/hdl/pyhdlparser/tarball/master` was run as
the equivalent `git+https://github.com/hdl/pyhdlparser`. The scripts keep the
original URL.

## 5. Remaining issues

* **KiCad 9 on 25.10/26.04.** No KiCad 8 build exists for these releases, so
  the installer uses the archive's KiCad 9 and warns. KiCad 9 reads eSim's
  KiCad-8 symbol libraries and projects, but eSim 2.5 is only validated with
  KiCad 8; eSim's schematic-to-netlist flow should be checked by hand.
* **PPA build for 25.04 is broken upstream** (libgit2-1.8). Worth reporting to
  the KiCad PPA maintainers; the installer no longer depends on it.
* **GHDL 4.1.0 needs LLVM ≤ 18.** Fine through 26.04. When `llvm-18` leaves the
  archive, move NGHDL to GHDL 5.x (Ubuntu ships `ghdl-llvm` 5.0.1).
* **Upstream NGHDL.** The fixed NGHDL installer should also go to
  `FOSSEE/nghdl` (`installers` branch) and into the next `nghdl.zip`.
* **Not covered:** a graphical desktop session (tested with Qt's offscreen
  platform), Ubuntu flavours, ARM64.

## 6. How to reproduce

```bash
cd Ubuntu/testing
sudo ./build-image.sh plucky 25.04                 # clean Ubuntu 25.04 image
./make-package.sh /tmp/pkg <eSim clone> <nghdl clone>
./run-install.sh esim-base:25.04 /tmp/pkg/eSim-2.5.zip install-25.04.log
```

## References

* eSim downloads: https://esim.fossee.in/downloads
* eSim installers branch: https://github.com/FOSSEE/eSim/tree/installers
* NGHDL installers branch: https://github.com/FOSSEE/nghdl/tree/installers
* KiCad 8 PPA: https://launchpad.net/~kicad/+archive/ubuntu/kicad-8.0-releases
* GHDL: https://github.com/ghdl/ghdl
* GCC 15 C23 default: https://gcc.gnu.org/gcc-15/porting_to.html

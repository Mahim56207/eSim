# Fixed NGHDL installer for Ubuntu 25.04 and newer

`install-nghdl.sh` in this folder is a fixed copy of
[`install-nghdl.sh` from the FOSSEE/nghdl installers branch](https://github.com/FOSSEE/nghdl/blob/installers/Ubuntu/install-nghdl.sh).

## Why it is needed

The `nghdl.zip` inside `eSim-2.5.zip` has the old installer. On Ubuntu 25.04
and newer it stops with:

```
Error: Package 'libcanberra-gtk-module' has no installation candidate
Unhandled version llvm 20.1.2
```

`install-eSim-25.04.sh` copies this fixed file over the old one right after
it unzips `nghdl.zip`. So the official eSim-2.5.zip works without changes.

## What was changed

| Problem | Change |
| --- | --- |
| `libcanberra-gtk-module` removed from Ubuntu 25.04 | Install `libcanberra-gtk3-module`; install the GTK2 module only if it exists |
| GHDL 4.1.0 accepts LLVM up to 18; Ubuntu 25.04+ has LLVM 20 or 21 by default | Install the newest LLVM that is 18 or lower and build GHDL with `llvm-config-18` |
| `clang++: not found` after the LLVM change | Pass `CXX=clang++-18` to GHDL |
| ngspice does not compile with GCC 15 (25.10, 26.04) | Build ngspice with `gcc -std=gnu17` |
| `libncurses5-dev` is only an alias now | Use `libncurses-dev` |
| `else [[ ... ]]` instead of `elif` | Fixed |
| Uninstall used an LLVM version that was never set | Save the version in `~/.nghdl/config.ini` and read it back |

## Patch for the NGHDL repository

`install-nghdl-ubuntu-25.04.patch` has the same changes as a patch for the
FOSSEE/nghdl `installers` branch:

```bash
git clone -b installers https://github.com/FOSSEE/nghdl.git
cd nghdl
git apply /path/to/install-nghdl-ubuntu-25.04.patch
```

# Updated NGHDL installer for Ubuntu 25.04 and newer

`install-nghdl.sh` in this folder is a fixed copy of
[`FOSSEE/nghdl` → `installers/Ubuntu/install-nghdl.sh`](https://github.com/FOSSEE/nghdl/blob/installers/Ubuntu/install-nghdl.sh)
(revision `9869c52`).

The `nghdl.zip` shipped inside `eSim-2.5.zip` still contains the old script,
which stops on Ubuntu 25.04+ with:

```
Error: Package 'libcanberra-gtk-module' has no installation candidate
Unhandled version llvm 20.1.2
```

`install-eSim-25.04.sh` (function `installNghdl`) copies this file over
`nghdl/install-nghdl.sh` right after unzipping `nghdl.zip`, so the official
eSim-2.5 package installs without rebuilding `nghdl.zip`.

## What changed

| Problem on Ubuntu 25.04+ | Change |
| --- | --- |
| `libcanberra-gtk-module` (GTK2) removed from the archive | install `libcanberra-gtk3-module`; GTK2 module only when apt still has it |
| default LLVM is 20 (25.04, 25.10) / 21 (26.04); GHDL 4.1.0 accepts LLVM ≤ 18.1 | install the newest `llvm-N`/`llvm-N-dev`/`clang-N` with N ≤ 18 (LLVM 18 on 25.04, 25.10, 26.04) and build GHDL with `--with-llvm-config=/usr/bin/llvm-config-N` |
| `clang++: not found` once only `clang-18` is installed | pass `CXX=clang++-N` to GHDL `configure` |
| `libncurses5-dev` is only a virtual package now | use `libncurses-dev` |
| `else [[ ... ]]` instead of `elif` in the Verilator dependency check | fixed |
| `--uninstall` used `${llvm_version}` that was never set | LLVM version is saved in `~/.nghdl/config.ini` and read back |

`install-nghdl-ubuntu-25.04.patch` is the same change as a patch that applies
cleanly to `FOSSEE/nghdl` branch `installers`:

```bash
git clone -b installers https://github.com/FOSSEE/nghdl.git
cd nghdl
git apply /path/to/install-nghdl-ubuntu-25.04.patch
```

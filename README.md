eSim Packaging
====

It contains all the documentation for packaging eSim for distribution.


## Ubuntu 25.04 and newer (Screening Task 4)

This fork fixes the installation of eSim 2.5 on Ubuntu 25.04, 25.10 and 26.04.

- **Full report:** [Ubuntu/REPORT-Ubuntu-25.04-and-above.md](Ubuntu/REPORT-Ubuntu-25.04-and-above.md)
- **Problems found:** 16
- **Problems fixed:** 15 (the last one needs no code change)
- **Result:** eSim 2.5 installs fully on Ubuntu 25.04, 25.10 and 26.04

Main problems fixed:

| Problem | Where |
| --- | --- |
| Installer says "Unsupported Ubuntu version: 25.04" | `Ubuntu/install-eSim.sh` |
| Syntax error at line 70 of `install-eSim.sh` | `Ubuntu/install-eSim.sh` |
| KiCad 8 from the PPA cannot be installed on 25.04 | `Ubuntu/install-eSim-scripts/install-eSim-25.04.sh` |
| A second run of the installer skips NGHDL | `Ubuntu/install-eSim-scripts/install-eSim-25.04.sh` |
| `libcanberra-gtk-module` no longer exists | `Ubuntu/install-eSim-scripts/nghdl/install-nghdl.sh` |
| GHDL 4.1.0 does not accept LLVM 20 | `Ubuntu/install-eSim-scripts/nghdl/install-nghdl.sh` |
| ngspice does not compile with GCC 15 (25.10, 26.04) | `Ubuntu/install-eSim-scripts/nghdl/install-nghdl.sh` |

How to install eSim 2.5 on Ubuntu 25.04 or newer with these fixes:

```bash
unzip eSim-2.5.zip
cd eSim-2.5
cp /path/to/this/repo/Ubuntu/install-eSim.sh .
cp -r /path/to/this/repo/Ubuntu/install-eSim-scripts .
./install-eSim.sh --install
```

Scripts to repeat all tests are in [Ubuntu/testing/](Ubuntu/testing/).


# Packaging eSim for Distribution:

1. eSim is currently packaged and distributed for Ubuntu OS (Linux) and MS Windows OS.

2. Refer the [documentation](Version_Change.md) for the changes to be done when a new release is to be made.

> Note: These changes have to be made `first` before proceeding with the packaging on either platform.

3. Refer the [documentation](Ubuntu/README.md) to package eSim for Ubuntu OS.

4. Refer the [documentation](Windows/README.md) to package eSim for Windows OS.

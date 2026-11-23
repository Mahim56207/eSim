# Installer tests for Ubuntu 25.04 and newer

These scripts install eSim 2.5 on a fresh Ubuntu system inside Docker and
check that it works. They were used for the results in
[../REPORT-Ubuntu-25.04-and-above.md](../REPORT-Ubuntu-25.04-and-above.md).

## Files

| File | What it does |
| --- | --- |
| `build-image.sh` | Makes a clean Ubuntu image with `debootstrap` (for example 25.04, 25.10 or 26.04) |
| `Dockerfile.base` | Adds a normal user with `sudo` and the tools a desktop install has |
| `make-package.sh` | Builds `eSim-2.5.zip` from the eSim and NGHDL GitHub repositories, as described in `Ubuntu/README.md` |
| `run-install.sh` | Installs the package in a fresh container, saves the log and runs `smoke.sh` |
| `smoke.sh` | Checks versions, compiles a VHDL file with GHDL, runs an ngspice simulation and starts eSim and NGHDL |
| `logs/` | Check results and short log extracts from the test runs |

## Steps

```bash
# 1. Make a clean Ubuntu image (needs root and debootstrap)
sudo ./build-image.sh plucky 25.04      # or: questing 25.10, resolute 26.04

# 2. Build the eSim-2.5 package
git clone https://github.com/FOSSEE/eSim.git /tmp/FOSSEE-eSim
git clone https://github.com/FOSSEE/nghdl.git /tmp/FOSSEE-nghdl
./make-package.sh /tmp/pkg /tmp/FOSSEE-eSim /tmp/FOSSEE-nghdl

# 3. Install and check
./run-install.sh esim-base:25.04 /tmp/pkg/eSim-2.5.zip install-25.04.log
```

One full install takes about 35 minutes on 2 CPU cores, because GHDL,
Verilator and ngspice are built from source.

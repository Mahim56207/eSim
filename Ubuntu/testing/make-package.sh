#!/bin/bash
#=============================================================================
#  make-package.sh - rebuild an eSim-2.5 Ubuntu package from Git, following
#  Ubuntu/README.md (eSim) and Ubuntu/README.md (nghdl, installers branch).
#
#  usage: ./make-package.sh <out_dir> <esim_clone> <nghdl_clone> [eSim_tag]
#     esim_clone : clone of FOSSEE/eSim (needs tag v2.5 and this installers tree)
#     nghdl_clone: clone of FOSSEE/nghdl (branches master and installers)
#  env: NGHDL_MASTER (default master), NGHDL_INSTALLERS (default installers),
#       INSTALLERS_DIR (default: the Ubuntu/ folder this script lives in)
#=============================================================================
set -euo pipefail
OUT=$1; ESIM=$2; NGHDL=$3; TAG=${4:-v2.5}
HERE="$(cd "$(dirname "$0")/.." && pwd)"
INST=${INSTALLERS_DIR:-$HERE}
NM=${NGHDL_MASTER:-origin/master}; NI=${NGHDL_INSTALLERS:-origin/installers}
VER=${TAG#v}; P="$OUT/eSim-$VER"
rm -rf "$OUT"; mkdir -p "$OUT"
# 1. eSim source
git -C "$ESIM" archive --format=tar --prefix="eSim-$VER/" "$TAG" | tar -x -C "$OUT"
rm -rf "$P/.github" "$P/code" "$P/conf.py" "$P/setup.py" "$P/index.rst" "$P/.gitignore" "$P/.travis.yml"
# 2. installer scripts (this branch)
cp -r "$INST/install-eSim.sh" "$INST/install-eSim-scripts" "$P/"; chmod +x "$P/install-eSim.sh"
# 5. nghdl.zip = nghdl master + installers/Ubuntu files
N="$OUT/nghdl"; mkdir -p "$N"
git -C "$NGHDL" archive "$NM" | tar -x -C "$N"
rm -f "$N/GHDLside.md" "$N/Workflow.md" "$N/.gitignore"
for f in install-nghdl.sh ghdl-4.1.0.tar.gz verilator-4.210.tar.xz; do
  git -C "$NGHDL" show "$NI:Ubuntu/$f" > "$N/$f"; done
chmod +x "$N/install-nghdl.sh"
(cd "$OUT" && zip -qr "$P/nghdl.zip" nghdl) && rm -rf "$N"
# 6. kicadLibrary -> tar.xz
(cd "$P/library" && tar -cJf kicadLibrary.tar.xz kicadLibrary && rm -rf kicadLibrary)
(cd "$OUT" && zip -qr "eSim-$VER.zip" "eSim-$VER") && rm -rf "$P"
ls -la "$OUT"

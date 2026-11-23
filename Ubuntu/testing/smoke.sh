#!/bin/bash
# Post-install checks for eSim on Ubuntu
echo "== versions"; lsb_release -ds
ngspice -v 2>&1 | grep -m1 -i "ngspice-"; ghdl --version | head -1; verilator --version; kicad-cli version 2>/dev/null || dpkg-query -W -f='kicad ${Version}\n' kicad
echo "== files"; ls ~/.esim/config.ini ~/.nghdl/config.ini /usr/bin/esim /usr/local/bin/nghdl /usr/share/local/sky130_fd_pr -d; ls ~/.config/kicad/; ls /usr/share/kicad/symbols | grep -c eSim_
echo "== GHDL+LLVM compile test"; cd /tmp && printf 'entity t is end;\narchitecture a of t is begin process begin report "ghdl-ok"; wait; end process; end;\n' > t.vhd && ghdl -a t.vhd && ghdl -e t && ./t 2>&1 | tail -1
echo "== ngspice batch test"; printf 'test\nV1 1 0 1\nR1 1 0 1k\n.op\n.control\nrun\nprint i(V1)\n.endc\n.end\n' > r.cir && ngspice -b r.cir 2>&1 | grep -i "i(v1)"
echo "== eSim GUI start (offscreen, 25 s)"; cd ~ && QT_QPA_PLATFORM=offscreen timeout 25 esim > /tmp/esim.out 2>&1; echo "rc=$? (124 = still running after 25 s = OK)"; grep -i -E "traceback|error" /tmp/esim.out | head -5; tail -3 /tmp/esim.out
echo "== NGHDL GUI start (offscreen, 10 s)"; QT_QPA_PLATFORM=offscreen timeout 10 bash -c 'source ~/.esim/env/bin/activate; nghdl' > /tmp/nghdl.out 2>&1; echo "rc=$?"; grep -i traceback -A5 /tmp/nghdl.out | head -8

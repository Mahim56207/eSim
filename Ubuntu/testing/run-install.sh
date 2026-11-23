#!/bin/bash
#=============================================================================
#  run-install.sh - install a package zip in a fresh container and log it
#  usage: ./run-install.sh <image> <eSim-2.5.zip> <logfile>
#=============================================================================
img=$1; pkg=$2; log=$3; name=esim-run-$$
docker create --name $name --network host -e USER=esim "$img" bash -lc '
  cd ~ && unzip -q eSim-2.5.zip && cd eSim-2.5 &&
  echo n | ./install-eSim.sh --install; echo "INSTALLER_EXIT=$?"' >/dev/null
docker cp "$pkg" $name:/home/esim/eSim-2.5.zip
docker start -a $name 2>&1 | tee "$log"
docker cp "$(dirname "$0")/smoke.sh" $name:/tmp/smoke.sh
docker commit $name esim-installed:latest >/dev/null && docker rm $name >/dev/null
docker run --rm -e USER=esim esim-installed:latest bash /tmp/smoke.sh | tee -a "$log"

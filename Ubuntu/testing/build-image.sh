#!/bin/bash
#=============================================================================
#  build-image.sh - make a clean Ubuntu Docker image with debootstrap
#  (works even after a release has left Docker Hub).
#  usage: sudo ./build-image.sh <codename> <version>   e.g. plucky 25.04
#=============================================================================
set -euo pipefail
C=$1; V=$2; R=/srv/$C; M=${MIRROR:-http://archive.ubuntu.com/ubuntu}
[ -e /usr/share/debootstrap/scripts/$C ] || ln -s gutsy /usr/share/debootstrap/scripts/$C
debootstrap --variant=minbase --components=main,universe "$C" "$R" "$M"
cat > "$R/etc/apt/sources.list" <<SRC
deb $M $C main restricted universe multiverse
deb $M $C-updates main restricted universe multiverse
deb http://security.ubuntu.com/ubuntu $C-security main restricted universe multiverse
SRC
tar -C "$R" -c . | docker import - esim-test/ubuntu:$V
docker build --build-arg BASE=esim-test/ubuntu:$V -t esim-base:$V -f "$(dirname "$0")/Dockerfile.base" "$(dirname "$0")"
rm -rf "$R"

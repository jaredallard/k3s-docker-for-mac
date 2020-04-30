#!/usr/bin/env sh
#
# Fetches and starts k3s in Docker for Mac.

set -x
set -e

base_dir="/var/lib/k3s-dfm"
bin_dir="$base_dir/bin"
mkdir -p "$bin_dir"

k3s="$bin_dir/k3s"

if [ ! -e "$k3s" ]; then
  echo "downloading k3s ..."

  # TODO(jaredallard): allow this version to be customized
  curl -Lo "$k3s" https://github.com/rancher/k3s/releases/download/v1.17.4%2Bk3s1/k3s
  chmod +x "$k3s"
fi

# only mount this here if we're in Docker for Mac
if mountpoint -q -- "/var/lib"; then
  # /dev/sda1 on pre-edge versions, edge is vda1
  persistent_mountpoint=$(df -h | grep -E /var/lib$ | awk '{ print $1 }')

  umount /etc/rancher || echo "no /etc/rancher mountpoint to unmount. Continuing"

  echo "mounting '$persistent_mountpoint' on '/etc/rancher'"
  mkdir -p /etc/rancher
  mount "$persistent_mountpoint" /etc/rancher
fi

echo "starting k3s"
exec "$k3s" server --docker
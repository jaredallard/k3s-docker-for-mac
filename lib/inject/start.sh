#!/usr/bin/env sh
#
# Fetches and starts k3s in Docker for Mac.

set -x
set -e

k3s_version="v1.19.1+k3s1"

base_dir="/var/lib/k3s-dfm"
bin_dir="$base_dir/bin"
k3s="$bin_dir/k3s"

# Rancher
rancher_dir="$base_dir/rancher"
rancher_config_dir="/etc/rancher"
rancher_state_dir="/var/lib/rancher"

# Create our state directories
mkdir -p "$bin_dir" "$rancher_dir" /root/.docker

# Create the target bindmount directories
mkdir -p "$rancher_config_dir" "$rancher_state_dir/k3s"

# Check if k3s exists, and matches the version we expect.
current_k3s_version="$($k3s --version 2>&1 | awk '{ print $3 }')"
if [ ! -e "$k3s" ] || [ "$current_k3s_version" != "$k3s_version" ]; then
  if [ -e "$k3s" ]; then
    echo "updating k3s ($current_k3s_version -> $k3s_version)"
  else
    echo "downloading k3s"
  fi

  wget -O "$k3s" "https://github.com/rancher/k3s/releases/download/$(echo "$k3s_version" | sed 's/+/%2B/')/k3s"
  chmod +x "$k3s"
fi

# We bind mount the /etc/rancher directory if it's not already mounted
if ! mountpoint -q -- "$rancher_config_dir"; then
  mount -v --rbind "$rancher_dir" "$rancher_config_dir"
  mount --make-rshared "$rancher_config_dir"
fi

# We bind mount the /var/lib/rancher directory if it's not already mounted
if ! mountpoint -q -- "$rancher_state_dir"; then
  mount -v --rbind "$rancher_dir" "$rancher_state_dir"
  mount --make-rshared "$rancher_state_dir"
fi

echo "setting up docker authentication"
cp -v "$base_dir/config.json" /root/.docker/config.json || true

echo "starting k3s"
exec "$k3s" server --docker --kubelet-arg=image-gc-high-threshold=98 \
  --kubelet-arg=image-gc-low-threshold=95

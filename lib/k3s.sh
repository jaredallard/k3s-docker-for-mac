#!/usr/bin/env bash
#
# k3s lib

# ports we proxy by default
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
proxies=(443 80 6443)

reset_k3s() {
  copy_files

  # Run reset-k3s.sh in the specified namespaces of the dockerd process
  docker run --privileged --pid=host --rm alpine \
    sh -c 'nsenter -t $(pgrep dockerd) --mount --uts --ipc --pid sh /var/lib/k3s-dfm/reset.sh'

  remove_proxies
}

copy_files() {
  pushd "$DIR/inject" >/dev/null || exit 1
  # Copy files from 'inject' into the mount namespace of the dockerd process.
  tar cf - . | docker run --privileged --pid=host --rm -i alpine sh -c 'cd /proc/$(pgrep dockerd)/root && mkdir -p var/lib/k3s-dfm && cd var/lib/k3s-dfm && tar xf - '
  popd >/dev/null || exit 1
}

remove_proxies() {
  # Keep this for now, since there may be older proxies that still exist
  docker stop proxy proxy-http proxy-https >/dev/null 2>&1 || true
  docker rm proxy proxy-http proxy-https >/dev/null 2>&1 || true

  for proxy in "${proxies[@]}"; do
    docker stop "proxy-$proxy" >/dev/null 2>&1 || true
    docker rm "proxy-$proxy" >/dev/null 2>&1 || true
  done

  return 0
}

create_proxies() {
  IP_ADDRESS="$(docker inspect k3s | jq '.[0].NetworkSettings.IPAddress' -r)"
  if [[ -z $IP_ADDRESS ]]; then
    warn "failed to get ip address of k3s container, will fail to talk to kubernetes"
  fi

  # Ensure that we always have no proxies running
  remove_proxies

  ## Loadbalancers
  for proxy in "${proxies[@]}"; do
    docker run -d --restart=unless-stopped \
      -v /var/run/docker.sock:/var/run/docker.sock --name "proxy-$proxy" \
      -p "$proxy:$proxy" hpello/tcp-proxy "$IP_ADDRESS" "$proxy" >/dev/null
  done
}

start_k3s() {
  copy_files

  # we have to start k3s first so we can get the potential new ip address for the container
  docker start k3s

  create_proxies
}

init_k3s() {
  copy_files

  info "creating k3s cluster"

  # Create the container to run k3s in.
  docker run --privileged --pid=host --restart=unless-stopped \
    --name k3s --detach alpine \
    sh -c 'nsenter --target $(pgrep dockerd) --mount --uts --ipc --pid sh /var/lib/k3s-dfm/start.sh' >/dev/null

  create_proxies
}

get_kubeconfig() {
  # Access the mount namespace of the dockerd process.
  docker run --privileged --pid=host --rm alpine sh -c 'cat /proc/$(pgrep dockerd)/root/etc/rancher/k3s/k3s.yaml' 2>&1
  return $?
}

#!/usr/bin/env bash
#
# k3s lib
reset_k3s() {
  copy_files

  docker run --privileged --pid=host --rm alpine \
    sh -c 'nsenter -t $(pgrep dockerd) --mount --uts --ipc --pid sh /var/lib/dev-env/reset-k3s.sh'

  ## Loadbalancer cleanup
  docker stop proxy proxy-http proxy-https >/dev/null
  docker rm proxy proxy-http proxy-https >/dev/null
}

copy_files() {
  info "copying files to vm host"

  # DIR comes in from parent script.
  pushd "$DIR/lib/inject" >/dev/null || exit 1
  tar cvf - . | docker run --privileged --pid=host --rm -i alpine sh -c 'cd /proc/$(pgrep dockerd)/root && mkdir -p var/lib/dev-env && cd var/lib/dev-env && tar xf -' >/dev/null
  popd >/dev/null || exit 1
}

start_k3s() {
  copy_files

  # Cleanup the host, this runs if we detect an original cluster.
  if docker inspect k3s >/dev/null 2>&1 || docker inspect proxy >/dev/null 2>&1; then
    info "removing old cluster"

    # We only show errors here, since we didn't explicitly ask for a removal
    reset_k3s >/dev/null
  fi

  info "creating k3s cluster"

  docker_k3s_flags="--privileged --pid=host --restart=always --name k3s --detach"

  docker run $docker_k3s_flags alpine \
    sh -c 'nsenter --target $(pgrep dockerd) --mount --uts --ipc --pid sh /var/lib/dev-env/start-k3s.sh'

  IP_ADDRESS="$(docker inspect k3s | jq '.[0].NetworkSettings.IPAddress' -r)"

  ## Loadbalancers
  docker run -d --restart=always --name proxy -p 6443:6443 hpello/tcp-proxy "$IP_ADDRESS" 6443 # k3s
  docker run -d --restart=always --name proxy-https -p 443:443 hpello/tcp-proxy "$IP_ADDRESS" 443 # https-traefik
  docker run -d --restart=always --name proxy-http -p 80:80 hpello/tcp-proxy "$IP_ADDRESS" 80 # http-traefik
}

get_kubeconfig() {
  docker run --privileged --pid=host -it --rm alpine sh -c 'cat /proc/$(pgrep dockerd)/root/etc/rancher/k3s/k3s.yaml' 2>&1
  return $?
}

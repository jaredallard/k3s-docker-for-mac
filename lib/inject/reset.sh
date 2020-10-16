#!/usr/bin/env sh
#
# Stops and resets k3s

echo " -> Stopping Kubernetes"
if docker inspect k3s >/dev/null 2>&1; then
  {
    docker stop -t 0 k3s
    docker rm k3s
  } >/dev/null
fi

echo " -> Stopping and Removing Kubernetes Containers ..."
containerIDs="$(docker ps --all --filter "name=k8s_*" --quiet)"
if test -n "$containerIDs"; then
  echo "$containerIDs" | xargs --max-args 20 docker stop --time 0 >/dev/null
  echo "$containerIDs" | xargs --max-args 20 docker rm >/dev/null
fi

echo " -> Cleaning up Kubernetes Installation"
# We don't actually care if this succeeds, since the start script
# will handle failure.
{
  umount -v /etc/rancher
  umount -v /var/lib/rancher
  umount -v /opt/cni/bin
} 2>/dev/null

# clean up the actual bindmount directory, but leave the CNI plugins
# and the k3s binary for future installs
rm -rf /var/lib/k3s-dfm/rancher

echo " -> Cleaning up Docker Volumes"

# We search for volumes of len 64, that's what seems to be local path only volumes. This reduces
# the chance of us nuking a volume that someone cares about. Unforunately deleting them via
# k8s doesn't always work... this seems to be the only way that reliably does.
volumeIDs=$(docker volume ls --quiet --filter "driver=local")
if test -n "$volumeIDs"; then
  echo "$volumeIDs" | xargs --max-args 1 docker volume rm >/dev/null
fi

echo " -> Removing Docker Network"
docker network rm k3s-dfm

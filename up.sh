#!/usr/bin/env bash
#
# Run k3s on Docker for Mac w/ host docker.
set -e

# directories
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
LIBDIR="$DIR/lib"

export KUBECONFIG="$HOME/.k3s/kubeconfig.yaml"

# ensure the dir exists
mkdir -p "$(dirname "$KUBECONFIG")"

# shellcheck source="./lib/k3s.sh"
. "$LIBDIR/k3s.sh"
# shellcheck source="./lib/logging.sh"
. "$LIBDIR/logging.sh"


info "checking pre-reqs"
deps=("docker" "jq")
for dep in "${deps[@]}"; do
  install_command="brew install $dep"
  if ! command -v "$dep" >/dev/null 2>&1; then
    info "you can install '$dep' via brew: $install_command"
    fatal "failed to find '$dep'"
  fi
done

# lib/k3s.sh
start_k3s

# sleep for 20 seconds since the intial kubeconfig isn't actually it sometimes
# TODO(jaredallard): do some sort of cert validation or something to detect when it changed
sleep 20

info "waiting for cluster to create kubeconfig...\c"
while ! get_kubeconfig >/dev/null 2>&1; do
  echo -n "."
  sleep 5
done
echo "done"

info " -> writing kubeconfig to '$KUBECONFIG'"
get_kubeconfig | sed 's/default/k3s/g' > "$KUBECONFIG"

# wait until the cluster is ready
until kubectl get node | grep Ready >/dev/null; do
  info "waiting for cluster to be up ..."
  sleep 5
done

info "cluster is ready"

info "To connect to this cluster, run:"
echo "export KUBECONFIG=\"$kubeConfig\""
echo 'kubectl config use-context k3s'
echo "Note: You can also add: export KUBECONFIG=\"$KUBECONFIG:$kubeConfig\" to your ~/.shellrc instead."

#!/usr/bin/env bash
#
# Run k3s on Docker for Mac w/ host docker.
set -e

# directories
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
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
init_k3s

info "waiting for cluster to create kubeconfig...\c"
while true; do
  get_kubeconfig | sed 's/default/k3s/g' >"$KUBECONFIG"

  # check to make sure the kubeconfig actually works
  if kubectl get node 2>/dev/null | grep Ready >/dev/null; then
    break
  fi

  echo -n "."
  sleep 5
done
echo "done"

info " -> writing kubeconfig to '$KUBECONFIG'"
get_kubeconfig | sed 's/default/k3s/g' >"$KUBECONFIG"

# wait until the cluster is ready
until kubectl get node | grep Ready >/dev/null; do
  info "waiting for cluster to be up ..."
  sleep 5
done

info "cluster is ready"

info "To connect to this cluster, run:"
echo
# shellcheck disable=SC2016
echo '  export KUBECONFIG="$kubeConfig"'
echo '  kubectl config use-context k3s'
echo
# shellcheck disable=SC2016
echo '  Note: You can also add: export KUBECONFIG="$KUBECONFIG:$kubeConfig" to your ~/.shellrc instead.'

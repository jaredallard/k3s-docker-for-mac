#!/usr/bin/env bash
#
# Stop a running developer environment

# directories
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
LIBDIR="$DIR/lib"

# shellcheck source="./lib/k3s.sh"
. "$LIBDIR/k3s.sh"
# shellcheck source="./lib/logging.sh"
. "$LIBDIR/logging.sh"

info "cleaning up cluster"
reset_k3s

info "finished"
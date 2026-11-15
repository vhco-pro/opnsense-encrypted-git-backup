#!/usr/bin/env bash
set -euo pipefail
# The Linux runner owns the publisher. Only the client's verification command
# crosses into the guest. Keep the HTTP listener and SSH reverse forward local.
[[ $# == 1 && "$1" =~ ^[0-9]+$ ]]
exec ssh -o BatchMode=yes -o ExitOnForwardFailure=yes -N \
    -R "127.0.0.1:$1:127.0.0.1:$1" freebsd

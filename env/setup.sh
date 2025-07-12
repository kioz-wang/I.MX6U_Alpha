#!/usr/bin/env bash

# shellcheck disable=SC2155
declare -r P_ENV=$(realpath "${BASH_SOURCE[0]%/*}")
declare -r P_ROOT=$(dirname "${P_ENV}")
declare -r N_ROOT=$(basename "${P_ROOT}")

function build() {
    podman build --http-proxy=false --build-arg-file "${P_ENV}"/argfile.conf --tag kioz0wang/buildenv:1.0 -f "${P_ENV}"/Containerfile.buildenv
}

function create() {
    podman container create --http-proxy=false --interactive --tty --publish 10022:10022 --volume "${P_ROOT}":"/root/${N_ROOT}" --name buildenv localhost/kioz0wang/buildenv:1.0
}

function run() {
    podman container start buildenv || return $?
    echo "=> login root with password [123]"
    echo "  ssh -o StrictHostKeyChecking=no -p 10022 root@localhost"
}

function run_attach() {
    run || return $?
    podman container attach buildenv
}

function run_once() {
    podman run --rm --http-proxy=false --interactive --tty --publish 10022:10022 --volume "${P_ROOT}":"/root/${N_ROOT}" localhost/kioz0wang/buildenv:1.0
}

function main() {
    local -r fn=$1
    shift
    ${fn} "$@"
    echo "Result(${fn}) = $?"
}

main "$@"

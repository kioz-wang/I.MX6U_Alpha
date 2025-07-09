#!/usr/bin/env bash

function build() {
    podman build --http-proxy=false --build-arg-file argfile.conf --tag kioz0wang/buildenv:1.0 -f Containerfile.buildenv "$@"
}

function create() {
    podman container create --http-proxy=false -it --publish 10022:10022 localhost/kioz0wang/buildenv:1.0 --name buildenv "$@"
    podman container start buildenv
}

function main() {
    local -r fn=$1
    shift
    ${fn} "$@"
    echo "Result(${fn}) = $?"
}

main "$@"

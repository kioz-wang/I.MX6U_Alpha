#!/usr/bin/env bash

# shellcheck disable=SC2155
declare -r P_ENV=$(realpath "${BASH_SOURCE[0]%/*}")
declare -r P_ROOT=$(dirname "${P_ENV}")
declare -r N_ROOT=$(basename "${P_ROOT}")

declare g_target
declare g_tag

function build() {
    if [[ ${g_tag} == "latest" ]]; then
        echo "Don't use tag 'latest'"
        return 1
    fi

    if [ -f "${P_ENV}/${g_target}/.pre" ]; then
        bash "${P_ENV}/${g_target}/.pre" "${P_ROOT}" || return $?
    fi

    podman build --http-proxy=false --build-arg-file "${P_ENV}"/argfile.conf \
        --tag "kioz0wang/${g_target}:${g_tag}" \
        -f "${P_ENV}/${g_target}/Containerfile" || return $?
    podman tag "kioz0wang/${g_target}:${g_tag}" "kioz0wang/${g_target}:latest" || return $?

    if [ -f "${P_ENV}/${g_target}/.post" ]; then
        bash "${P_ENV}/${g_target}/.post" "${P_ROOT}" || return $?
    fi
}

function create() {
    if [ $# -lt 1 ]; then
        echo "Usage: create {name} [ssh_port]"
        return
    fi
    local -r name=$1
    local -i ssh_port
    local -a publish
    if [ $# -gt 1 ]; then
        ssh_port=$2
        publish=(--publish "${ssh_port}:10022")
    fi
    podman container create --http-proxy=false --interactive --tty \
        "${publish[@]}" \
        --volume "${P_ROOT}":"/root/${N_ROOT}" \
        --name "${name}" \
        "kioz0wang/${g_target}:${g_tag}" || return $?
    if [ -n "${ssh_port}" ]; then
        echo "=> start and login root with password [123]"
        echo "  podman start ${name}"
        echo "  ssh -o StrictHostKeyChecking=no -p ${ssh_port} root@localhost"
    else
        echo "=> start and attach"
        echo "  podman container start --attach ${name}"
    fi
}

function run_once() {
    local -i ssh_port
    local -a publish
    if [ $# -gt 0 ]; then
        ssh_port=$1
        publish=(--publish "${ssh_port}:10022")
    fi
    podman run --rm --http-proxy=false --interactive --tty \
        "${publish[@]}" \
        --volume "${P_ROOT}":"/root/${N_ROOT}" \
        "kioz0wang/${g_target}:${g_tag}"
}

function main() {
    if [ $# -lt 3 ]; then
        echo "Usage: setup.sh {target} {tag} {action} [...]"
        echo "  build"
        echo "  create {name} [ssh_port]"
        echo "  run_once [ssh_port]"
        return
    fi
    g_target=$1
    g_tag=$2
    local -r action=$3
    shift 3
    ${action} "$@"
    echo "Result(${action}) = $?"
}

main "$@"

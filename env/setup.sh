#!/usr/bin/env bash

# shellcheck disable=SC2155
declare -rx P_ENV=$(realpath "${BASH_SOURCE[0]%/*}")
declare -rx P_ROOT=$(dirname "${P_ENV}")
declare -rx N_ROOT=$(basename "${P_ROOT}")

if [ $# -lt 3 ]; then
    echo "Usage: setup.sh {target} {tag} {action} [...]"
    echo "  build"
    echo "  create {name} [ssh_port]"
    echo "  run_once [ssh_port]"
    exit 1
fi
declare -rx N_TARGET=$1
declare -rx N_TAG="kioz0wang/${N_TARGET}:$2"
shift 2

declare -rx P_TARGET="${P_ENV}/${N_TARGET}"

function foreach_dependencies() {
    local -r is_pre=$1
    local item
    if [ -f "${P_TARGET}/.dependencies" ]; then
        while read -r item; do
            [[ -z "${item}" ]] && continue
            if [[ ${item} != /* ]]; then
                item="${P_ROOT}/${item}"
            fi
            if ${is_pre}; then
                ln -vf "${item}" "${P_TARGET}"/ || return $?
            else
                rm -v "${P_TARGET}/$(basename "${item}")" || return $?
            fi
        done < "${P_TARGET}/.dependencies"
    fi
}
function pre_build() {
    foreach_dependencies true  || return $?
    if [ -f "${P_TARGET}/.pre" ]; then
        (cd "${P_TARGET}" && bash .pre) || return $?
    fi
}
function post_build() {
    foreach_dependencies false  || return $?
    if [ -f "${P_TARGET}/.post" ]; then
        (cd "${P_TARGET}" && bash .post) || return $?
    fi
}

function action_build() {
    if [[ ${N_TAG##*:} == "latest" ]]; then
        echo "Don't use tag 'latest'"
        return 1
    fi
    pre_build || return $?
    podman build --http-proxy=false --build-arg-file "${P_ENV}"/argfile.conf \
        --tag "${N_TAG}" \
        -f "${P_TARGET}/Containerfile" || return $?
    podman tag "${N_TAG}" "kioz0wang/${N_TARGET}:latest" || return $?
    post_build || return $?
}

function action_create() {
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
        "${N_TAG}" || return $?
    if [ -n "${ssh_port}" ]; then
        echo "=> start and login root with password [123]"
        echo "  podman start ${name}"
        echo "  ssh -o StrictHostKeyChecking=no -p ${ssh_port} root@localhost"
    else
        echo "=> start and attach"
        echo "  podman container start --attach ${name}"
    fi
}

function action_run_once() {
    local -i ssh_port
    local -a publish
    if [ $# -gt 0 ]; then
        ssh_port=$1
        publish=(--publish "${ssh_port}:10022")
    fi
    podman run --rm --http-proxy=false --interactive --tty \
        "${publish[@]}" \
        --volume "${P_ROOT}":"/root/${N_ROOT}" \
        "${N_TAG}"
}

function main() {
    local -r action=$1
    shift
    "action_${action}" "$@"
    echo "Result(${action}) = $?"
}

main "$@"

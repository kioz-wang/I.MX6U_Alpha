#!/usr/bin/env bash

# shellcheck disable=SC2317
function push_path() {
    case ":$PATH:" in
        *:"$1":*)
            ;;
        *)
            PATH="$1${PATH:+:$PATH}"
    esac
}

if [[ -d /opt/.toolchain.env.d ]] && [[ -n $(ls /opt/.toolchain.env.d) ]]; then
    for tc in /opt/.toolchain.env.d/*; do
        echo "Sourcing ${tc}"
        # shellcheck disable=SC1090
        source "${tc}"
    done; unset tc
fi

unset -f push_path
export PATH

#!/usr/bin/env bash

function push_path() {
    case ":$PATH:" in
        *:"$1":*)
            ;;
        *)
            PATH="$1${PATH:+:$PATH}"
    esac
}

push_path "/opt/arm-gnu-toolchain-12.3.rel1-x86_64-arm-none-linux-gnueabihf/bin"
push_path "/opt/arm-gnu-toolchain-12.3.rel1-x86_64-aarch64-none-linux-gnu/bin"
export PATH

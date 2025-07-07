#!/usr/bin/env bash

podman build --http-proxy=false --tag kioz0wang/buildenv:1.0 -f Containerfile.buildenv

#!/usr/bin/env bash
# Shell script for starting Docker container
# TBD:  - Check other useful Docker CLI options
# 
# Create output directory if not exists
mkdir -p output
docker run \
 --mount type=bind,source="$(pwd)",target=/usr/app/src/data,readonly \
 --mount type=bind,source="$(pwd)/output",target=/usr/app/src/output \
 --net none \
 --security-opt seccomp=seccomp-default.json \
 --security-opt=no-new-privileges \
 --read-only --tmpfs /tmp \
 --cap-drop all \
 --rm \
 test_app "$@" 
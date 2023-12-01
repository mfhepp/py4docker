#!/usr/bin/env bash
# Shell script for starting Docker container
# TBD:  - Check other useful Docker CLI options
# 

SOURCE_MOUNT=""
SOURCE_ACCESS=",readonly"
# Change to SOURCE_ACCESS="" if container should be able to write to the source folder
# Make sure you understand the security implications!
NETWORK="--net=none"
PARAMETERS=""
IMAGE_NAME="test_app"
COMMAND="python ./main.py"
# Change to COMMAND="python -u ./main.py" if you want print() statements 
# to be visible on stdout (default: logging only)

usage ()
{
    printf "Starts the ${IMAGE_NAME} application inside a Docker container"
    printf 'Usage: %s [OPTIONS] [APP_ARGS]\n\n' "$0"
    printf 'Options:\n'
    printf '  -d: (D)evelopment mode (mount local volume, as read-only)\n'
    printf '  -i: (i)nteractive mode (keep terminal open and start with bash)\n'
    printf '  -n: Allow outbound (N)etwork access to host network\n'
    printf '  --help: Show help\n'
}

if [[ $1 = "--help" ]]; then
   usage
   exit 0
fi

while getopts ":din" opt; do
  case ${opt} in
    d)
      echo "Development mode enabled (running code from local file)"
      echo "Using image ${IMAGE_NAME}_dev"
      SOURCE_MOUNT="--mount type=bind,source="$(pwd)/src",target=/usr/app/src,readonly"
      IMAGE_NAME="${IMAGE_NAME}_dev"
      ;;
    i)
      echo "Interactive mode enabled, keeping terminal open (use 'exit' to quit)"
      PARAMETERS="-it"
      COMMAND="/bin/sh"
      ;;
    n)
      echo "Outbound network ENABLED (Warning: The script can access the entire host network)"
      NETWORK="--net=host"
      ;;        
  esac
done
# Remove processed
shift $((OPTIND-1))
echo DEBUG: $COMMAND "$@"
echo
# Create output directory if not exists
mkdir -p output
docker run \
$PARAMETERS \
$SOURCE_MOUNT \
 --mount type=bind,source="$(pwd)",target=/usr/app/src/data,readonly \
 --mount type=bind,source="$(pwd)/output",target=/usr/app/src/output \
$NETWORK \
 --security-opt seccomp=seccomp-default.json \
 --security-opt=no-new-privileges \
 --read-only --tmpfs /tmp \
 --cap-drop all \
 --rm \
 $IMAGE_NAME $COMMAND "$@"


 
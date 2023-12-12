#!/usr/bin/env bash
# Shell script for building Docker image

IMAGE_NAME="test_app"

usage ()
{
    printf 'Builds the Docker image from the Dockerfile\n'
    printf 'Usage: %s [OPTIONS] \n\n' "$0"
    printf 'Option(s):\n'
    printf "  -d: development mode (create ${IMAGE_NAME}_dev)\n"
    printf '  -f: force fresh build, ignoring caches (will update Python packages)\n'
    printf '  -n: notebook mode, build noteboot image\n'        

}

CACHED=""

while getopts ":dfn" opt; do
  case ${opt} in
    d)
      echo "Building development image as ${IMAGE_NAME}_dev"
      IMAGE_NAME="${IMAGE_NAME}_dev"
      ;;
    f)
      echo "Force fresh build, ignoring caches (will update Python packages)"
      PARAMETERS="--no-cache"
      ;;
    n)
      echo "Building notebook image as ${IMAGE_NAME}_notebook"
      IMAGE_NAME="${IMAGE_NAME}_notebook"
      ;;
    ?)
      usage && exit 1
  esac
done

docker build $PARAMETERS --progress=plain --tag $IMAGE_NAME .

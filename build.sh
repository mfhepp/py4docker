#!/usr/bin/env bash
# Shell script for building Docker image
# It is possible to set UID, GID, and username to the matching 
# user on the host by building a local image from mambaorg/micromamba
#    git clone https://github.com/mamba-org/micromamba-docker.git
#    cd micromamba-docker
#    docker build . -t micromamba_local_user --build-arg="MAMBA_USER=$USER" \
#      --build-arg="MAMBA_USER_ID=$(id -u)" \
#      --build-arg="MAMBA_USER_GID=$(id -g)"
# and then change the base image in the Dockerfile from e.g.
#    mambaorg/micromamba:1.5.6
# to
#    micromamba_local_user

IMAGE_NAME="test_app"

usage ()
{
    printf 'Builds the Docker image from the Dockerfile\n'
    printf 'Usage: %s [OPTIONS] \n\n' "$0"
    printf 'Option(s):\n'
    printf "  -d: development mode (create ${IMAGE_NAME}_dev)\n"
    printf '  -f: force fresh build, ignoring caches (will update Python packages)\n'    

}

CACHED=""

while getopts ":df" opt; do
  case ${opt} in
    d)
      echo "Building development image as ${IMAGE_NAME}_dev"
      IMAGE_NAME="${IMAGE_NAME}_dev"
      ;;
    f)
      echo "Force fresh build, ignoring caches (will update Python packages)"
      PARAMETERS="--no-cache"
      ;;
    ?)
      usage && exit 1
  esac
done

docker build $PARAMETERS --progress=plain --tag $IMAGE_NAME .

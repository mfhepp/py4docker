#!/usr/bin/env bash
# Shell script for starting Jupyter Notebook inside Docker container

# IMAGE_NAME="test_app_dev"
USERNAME=$USER
NOTEBOOK_ID="notebook"
DIGEST=""
NETWORK="--net=bridge"
# Get absolute paths
PWD=$(pwd)
REAL_PWD=$(realpath .)
SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
NOTEBOOK_DIR_MOUNT="--mount type=bind,source=$REAL_PWD,target=/usr/app/src"
# Create Jupyter security token so that we have it for opening the browser
TOKEN=$(uuidgen | tr '[:upper:]' '[:lower:]')"-"$(uuidgen | tr '[:upper:]' '[:lower:]')
COMMAND="jupyter notebook --port 8888 --ip=0.0.0.0 --no-browser --notebook-dir=/usr/app/src --IdentityProvider.token=$TOKEN --KernelSpecManager.ensure_native_kernel=False"

usage ()
{
    printf "Starts Jupyter Notebook inside a Docker container\n"
    printf 'Usage: %s [OPTIONS] [<env_name>]\n\n' "$0"
    printf 'Option(s):\n' 
    printf '  -i: (i)nteractive mode (start shell instead of Jupyter for debugging)\n'
    printf '  --list: List available notebook images\n'
    printf '  --help: Show help\n'
}

if [[ $1 = "--help" ]]; then
   usage
   exit 0
fi

if [[ $1 = "--list" ]]; then
   echo Available notebook images:
   echo -------------------------
   docker images $USER/$NOTEBOOK_ID
   exit 0
fi

while getopts ":i" opt; do
  case ${opt} in   
    i)
      echo "Interactive mode enabled, starting shell and keeping terminal open (use 'exit' to quit)"
      echo Use e.g. $COMMAND
      COMMAND="/bin/sh"
      ;;   
  esac
done
# Remove processed options
shift $((OPTIND-1))
DIGEST=$1
IMAGE_NAME="${USER}/${NOTEBOOK_ID}${DIGEST:+:$DIGEST}"
echo INFO: Docker image = $IMAGE_NAME
# Internal Jupyter paths:
#      config -> /opt/conda/etc/jupyter
#      data -> /opt/conda/share/jupyter
#      bin -> /opt/conda/bin/jupyter
# https://github.com/jupyter/docker-stacks/blob/main/images/base-notebook/Dockerfile
# https://docs.jupyter.org/en/latest/use/jupyter-directories.
echo "WARNING: Outbound network ENABLED (the notebook and all components can access the entire host network)"
echo "WARNING: Jupyter Notebook will have WRITE-ACCESS to $PWD [$REAL_PWD]"
read -n1 -p "Do you REALLY want to continue (Y/N)?" reply
echo ""
[ "$reply" != "Y" ] && [ "$reply" != "y" ] && echo "Aborting." && exit 1

# Open browser
open http://localhost:8888/?token=$TOKEN
docker run -it -p 8888:8888 \
    $NOTEBOOK_DIR_MOUNT \
    $NETWORK \
    --security-opt seccomp=${SCRIPT_DIR}/seccomp-default.json \
    --security-opt=no-new-privileges \
    --cap-drop all \
    --rm \
    $IMAGE_NAME $COMMAND
  echo INFO: Shutting down Jupyter Notebook
  exit 0
fi

# TODO: read-only file system does not seem to work for Jupyter kernels
#     --read-only --tmpfs /tmp --tmpfs /home/mambauser/ \

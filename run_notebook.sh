#!/usr/bin/env bash
# Shell script for starting Jupyter Notebook inside Docker container

# IMAGE_NAME="test_app_dev"

USERNAME=$USER
NOTEBOOK_ID="notebook"
DIGEST=""
NETWORK="--net=bridge"
DATA_DIR=""
DATA_DIR_MOUNT=""
# SECRETS_DIR=""
# SECRETS_MOUNT=""
# Array for secrets
declare -a SECRETS_MOUNTS

# DATA_DIR_MOUNT="--mount type=bind,source=$DATA_DIR,target=/mnt/data,readonly"
# Create Jupyter security token so that we have it for opening the browser
TOKEN=$(uuidgen | tr '[:upper:]' '[:lower:]')"-"$(uuidgen | tr '[:upper:]' '[:lower:]')
# Get absolute paths
PWD=$(pwd)
REAL_PWD=$(realpath .)
SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
NOTEBOOK_DIR_MOUNT="--mount type=bind,source=$REAL_PWD,target=/usr/app/src"

usage ()
{
    printf "Starts Jupyter Notebook inside a Docker container\n"
    printf 'Usage: %s [OPTIONS] [<env_name>]\n\n' "$0"
    printf 'Option(s):\n' 
    printf '  -i: (i)nteractive mode (starts a Bash shell instead of Jupyter for debugging)\n'
    printf '  --data-dir <DIRECTORY>: Mount <DIRECTORY> as /mnt/data inside the image\n'
    printf '  --add_secret <FILE> <NAME>: Mount <FILE> as /mnt/secrets/<NAME> inside the image\n'
    printf '  --list: List available notebook images\n'
    printf '  --help: Show help\n'
}

list_environments() {
   echo "Available notebook images / environments:"
   echo "-------------------------"
   docker images $USER/$NOTEBOOK_ID   
}


# Check for --help or --list in the parameters
for arg in "$@"; do
    case "$arg" in
        --help)
            usage
            exit 0
            ;;
        --list)
            list_environments
            exit 0
            ;;
    esac
done

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case "$1" in
        --data-dir)
            DATA_DIR="$2"
            DATA_DIR_MOUNT="--mount type=bind,source=$DATA_DIR,target=/mnt/data,readonly"
            echo "Mounting $DATA_DIR as /mnt/data"       
            shift 2 # move past argument and value
            ;;
        --add-secret)
            if [[ $# -lt 3 ]]; then
                echo "Error: Insufficient arguments. Please provide both secrets file and name." >&2
                exit 1
            fi
            SECRETS_FILE=$(realpath "$2")
            SECRETS_NAME="$3"
            SECRETS_MOUNT="--mount type=bind,source=$SECRETS_FILE,target=/mnt/secrets/$SECRETS_NAME,readonly"
            SECRETS_MOUNTS+=("$SECRETS_MOUNT")  # Add to array of filenames
            shift 3 # move past argument and two value            
            echo "Mounting $SECRETS_FILE as /mnt/secrets/$SECRETS_NAME"
            ;;
        -i)
            echo "Interactive mode enabled, starting shell and keeping terminal open (use 'exit' to quit)"
            echo Use e.g. $COMMAND
            COMMAND="/bin/bash"
            shift # move past argument
            ;;
        -*)
            # Catch additional options
            echo "Error: Unrecognized option $1" >&2
            exit 1
            ;;
        *) 
            # Name of image / environment / kernel
            DIGEST="$1"
            shift  # Move to next argument
            ;;            

    esac
done

# Export variables as environment variables, if needed; likely not
# export USE_ENV_VAR="$USE_VALUE"


# Jupyter 3:
# COMMAND="jupyter notebook --port 8888 --ip=0.0.0.0 --no-browser --notebook-dir=/usr/app/src --IdentityProvider.token=$TOKEN --KernelSpecManager.ensure_native_kernel=False"
# New in Jupyter 4.1
# Not sure we actually have to export it(?)
export JUPYTER_TOKEN=$TOKEN
COMMAND="jupyter notebook --port 8888 --ip=0.0.0.0 --no-browser --NotebookApp.token=$JUPYTER_TOKEN --notebook-dir=/usr/app/src --KernelSpecManager.ensure_native_kernel=False"
# Take e.g. "foo" if given as the digest name for the image based on foo.yaml
IMAGE_NAME="${USER}/${NOTEBOOK_ID}${DIGEST:+:$DIGEST}"
echo INFO: Using Docker image $IMAGE_NAME
echo INFO: Jupyter access token is $TOKEN
# Expected internal Jupyter paths:
#      config -> /opt/conda/etc/jupyter
#      data -> /opt/conda/share/jupyter
#      bin -> /opt/conda/bin/jupyter
# https://github.com/jupyter/docker-stacks/blob/main/images/base-notebook/Dockerfile
# https://docs.jupyter.org/en/latest/use/jupyter-directories.
# We also add
#      secrets -> /mnt/secrets
#      additional data -> /mnt/data
#
echo "WARNING: Outbound network ENABLED (the notebook and all components can access the entire host network)"
echo "WARNING: Jupyter Notebook will have WRITE-ACCESS to $PWD [$REAL_PWD]"
read -n1 -p "Do you REALLY want to continue (Y/N)?" reply
echo ""
[ "$reply" != "Y" ] && [ "$reply" != "y" ] && echo "Aborting." && exit 1

# Open browser
# TBD: Find a way to delay that
open http://localhost:8888/?token=$TOKEN
docker run -it -p 8888:8888 \
    $NOTEBOOK_DIR_MOUNT \
    ${SECRETS_MOUNTS[@]} \
    $DATA_DIR_MOUNT \
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
# This also prevents adding new packages via the !command syntax

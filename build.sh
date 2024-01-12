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

# Images should use user:name:digest in order to avoid collisions
USERNAME=$USER
APPLICATION_ID="test_app"
NOTEBOOK_ID="notebook"
BUILD_NOTEBOOK=""
DIGEST=""
ENVIRONMENT_FILE="env.yaml"

usage ()
{
    printf 'Builds the Docker image from the Dockerfile\n'
    printf 'Usage: %s [OPTIONS] [<env_name>.yaml]\n\n' "$0"
    printf 'Option(s):\n'
    printf "  -d: development mode (create $USER/$APPLICATION_ID:dev)\n"
    printf '  -f: force fresh build, ignoring cached build stages (will e.g. update Python packages)\n'
    printf "  -n: Jupyter Notebook mode (create $USER/$NOTEBOOK_ID or $USER/$NOTEBOOK_ID:<env_name>)\n"    
}

if [[ $1 = "--help" ]]; then
   usage
   exit 0
fi

while getopts ":dfn" opt; do
  case ${opt} in
    d)
      if [ "$APPLICATION_ID" = "$NOTEBOOK_ID" ]; then
        echo "ERROR: Incompatible options -d and -n. Aborting."
        exit 1
      else
        echo "INFO: Building DEVELOPMENT image"    
        DIGEST="dev"
      fi
      ;;
    f)
      echo "INFO: Force fresh build, ignoring cached build stages (will update Python packages and Debian packages)"
      PARAMETERS="--no-cache"
      ;;
    n)
      if [ "$DIGEST" = "dev" ]; then
        echo "ERROR: Incompatible options -d and -n. Aborting."
        exit 1
      else
        echo "INFO: Building Jupyter NOTEBOOK image"
        ENVIRONMENT_FILE="notebook.yaml"
        APPLICATION_ID=$NOTEBOOK_ID
        BUILD_NOTEBOOK="--build-arg NOTEBOOK_MODE=true"
      fi
      ;;      
    ?)
      usage && exit 1
  esac
done

# Remove processed arguments
shift $((OPTIND-1))

if [ $# -eq 0 ]; then
  echo "INFO: Environment file = $ENVIRONMENT_FILE"
else
  ENVIRONMENT_FILE="$1.yaml"
  # user:test_app:env-dev
  # user:test_app:env
  DIGEST="$1${DIGEST:+-$DIGEST}"
  echo "INFO: Environment file = $ENVIRONMENT_FILE"
fi
# Test if environment file exists
if [ ! -f "$ENVIRONMENT_FILE" ]; then
    echo "ERROR: Environment file $ENVIRONMENT_FILE not found. Aborting."
    exit 1
fi

# Hint: ${DIGEST:+:$DIGEST} means add ":value" if variable DIGEST is set, nothing otherwise
IMAGE_NAME="${USER}/${APPLICATION_ID}${DIGEST:+:$DIGEST}"
echo INFO: Image tag = $IMAGE_NAME
docker build $PARAMETERS \
 --build-arg="ENVIRONMENT_FILE=$ENVIRONMENT_FILE" \
$BUILD_NOTEBOOK \
 --progress=plain --tag $IMAGE_NAME .

#!/usr/bin/env bash
# Shell script for starting Docker container with main.py
# TODO:  - Check other useful Docker CLI options

APPLICATION_ID="test_app"
# Change to name of alternate Python environment if needed
# Example:
# DIGEST="foo" for user/test_app:foo from foo.yaml
DIGEST=""
SOURCE_MOUNT=""
NETWORK="--net=none"
PARAMETERS=""
# Change to COMMAND="python -u ./main.py" if you want print() statements 
# to be visible on stdout (default: logging only)
COMMAND="python ./main.py"

usage ()
{
    printf "Starts the ${USER}/${IMAGE_NAME} application inside a Docker container\n"
    printf 'Usage: %s [OPTIONS] [APP_ARGS]\n\n' "$0"
    printf 'Options:\n'
    printf '  -d: (D)evelopment mode (mount local volume, as read-only)\n'
    printf '  -D: Expert (D)evelopment mode with WRITE ACCESS to src/ \n'    
    printf '  -i: (i)nteractive mode (keep terminal open and start with bash)\n'
    printf '  -n: Allow outbound (N)etwork access to host network\n'
    printf '  --help: Show help\n'
}

if [[ $1 = "--help" ]]; then
   usage
   exit 0
fi
# Get absolute paths
REAL_PWD=$(realpath .)
echo "INFO: Working directory is $REAL_PWD"
# Determine absolute path from which the script is being executed
# This will be used to find the src/ folder for the development mode
SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
SOURCE_DIR=${SCRIPT_DIR}/src
echo "INFO: Source code path is $SOURCE_DIR"
# Mapping user id and user group for Linux bind mounts
UID_HOST=$(id -u)
GID_HOST=$(id -g)
echo "INFO: Local User has UID = $UID_HOST, GID = $GID_HOST"
if [[ $UID_HOST -lt 1000 ]]; then
    echo "INFO: The User ID is < 1000, not passed to container user"
    echo "Most likely, you are running Docker Desktop on OSX."
    USER_MAPPING=""
    MOUNT_SUFFIX=""
else
    USER_MAPPING="--user $UID_HOST:$GID_HOST"
    # Disable
    MOUNT_SUFFIX=",userns=host"
fi
while getopts ":dDin" opt; do
  case ${opt} in
    d)
      if [ -n "$DIGEST_SUFFIX" ]; then
      echo "ERROR: Incompatible options -d and -D. Aborting."
      exit 1
      else
      echo "INFO: Development mode enabled (running code from local file)"
      DIGEST_SUFFIX="dev"
#      echo "Using image ${IMAGE_NAME}_dev"
      SOURCE_MOUNT="--mount type=bind,source=$SCRIPT_DIR/src,target=/usr/app/src,readonly"
#      IMAGE_NAME="${IMAGE_NAME}_dev"
      fi
      ;;
    D)
      if [ -n "$DIGEST_SUFFIX" ]; then
      echo "ERROR: Incompatible options -d and -D. Aborting."
      exit 1
      else
      echo "INFO: EXPERT development mode enabled (running code from local file)"
      echo "WARNING: Write access granted to $SCRIPT_DIR/src"
      read -n1 -p "Do you REALLY want to continue (Y/N)?" reply
      echo ""
      [ "$reply" != "Y" ] && [ "$reply" != "y" ] && echo "Aborting." && exit 1
      DIGEST_SUFFIX="dev"
      # echo "Using image ${IMAGE_NAME}_dev"
      # SOURCE_MOUNT="--mount type=bind,source=$SCRIPT_DIR/src,target=/usr/app/src$MOUNT_SUFFIX"
      SOURCE_MOUNT="-v $SCRIPT_DIR/src:/usr/app/src$MOUNT_SUFFIX" \
      # IMAGE_NAME="${IMAGE_NAME}_dev"
      fi
      ;;      
    i)
      echo "INFO: Interactive mode enabled, keeping terminal open (use 'exit' to quit)"
      PARAMETERS="-it"
      COMMAND="/bin/bash"
      ;;
    n)
      echo "INFO: Outbound network ENABLED (Warning: The script can access the entire host network)"
      NETWORK="--net=host"
      ;;        
  esac
done
if [ -n "$DIGEST" ]; then
  # user:test_app:foo -> user:test_app:foo-dev
  DIGEST="$DIGEST${DIGEST_SUFFIX:+-DIGEST_SUFFIX}"
else
  DIGEST=$DIGEST_SUFFIX
fi
IMAGE_NAME="${USER}/${APPLICATION_ID}${DIGEST:+:$DIGEST}"

# Remove processed arguments
shift $((OPTIND-1))

# In developer mode, we need to make sure that,
# no matter from which working directory the script is being executed, 
#   1. the proper source code directory is used for the bind mount,
#   2. the source code directory is not a subdirectory of the working directory,
#   3. the working directory is not a subdirectory of the source code directory, and
#   4. that the two directories are not equal.
# Otherwise, lots of nasty things can happen ;-).
# Also, we may encounter symbolic links when checking this; they must be 
# dereferenced to their absolute paths.
# In the cases 2. and 3. we can mitigate the issue by blocking the overlapping path
# via an anonymous, read-only volume.
# But this may also lead to trouble (e.g., a subdirectory of src will be inaccessible).
if [ "$REAL_PWD" = "$SOURCE_DIR" ]  && [ -n "$DEV" ]; then
    echo "ERROR: In development mode, the working directory and source code directory must not be equal. Aborting."
    exit 1
fi

MOUNT_BEFORE_PWD=""
MOUNT_AFTER_PWD=""
FIX_OVERLAP_MOUNT=""

# Determine if the source code path is below the working directory
case $SOURCE_DIR/ in 
    $REAL_PWD/*) echo "WARNING: src/ IS in $REAL_PWD/*"
    # Fix is to block the _source_ directory in /usr/app/data via an anonymous volume
    # ${SOURCE_DIR#$REAL_PWD/} is $(realpath --relative-to="$REAL_PWD/" "$SOURCE_DIR/")
    FIX_OVERLAP_MOUNT="--mount type=volume,target=/usr/app/data/${SOURCE_DIR#$REAL_PWD/}"
    # We will FIRST mount the upper host directory, in this case the PWD
    MOUNT_AFTER_PWD=$SOURCE_MOUNT
    echo INFO: Blocking overlapping paths via $FIX_OVERLAP_MOUNT
    ;;
    *) echo "INFO: src/ IS NOT in $REAL_PWD/*" ;;
esac
# Determine if the working directory is below the source code path  
case $REAL_PWD/ in 
    $SOURCE_DIR/*) echo "WARNING: $REAL_PWD IS in src/*"
    # ${REAL_PWD#$SOURCE_DIR/} is $(realpath --relative-to="$SOURCE_DIR/" "$REAL_PWD/")
    FIX_OVERLAP_MOUNT="--mount type=volume,target=/usr/app/src/${REAL_PWD#$SOURCE_DIR/}"
    # We will FIRST mount the upper host directory, in this case the source directory
    MOUNT_BEFORE_PWD=$SOURCE_MOUNT
    echo INFO: Blocking overlapping paths via $FIX_OVERLAP_MOUNT
    ;;
    *) echo "INFO: $REAL_PWD IS NOT in src/*" ;;
esac

echo INFO: Docker image is = $IMAGE_NAME
# Create output directory if not exists
mkdir -p output

# what works is
#  docker run --rm -it -v "$(pwd):/tmp",userns=host --user $(id -u):$(id -g) mambaorg/micromamba:1.5.8 /bin/bash
docker run \
$PARAMETERS \
$USER_MAPPING \
$MOUNT_BEFORE_PWD \
#  --mount type=bind,source=$REAL_PWD,target=/usr/app/data,readonly \
 -v "$REAL_PWD":/usr/app/data:ro \
# --mount type=bind,source=$REAL_PWD/output,target=/usr/app/data/output$MOUNT_SUFFIX \
 -v "$REAL_PWD"/output:/usr/app/data/output$MOUNT_SUFFIX \
$MOUNT_AFTER_PWD \
$FIX_OVERLAP_MOUNT \
$NETWORK \
 --security-opt seccomp=${SCRIPT_DIR}/seccomp-default.json \
 --security-opt=no-new-privileges \
 --read-only --tmpfs /tmp \
 --cap-drop all \
 --rm \
 $IMAGE_NAME $COMMAND "$@"
#!/usr/bin/env bash
# Shell script for starting Docker container
# TBD:  - Check other useful Docker CLI options
# 

SOURCE_MOUNT=""
NETWORK="--net=none"
PARAMETERS=""
IMAGE_NAME="test_app"
COMMAND="python ./main.py"
# Change to COMMAND="python -u ./main.py" if you want print() statements 
# to be visible on stdout (default: logging only)

usage ()
{
    printf "Starts the ${IMAGE_NAME} application inside a Docker container\n"
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
UID_HOST=$(id -u)
GID_HOST=$(id -g)
echo "INFO: Local User has UID = $UID_HOST, GID = $GID_HOST"
if [[ $UID_HOST -lt 1000 ]]; then
    echo "WARNING: User ID is < 1000, not passed to container user"
    USER_MAPPING=""
else
    USER_MAPPING="--user $UID_HOST:$GID_HOST"
fi
while getopts ":dDin" opt; do
  case ${opt} in
    d)
      if [ -n "$DEV" ]; then
      echo "ERROR: Incompatible options -d and -D. Aborting."
      exit 1
      else
      DEV=TRUE
      echo "Development mode enabled (running code from local file)"
      echo "Using image ${IMAGE_NAME}_dev"
      SOURCE_MOUNT="--mount type=bind,source=$SCRIPT_DIR/src,target=/usr/app/src,readonly"
      IMAGE_NAME="${IMAGE_NAME}_dev"
      fi
      ;;
    D)
      if [ -n "$DEV" ]; then
      echo "ERROR: Incompatible options -d and -D. Aborting."
      exit 1
      else
      DEV=TRUE    
      echo "EXPERT development mode enabled (running code from local file)"
      echo "Write access granted to $SCRIPT_DIR/src"
      read -n1 -p "Do you REALLY want to continue (Y/N)?" reply
      echo ""
      [ "$reply" != "Y" ] && [ "$reply" != "y" ] && echo "Aborting." && exit 1
      echo "Using image ${IMAGE_NAME}_dev"
      SOURCE_MOUNT="--mount type=bind,source=$SCRIPT_DIR/src,target=/usr/app/src"
      IMAGE_NAME="${IMAGE_NAME}_dev"
      fi
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
    echo DEBUG: Blocking overlap via $FIX_OVERLAP_MOUNT
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
    echo DEBUG: Blocking overlap via $FIX_OVERLAP_MOUNT
    ;;
    *) echo "INFO: $REAL_PWD IS NOT in src/*" ;;
esac

# Create output directory if not exists
mkdir -p output
# $USER_MAPPING \ removed for the moment bc we change the user at build time

docker run \
$PARAMETERS \
$MOUNT_BEFORE_PWD \
 --mount type=bind,source=$REAL_PWD,target=/usr/app/data,readonly \
 --mount type=bind,source=$REAL_PWD/output,target=/usr/app/data/output \
$MOUNT_AFTER_PWD \
$FIX_OVERLAP_MOUNT \
$NETWORK \
 --security-opt seccomp=${SCRIPT_DIR}/seccomp-default.json \
 --security-opt=no-new-privileges \
 --read-only --tmpfs /tmp \
 --cap-drop all \
 --rm \
 $IMAGE_NAME $COMMAND "$@"

#!/usr/bin/env bash
# Shell script for building the Docker images for all default
# environments.
set -euo pipefail

ENVS=(mini dataviz openai)
USERNAME=$USER
NOTEBOOK_ID="notebook"

usage ()
{
    printf 'Builds the Docker images for all default environments:\n\n'
    for env in "${ENVS[@]}"; do
        printf "- $env\n"
    done     
}

if [[ "${1:-}" == "--help" ]]; then
    usage
    exit 0
fi

echo 'WARNING: This will also overwrite your local Docker images!'
echo "Available notebook images / environments:"
echo "-------------------------"
docker images $USER/$NOTEBOOK_ID   
echo 
read -n1 -p "Do you REALLY want to continue (Y/N)?" reply
echo ""
[ "$reply" != "Y" ] && [ "$reply" != "y" ] && echo "Aborting." && exit 1
for env in "${ENVS[@]}"; do
  echo "Running build for: $env"
  ./build.sh -fn "$env"
done

printf '\nCompleted.\n'
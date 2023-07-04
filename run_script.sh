# Shell script for starting Docker container
# TBD:  - Check other useful Docker CLI options
docker run \
 --mount type=bind,source="$(pwd)",target=/usr/app/src/data \
 --net none \
 --rm \
 test_app "$@"

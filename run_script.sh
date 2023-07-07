# Shell script for starting Docker container
# TBD:  - Check other useful Docker CLI options
# 
# Create output directory if not exists
mkdir -p output
docker run \
 --mount type=bind,source="$(pwd)",target=/usr/app/src/data \
 --mount type=bind,source="$(pwd)/output",target=/usr/app/src/output,readonly \
 --net none \
 --rm \
 test_app "$@"
#  
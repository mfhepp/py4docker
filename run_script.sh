# Shell script for starting Docker container
# TBD
# 1. Allow access to working directory.
# 2. Block network access except for during the build process.
# 3. Check other useful Docker CLI options
echo "$(pwd)"
docker run \
 --mount type=bind,source="$(pwd)",target=/usr/app/src/data \
 test_app "$@"

# Read-only volumes:
#   --mount type=bind,source="$(pwd)"/target,target=/app,readonly \
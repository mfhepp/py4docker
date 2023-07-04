# py4docker
Basic structure for running Python 3.x shell scripts in a Docker container.

Based on [`micromamba-docker`](https://github.com/mamba-org/micromamba-docker) and [Uwe Korn's tips for smaller image sizes](https://uwekorn.com/2021/03/01/deploying-conda-environments-in-docker-how-to-do-it-right.html).

## Features

- Code inside the Docker container runs as a non-root user, [thanks to the `micromamba-docker` base](https://github.com/mamba-org/micromamba-docker/blob/main/FAQ.md#how-do-i-install-software-using-aptapt-getapk).
- Network access can be blocked, which reduces the risk if a hidden transfer of data and commands by malicious code.
- File-access is limited to the current working directory and can be disabled entirely.
- Small footprint (<300 MB)

## Usage

## Configuration and Settings


### Access to the Local File System

The current working directory will be available as `/usr/app/src/data` from within the container. If you want to make this read-only, change the line

` --mount type=bind,source="$(pwd)",target=/usr/app/src/data \`

in `run_script.sh` to

` --mount type=bind,source="$(pwd)",target=/usr/app/src/data,readonly \`

You can also mount additional local paths using the same syntax.

### Access to the Internet

By default, the script inside the container has no Internet access, which makes it more challenging for malicious code to transmit stolen content etc. 

You can grant Internet access by removing the line

`--net none \`

from `run_script.sh`.


### Build

`docker build --quiet --tag test_app .`

### Run

The skeletton includes a small shell script that mounts the current working directory for read- and write access.

This should be expanded to limit the access privileges even further, e.g.

- block outbound Internet access during the execution
- grant read-only access to current directory

#### Via the `run_script.sh`:

`./run_script.sh <parameter_1>``

#### Directly from Docker

`docker run test_app`

`docker run --rm test_app`

## Todo

- Improve Docker runtime options and parameters.
- Block internet access at run-time.
- Change user to non-root.
- Block access to Docker daemon (if possible).

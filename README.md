# py4docker
Basic structure for running Python 3.x shell scripts in a Docker container.

Based on [`micromamba-docker`](https://github.com/mamba-org/micromamba-docker) and [Uwe Korn's tips for smaller image sizes](https://uwekorn.com/2021/03/01/deploying-conda-environments-in-docker-how-to-do-it-right.html).

## Features

- Code inside the Docker container runs as a **non-root user,** [thanks to the `micromamba-docker` base](https://github.com/mamba-org/micromamba-docker/blob/main/FAQ.md#how-do-i-install-software-using-aptapt-getapk) image.
- **Network access can be blocked,** which reduces the risk of a hidden transfer of data and commands by malicious code (e.g. from compromised PyPi modules).
- **File-access is limited to the current working directory** and can be disabled entirely.
- **Small footprint** (<300 MB)

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

You can build the image with

`docker build --quiet --tag test_app .`

### Run

The skeletton includes a small shell script `run_script.sh` that mounts the current working directory for read- and write access and blocks Internet access etc.

This should be expanded to limit the access privileges even further, e.g. to grant read-only access to current directory.

`./run_script.sh <parameter_1>`

`<parameter_1>` is just a dummy parameter that the dummy `main.py` expects. Adjust as needed.

## Todo

- Improve Docker runtime options and parameters.
- Block access to Docker daemon (if possible).

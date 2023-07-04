# py4docker
Basic structure for running Python 3.x shell scripts in a Docker container.

Based on [`micromamba-docker`](https://github.com/mamba-org/micromamba-docker) and [Uwe Korn's tips for smaller image sizes](https://uwekorn.com/2021/03/01/deploying-conda-environments-in-docker-how-to-do-it-right.html).

## Usage

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

`docker run -it --rm test_app`

## Todo

- Improve Docker runtime options and parameters.
- Block internet access at run-time.
- Change user to non-root.
- Block access to Docker daemon (if possible).

# py4docker
Basic structure for running Python 3.x shell scripts in a Docker container, with several techniques for sandboxing the execution from the host system.

Based on [`micromamba-docker`](https://github.com/mamba-org/micromamba-docker) and [Uwe Korn's tips for smaller image sizes](https://uwekorn.com/2021/03/01/deploying-conda-environments-in-docker-how-to-do-it-right.html).

## Features

- Code inside the Docker container runs as a **non-root user,** [thanks to the `micromamba-docker` base](https://github.com/mamba-org/micromamba-docker/blob/main/FAQ.md#how-do-i-install-software-using-aptapt-getapk) image.
- **Outbound and inbound network access is blocked by default,** which reduces the risk of exfiltration of local data or code, or loading malware components or instructions (e.g. caused by compromised PyPi packages).
- **File-access is limited to the current working directory** and can be disabled entirely.
    - The actual working directory is mounted as **read-only**.
    - A subdirectory `output` is created if it does not exist and mounted for write-access.
- **Small footprint** (ca. 300 MB)
- Several techniques for limiting access rights (inspired by the [OWASP Docker Security Cheatsheet](https://cheatsheetseries.owasp.org/cheatsheets/Docker_Security_Cheat_Sheet.html)):
    - Seccomp profile
    - Read-only file-system but with `tmpfs` so that temporary files can be created.
    - Removed [Linux Kernel capabilities](https://man7.org/linux/man-pages/man7/capabilities.7.html)
    - Adding new kernel capabilities is blocked
- **Development mode,** in which the local version of the Python code can be run inside the container 

## Installation

The code is meant as a skeleton for your own work. Please **do not fork this repository** if you are creating your **own project.** A fork is appreciated for pull-requests related to this template.

1. Clone the repository onto your machine: 
    - `git clone https://github.com/mfhepp/py4docker.git`
2. Delete the folder `.git`; set up your own Git project, if needed.
3. Make sure Docker is installed and the Docker daemon or Docker Desktop is running on your machine,
4. Build a Docker image on your machine:

```bash
./build.sh
```
It should end like so:

```bash
#11 exporting to image
#11 exporting layers
#11 exporting layers 0.8s done
#11 writing image sha256:... done
#11 naming to docker.io/library/test_app done
#11 DONE 0.8s
```
6. Run the script from within a container with a random name as a single parameter, like `FooBar``:

```bash
# Run script
./run_script.sh FooBar
```

The script should run and report its progress, like so

```bash
2023-12-01 23:03:58,436 INFO     [main.py:28] Script started.
2023-12-01 23:03:58,436 INFO     [main.py:29] Hello, !
2023-12-01 23:03:58,436 INFO     [main.py:42] Test for read-access to /usr/app/src
2023-12-01 23:03:58,437 INFO     [main.py:44] OK: Read access to /usr/app/src, found 1 entries
2023-12-01 23:03:58,437 INFO     [main.py:45] Found 1 items in /usr/app/src
2023-12-01 23:03:58,437 INFO     [main.py:47] 	main.py
2023-12-01 23:03:58,437 INFO     [main.py:48] Test for write-access to /usr/app/src
2023-12-01 23:03:58,437 INFO     [main.py:54] OK: Write access to /usr/app/src is blocked [[Errno 30] Read-only file system: '/usr/app/src/test.txt']
2023-12-01 23:03:58,437 INFO     [main.py:42] Test for read-access to /usr/app/data
...
2023-12-01 23:03:58,440 INFO     [main.py:55] Testing outbound Internet access
2023-12-01 23:03:58,442 INFO     [main.py:64] OK: Network access is blocked [HTTPSConnectionPool(host='www.apple.com', port=443): Max retries exceeded with url: / (Caused by NameResolutionError("<urllib3.connection.HTTPSConnection object at 0xffff8bfec830>: Failed to resolve 'www.apple.com' ([Errno -3] Temporary failure in name resolution)"))]
2023-12-01 23:03:58,442 INFO     [main.py:65] Testing if user running the script has root access
2023-12-01 23:03:58,442 INFO     [main.py:73] OK: Python script seems to have no root privileges. [[Errno 13] Permission denied: '/root/']
2023-12-01 23:03:58,442 INFO     [main.py:74] Done.
```

## Configuration and Settings

Now, you can start working on your own code.

1. In `build.sh` and `run_script.sh`, change the string `test_app` to a name for your application (e.g. `my_crawler`), like so
```bash
IMAGE_NAME="my_crawler"
```
2. Edit the list of Python packages in `env.yaml`
3. You may want to change the name of the starter script `run_script.sh` to the name of your project (like `my_crawler.sh`).

## Folder Structure inside the Container

Your Python script will see the following directory structure

- `/usr/app/src`: This is the source code and startup directory.
In the regular mode, this is the `src` folder inside the Docker container, created from the image.
It will not be updated until you re-build the image.
In **development mode** (see below for details), this is the `src` **in the directory that contains the `run_script.sh` script.** Symbolic links will be resolved.
- `/usr/app/data`: This is the host's current working directory, i.e. from where you start the `run_script.sh` script.
- `/usr/app/data/output`: This is a writeable directory for results, mapped to the `output` folder relative to the host's current working directory

**Important:** The mapping of **directories from your local machine to these paths** inside the container **depends on from where you start the `run_script.sh` script.** The rationale is that the code can only see the data from the current (working) directory and only write to a dedicated `output` subdirectory therein. A malicious script can hence not modify or delete files in your working directory. But if you start the script from your user root directory `~/`, then the script can read all files from all subdirectories.

In the development mode, the inner workings are a bit more complicated. Please the comments in the `run_script.sh` file for details.

## Building Your Docker Image with `build.sh`

Before you can run your own code, you need to build a Docker image with `build.sh`:

```bash
Usage: ./build.sh [OPTIONS] 

Option(s):
  -d: development mode (create test_app_dev)
  -f: force fresh build, ignoring caches (will update Python packages)
```

### Development Image

Go to your project directory and execute:

```bash
./build.sh -d
```
This builds a development image, named `test_app_dev` (or whatever you chose for `test_app`; the suffix is added automatically).

### Image for Production

When done, you can build a production image with

```bash
./build.sh
```

This builds an image for production, named `test_app` (or whatever you chose).

The motivation for two images is that you will keep an image of your last working version available while you are developing (e.g. on feature branches).

### Updating an Image

Due to Docker caching mechanisms, **new versions of Python packages or security updates to the Debian system will only be installed** if you tell Docker to ignore the cached previous stages when building the image (or if you change `env.yaml``). 

This can be done with the `-f` (for _force_) option:

```bash
# Development image
./build.sh -d -f
```

```bash
# Production image
./build.sh -f
```

Note that this may change the installed versions of Python packages. There is currently no mechanism for pinning the installed versions.

## Running the Script with `run_script.sh`

This script starts your code in `main.py` inside a Docker container.

```bash
Usage: ./run_script.sh [OPTIONS] [APP_ARGS]

Options:
  -d: (D)evelopment mode (mount local volume, as read-only)
  -i: (i)nteractive mode (keep terminal open and start with bash)
  -n: Allow outbound (N)etwork access to host network
  --help: Show help
```

All other arguments and options will be passed to your `main.py` application.

It supports two modes:

### Development Mode

In this mode, **the local version of your `src` folder** is mounted within the Docker container. 

In other words, **if you change your code, the new code will be executed** via `run_script.sh`.

```bash
./run_script.sh -d
```

Try to avoid using this mode from within the `src` directory.

### Production Mode

In this mode, **your `src` folder contains what has been copied** to the Docker image **at build time** and remains unchanged and read-only.

```bash
./run_script.sh
```

### Interactive Mode

In both of the main modes, you can tell `run_script.sh` to provide an interactive terminal session to the respective container instead of running the `main.py` script.

```bash
# Development Mode
./run_script.sh -d -i 
# Production Mode
./run_script.sh -i
```

You can execute any Linux commands in there, e.g.

```bash
ls
```

In order to run your script, just type

`python ./main.py`

Note that you can only write to the `output` folder, while the rest of the system is read-only:

```bash
# This will work
cd /usr/app/data/output
echo This is a test > test.txt
# This won't
cd /usr/app/data
echo This is a test > test.txt
```

### Allowing Network Access

You can grant your script access to the host`s network with

```bash
# Development Mode
./run_script.sh -d -n 
# Production Mode
./run_script.sh -n
```

While this is necessary for many types of applications (like Web crawlers), it introduces a much larger risk for malicious code, in particular the transmission of secrets stolen from your machine or other data to a remote server.

## Logging

You will only see output from the pre-configured logger, not from `print()` statements.

For outputs, add statements like

```python
logging.info("That is what I have to say.")
```
as needed.

### Logging to Logfile and Console

If you want to log the output of the container (`stdout` and `stderr`) to both a file and the console, use

```bash
./run_script.sh [OPTIONS] [APP_ARGS] 2>&1 | tee -a logfile.log
```

### Logging to Logfile Only

If you just want to redirect it to the logfile, use

```bash
./run_script.sh [OPTIONS] [APP_ARGS] >> logfile.log 2>&1
```

## Deploying or Publishing Your Application

### Custom `run_script.sh`

It is recommended that you create a simplified version of the `run_script.sh` script for deployment with all of the options hard-wired for security reasons.

### Creating an Alias

If you want to be able to run the script just by a single command, like `my_script FooBar`, then add the following lines to your `.bash_profile` file:

```bash
alias my_script="bash run_script.sh"
```

It is **strongly recommended to use an absolute path in the alias** (otherwise, one random of multiple copies of `run_script.sh` with different functionality might be executed depending on your $PATH).

**Warning:** An alias will allow you to run the script from any folder on your system, and that folder will be available for read-access to the script as `/usr/app/data`.

## Advanced Topics

### Access to the Local File System

The current working directory will be available as `/usr/app/data` from within the container. By default, it is read-only. If you want to make this writeable, change the line

`--mount type=bind,source=$REAL_PWD,target=/usr/app/data,readonly \`

in `run_script.sh` to

`--mount type=bind,source=$REAL_PWD,target=/usr/app/data \`

You can also mount additional local paths using the same syntax.

### Write-Access to the Source Code in Development Mode

If you want to grant your code **write-access** to the `src` folder in **development mode** permanently, you can use the option `-D`, like so:


```bash
./run_script.sh -D
```
A common use-case is running code-formatters on the source-code. The [Black Code Formatter](https://black.readthedocs.io/en/stable/) is included in the default `conda/mamba` environment. So you can use `black` in the interactive development mode with write-access, like so:

```bash
./run_script.sh -D -i
$ black main.py
All done! ✨ 🍰 ✨
1 file left unchanged.
```
**Be warned: Make sure you understand the security implications!**

### User ID Mismatch Problems

On Linux machines, you may run into problems accessing the files in the `output` folder, because the user ID inside the container differs from your user ID on the host system. For details, see e.g. <https://www.joyfulbikeshedding.com/blog/2021-03-15-docker-and-the-host-filesystem-owner-matching-problem.html>. 

This should not be a problem on Apple OSX systems running ***Docker Desktop***, because the mechanism for accessing files on the host system is taking care of this issue.

### Access to the Internet

By default, the script inside the container has no Internet access, which makes it more challenging for malicious code to transmit harvested information etc. 

Besides using the `-n` option with `run_script.py`, you can grant Internet access as a default by removing the line

`--net none \`

from `run_script.sh`.

More advanced settings are possible, e.g. adding a proxy or firewall inside the container that permits access only to a known set of IP addresses or domains and / or logs the outbound traffic.

## Limitations and Ideas for Improvement

- The code is currently maintained for Docker Desktop on Apple Silicon only. It may work on other platforms, but I have no time for testing at the moment. In particular, there may be issues with user ID / file permissions on Linux systems if the script writes to the `output` folder.
- Expand support for blocking and logging Internet access e.g. by domain or IP ranges is a priority at my side, but non-trivial.

## LICENSE

- tbd. Not yet decided; please ask!
- The [Docker default seccomp profile file](https://github.com/moby/moby/blob/master/profiles/seccomp/default.json) is being used under an [Apache 2.0 License](https://github.com/moby/moby/blob/master/LICENSE).

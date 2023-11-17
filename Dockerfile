FROM mambaorg/micromamba:1.5.3 as micromamba-unpatched
# Install security updates if base image is not yet patched
# Inspired by https://pythonspeed.com/articles/security-updates-in-docker/
USER root
RUN apt-get update && apt-get -y upgrade
# ENTRYPOINT ["/usr/local/bin/_entrypoint.sh"]
# cat /etc/apt/sources.list
# WORKDIR /etc/apt/
USER mambauser

FROM micromamba-unpatched
USER mambauser
COPY --chown=$MAMBA_USER:$MAMBA_USER env.yaml /tmp/env.yaml
# Install packages
RUN micromamba install -y -n base -f /tmp/env.yaml && \
    micromamba clean --all --yes
WORKDIR /usr/app/src
COPY main.py ./
ARG MAMBA_DOCKERFILE_ACTIVATE=1  # (otherwise python will not be found)
# -u would be needed if print statements should be visible during programm execution
# But in general mixing logging and print is no good idea anyway.
# ENTRYPOINT ["/usr/local/bin/_entrypoint.sh", "python", "-u", "./main.py"]
ENTRYPOINT ["/usr/local/bin/_entrypoint.sh", "python", "./main.py"]

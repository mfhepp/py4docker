ARG MICROMAMBA_VERSION="1.5.6"
ARG ENVIRONMENT_FILE="env.yaml"
ARG NOTEBOOK_MODE
# Stage 1
FROM mambaorg/micromamba:${MICROMAMBA_VERSION} as micromamba-patched
ARG MICROMAMBA_VERSION
ARG ENVIRONMENT_FILE
ARG NOTEBOOK_MODE
# Install security updates if base image is not yet patched
# Inspired by https://pythonspeed.com/articles/security-updates-in-docker/
USER root
RUN apt-get update && apt-get -y upgrade
# ENTRYPOINT ["/usr/local/bin/_entrypoint.sh"]
# cat /etc/apt/sources.list
# WORKDIR /etc/apt/
USER $MAMBA_USER

# Stage 2
FROM micromamba-patched
ARG ENVIRONMENT_FILE
ARG NOTEBOOK_MODE
USER $MAMBA_USER
# ENV ENVIRONMENT_FILE=${ENVIRONMENT_FILE}
ENV NOTEBOOK_MODE=${NOTEBOOK_MODE}
COPY --chown=$MAMBA_USER:$MAMBA_USER ${ENVIRONMENT_FILE} /tmp/env.yaml
# Install packages
# The name of the environment will always be "base", irrespective of the YAML file
# This is due to the way micromamba-docker works
RUN micromamba install -y -n base -f /tmp/env.yaml && \
    micromamba clean --all --yes
# Install Kernels for Jupyter Notebook etc.
# TODO: Add
RUN echo Notebook mode is "$NOTEBOOK_MODE"
RUN if [[ -n "$NOTEBOOK_MODE" ]] ; then echo DEBUG Notebook mode ; fi
WORKDIR /usr/app/src
COPY --chown=$MAMBA_USER:$MAMBA_USER src/ ./
ARG MAMBA_DOCKERFILE_ACTIVATE=1
ENTRYPOINT ["/usr/local/bin/_entrypoint.sh"]
# For debugging, use this one
# ENTRYPOINT ["/usr/local/bin/_entrypoint.sh", "/bin/sh"]
# In a final application, you may want to hard-wire the entrypoint to the script:
# ENTRYPOINT ["/usr/local/bin/_entrypoint.sh", "python", "./main.py"]

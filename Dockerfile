FROM mambaorg/micromamba:1.5.6 as micromamba-patched
# Install security updates if base image is not yet patched
# Inspired by https://pythonspeed.com/articles/security-updates-in-docker/
USER root
RUN apt-get update && apt-get -y upgrade
# ENTRYPOINT ["/usr/local/bin/_entrypoint.sh"]
# cat /etc/apt/sources.list
# WORKDIR /etc/apt/
USER mambauser

FROM micromamba-patched
USER mambauser
COPY --chown=$MAMBA_USER:$MAMBA_USER env.yaml /tmp/env.yaml
# Install packages
RUN micromamba install -y -n base -f /tmp/env.yaml && \
    micromamba clean --all --yes
WORKDIR /usr/app/src
COPY --chown=$MAMBA_USER:$MAMBA_USER src/ ./
ARG MAMBA_DOCKERFILE_ACTIVATE=1
ENTRYPOINT ["/usr/local/bin/_entrypoint.sh"]
# For debugging, use this one
# ENTRYPOINT ["/usr/local/bin/_entrypoint.sh", "/bin/sh"]
# In a final application, you may want to hard-wire the entrypoint to the script:
# ENTRYPOINT ["/usr/local/bin/_entrypoint.sh", "python", "./main.py"]

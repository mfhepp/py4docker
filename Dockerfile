FROM mambaorg/micromamba:1.5.1 as micromamba-unpatched
# Install security updates if base image is not yet patched
# Inspired by https://pythonspeed.com/articles/security-updates-in-docker/
USER root
RUN apt-get update && apt-get -y upgrade
ENTRYPOINT ["/usr/local/bin/_entrypoint.sh"]
# cat /etc/apt/sources.list
WORKDIR /etc/apt/


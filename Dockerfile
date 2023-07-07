FROM mambaorg/micromamba:1.4.6
COPY --chown=$MAMBA_USER:$MAMBA_USER env.yaml /tmp/env.yaml
RUN micromamba install -y -n base -f /tmp/env.yaml && \
    micromamba clean --all --yes
WORKDIR /usr/app/src
COPY main.py ./
ARG MAMBA_DOCKERFILE_ACTIVATE=1  # (otherwise python will not be found)
# -u would be needed if print statements should be visible during programm execution
# But in general mixing logging and print is no good idea anyway.
# ENTRYPOINT ["/usr/local/bin/_entrypoint.sh", "python", "-u", "./main.py"]
ENTRYPOINT ["/usr/local/bin/_entrypoint.sh", "python", "./main.py"]

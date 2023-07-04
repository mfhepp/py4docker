FROM mambaorg/micromamba:1.4.6
COPY --chown=$MAMBA_USER:$MAMBA_USER env.yaml /tmp/env.yaml
RUN micromamba install -y -n base -f /tmp/env.yaml && \
    micromamba clean --all --yes
WORKDIR /usr/app/src
COPY main.py ./
ARG MAMBA_DOCKERFILE_ACTIVATE=1  # (otherwise python will not be found)
ENTRYPOINT ["/usr/local/bin/_entrypoint.sh", "python", "./main.py"]

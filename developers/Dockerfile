# syntax=docker/dockerfile:1.2
FROM python:3.12-bookworm

# Install Python packages, using the host cache
COPY requirements.txt /tmp/requirements.txt
RUN --mount=type=cache,target=/root/.cache \
    python -m pip install --no-deps --requirement /tmp/requirements.txt

# Without this, the Jupyter terminal defaults to /bin/sh which is much less
# usable
ENV SHELL=/bin/bash

# Jupyter writes various runtime files to $HOME so we need that to be writeable
# regardless of which user we run as
ENV HOME=/tmp

# Allow Jupyter to be configured from within the workspace
ENV JUPYTER_CONFIG_DIR=/workspace/jupyter-config

# This variable is only needed for the `ebmdatalab` package:
# https://pypi.org/project/ebmdatalab/
ENV EBMDATALAB_BQ_CREDENTIALS_PATH=/workspace/bq-service-account.json

RUN mkdir /workspace
WORKDIR /workspace

# This is a proper hack! The copied code gets credentials from
# Codespace secrets OR the `bq-service-account.json` file.
# TODO: #2 Need to remove when PyPI updated
COPY bq-env.py /usr/local/lib/python3.12/site-packages/ebmdatalab/bq.py

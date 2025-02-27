# Use the official VS Code Remote Development container image
FROM mcr.microsoft.com/vscode/devcontainers/base:focal

ENV DEBIAN_FRONTEND noninteractive

# Install required packages for Terraform and pre-commit
RUN apt-get update \
    && apt-get -y install --no-install-recommends \
    curl \
    git \
    unzip \
    python3-pip \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

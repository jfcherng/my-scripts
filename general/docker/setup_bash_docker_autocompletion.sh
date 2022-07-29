#!/usr/bin/env bash

# @see https://rohancragg.co.uk/misc/git-bash/

mkdir -p ~/bash_completion.d

# Docker CLI
curl -o \
    ~/bash_completion.d/docker \
    "https://raw.githubusercontent.com/docker/cli/master/contrib/completion/bash/docker"
echo "source ~/bash_completion.d/docker" >>~/.bashrc

# Docker Machine
curl -o \
    ~/bash_completion.d/docker-machine \
    "https://raw.githubusercontent.com/docker/machine/master/contrib/completion/bash/docker-machine.bash"
echo "source ~/bash_completion.d/docker-machine" >>~/.bashrc

# Docker Compose
curl -o \
    ~/bash_completion.d/docker-compose \
    "https://raw.githubusercontent.com/docker/compose/master/contrib/completion/bash/docker-compose"
echo "source ~/bash_completion.d/docker-compose" >>~/.bashrc

# Kubernetes
kubectl completion bash >~/bash_completion.d/kubectl
echo "source ~/bash_completion.d/kubectl" >>~/.bashrc

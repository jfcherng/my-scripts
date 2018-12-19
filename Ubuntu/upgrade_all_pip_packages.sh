#!/usr/bin/env bash

[[ "${UID}" == "0" ]] || { echo "run as sudo to execute"; exit 1; }

pip3 freeze --local | command grep -v '^\-e' | cut -d = -f 1 | xargs -n1 pip3 install -U

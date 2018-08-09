#!/usr/bin/env bash

ST_data_dir=~/.config/sublime-text-3

pushd "${ST_data_dir}" || exit

git fetch --all -p && git reset --hard "@{upstream}"

popd || exit

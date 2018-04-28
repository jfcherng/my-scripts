#!/usr/bin/env bash

ST_data_dir=~/.config/sublime-text-3

cd "$ST_data_dir" || exit
git fetch && git reset --hard origin/"$(git rev-parse --abbrev-ref HEAD)"
git remote update origin --prune
git gc --prune=now
cd -

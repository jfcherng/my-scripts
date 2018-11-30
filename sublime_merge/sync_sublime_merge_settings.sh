#!/usr/bin/env bash

SM_DATA_DIR=~/.config/sublime-merge

pushd "${SM_DATA_DIR}" || exit

if [ ! -d .git ]; then
    git init
    git remote add origin git@github.com:jfcherng/my-Sublime-Merge-settings.git
    git pull origin master
    git branch -u origin/master
fi

git fetch --tags --force --prune --all
git reset --hard @{upstream}

popd || exit

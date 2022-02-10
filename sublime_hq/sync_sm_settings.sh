#!/usr/bin/env bash

SETTINGS_REPO="git@github.com:jfcherng/my-Sublime-Merge-settings.git"
BRANCH_DEFAULT="master"

SM_DATA_DIRS=(
    # Windows
    "${APPDATA}/Sublime Merge"
    # Linux
    "${HOME}/.config/sublime-merge"
    # Mac
    "${HOME}/Library/Application Support/Sublime Merge"
)

for data_dir in "${SM_DATA_DIRS[@]}"; do
    if [ ! -d "${data_dir}" ]; then
        continue
    fi

    echo "* Targeted Data directory: ${data_dir}"

    pushd "${data_dir}" || exit

    if [ ! -d .git ]; then
        git init
        git remote add origin "${SETTINGS_REPO}"
        git pull origin "${BRANCH_DEFAULT}"
        git branch -u "origin/${BRANCH_DEFAULT}"
    fi

    git fetch --tags --force --prune --all
    git reset --hard "@{upstream}"
    git submodule update --init --recursive --force

    popd || exit

    break
done

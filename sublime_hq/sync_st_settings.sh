#!/usr/bin/env bash

SETTINGS_REPO="git@github.com:jfcherng/my-Sublime-Text-settings.git"
BRANCH_DEFAULT="master"

ST_DATA_DIRS=(
    # Windows
    "${APPDATA}/Sublime Text"
    "${APPDATA}/Sublime Text 3"
    # Linux
    "${HOME}/.config/sublime-text"
    "${HOME}/.config/sublime-text-3"
    # Mac
    "${HOME}/Library/Application Support/Sublime Text"
    "${HOME}/Library/Application Support/Sublime Text 3"
)

for data_dir in "${ST_DATA_DIRS[@]}"; do
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

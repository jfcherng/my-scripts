#!/usr/bin/env bash

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

    echo "* Targeting Data directory: ${data_dir}"

    pushd "${data_dir}" || exit

    if [ ! -d .git ]; then
        git init
        git remote add origin git@github.com:jfcherng/my-Sublime-Text-settings.git
        git pull origin master
        git branch -u origin/master
    fi

    git fetch --tags --force --prune --all
    git reset --hard "@{upstream}"
    git submodule update --init --recursive --force

    popd || exit

    break
done

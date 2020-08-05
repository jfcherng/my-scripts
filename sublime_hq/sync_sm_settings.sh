#!/usr/bin/env bash

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

    echo "* Targeting Data directory: ${data_dir}"

    pushd "${data_dir}" || exit

    if [ ! -d .git ]; then
        git init
        git remote add origin git@github.com:jfcherng/my-Sublime-Merge-settings.git
        git pull origin master
        git branch -u origin/master
    fi

    git fetch --tags --force --prune --all
    git reset --hard "@{upstream}"
    git submodule update --init --recursive --force

    popd || exit

    break
done

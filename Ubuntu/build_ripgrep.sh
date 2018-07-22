#!/usr/bin/env bash

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

pushd "${SCRIPT_DIR}" || exit

sudo apt install -y cargo

if [ ! -d "ripgrep/.git" ]; then
    rm -rf "ripgrep"
    git clone "https://github.com/BurntSushi/ripgrep"
fi

pushd ripgrep || exit

git fetch --all -p && git checkout origin/master && git reset --hard "@{upstream}"

cargo build --release
./target/release/rg --version

sudo cp -r target/release/rg /usr/local/bin

rm -rf target
git checkout -

popd || exit

popd || exit

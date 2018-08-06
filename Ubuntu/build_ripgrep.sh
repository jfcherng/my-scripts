#!/usr/bin/env bash

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

pushd "${SCRIPT_DIR}" || exit

sudo apt install -y cargo

if [ ! -d "ripgrep/.git" ]; then
    rm -rf "ripgrep"
    git clone --recursive "https://github.com/BurntSushi/ripgrep"
fi

pushd ripgrep || exit

# sync repo
git fetch --all -p && git checkout origin/master && git reset --hard "@{upstream}"
git submodule init
git submodule update --recursive --remote

# build
cargo build --release
./target/release/rg --version

# install
sudo cp -r target/release/rg /usr/local/bin

# cleanup
rm -rf target
git checkout -
git checkout -- .
git clean -dfx

popd || exit

popd || exit

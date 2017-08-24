#!/usr/bin/env bash

sudo apt install cargo

git clone https://github.com/BurntSushi/ripgrep
cd ripgrep || exit
git pull
cargo build --release
./target/release/rg --version

sudo cp -r ./target/release/rg /usr/local/bin

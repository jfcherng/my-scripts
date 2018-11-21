#!/usr/bin/env bash

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
THREAD_CNT=$(getconf _NPROCESSORS_ONLN)

pushd "${SCRIPT_DIR}" || exit

if [ ! -d "ctags/.git" ]; then
    rm -rf "ctags"
    git clone --recursive "https://github.com/universal-ctags/ctags.git"
fi

pushd ctags || exit

# sync repo
git fetch --tags --force --all -p && git checkout origin/master && git reset --hard "@{upstream}"
git submodule update --init
git submodule update --recursive --remote

# build
./autogen.sh
./configure --prefix=/usr/local
make -j "${THREAD_CNT}"
sudo make install

# cleanup
make clean
git checkout -
git checkout -- .
git clean -dfx

popd || exit

popd || exit

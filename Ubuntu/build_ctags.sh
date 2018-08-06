#!/usr/bin/env bash

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
THREAD_CNT=$(nproc --all)

pushd "${SCRIPT_DIR}" || exit

if [ ! -d "ctags/.git" ]; then
    rm -rf "ctags"
    git clone --recursive "https://github.com/universal-ctags/ctags.git"
fi

pushd ctags || exit

# sync repo
git fetch --all -p && git checkout origin/master && git reset --hard "@{upstream}"
git submodule init
git submodule update --recursive --remote

# build
./autogen.sh
./configure --prefix=/usr/local
make -j "${THREAD_CNT}"
sudo make install

# cleanup
make clean
git clean -dfx
git checkout -- .

popd || exit

popd || exit

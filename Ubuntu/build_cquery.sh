#!/usr/bin/env bash

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

pushd "${SCRIPT_DIR}" || exit

if [ ! -d "cquery/.git" ]; then
    rm -rf "cquery"
    git clone --recursive "https://github.com/cquery-project/cquery.git"
fi

pushd cquery || exit

# sycn repo
git fetch --all -p && git checkout origin/master && git reset --hard "@{upstream}"
git submodule update --init
git submodule update --recursive --remote

rm -rf build/CMakeFiles/ build/third_party/
mkdir -p build/

# build
pushd build || exit
cmake .. -DCMAKE_BUILD_TYPE=release -DCMAKE_INSTALL_PREFIX=release -DCMAKE_EXPORT_COMPILE_COMMANDS=YES
cmake --build . --target install
popd || exit

# cleanup
make clean
git checkout -
git checkout -- .

popd || exit

popd || exit

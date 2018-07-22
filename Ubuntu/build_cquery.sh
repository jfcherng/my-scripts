#!/usr/bin/env bash

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

pushd "${SCRIPT_DIR}" || exit

if [ ! -d "cquery/.git" ]; then
    rm -rf "cquery"
    git clone "https://github.com/cquery-project/cquery.git" --recursive
fi

pushd cquery || exit

git fetch --all -p && git checkout origin/master && git reset --hard "@{upstream}"
git submodule init
git submodule update --recursive --remote

rm -rf build/CMakeFiles/ build/third_party/
mkdir -p build/

pushd build || exit

cmake .. -DCMAKE_BUILD_TYPE=release -DCMAKE_INSTALL_PREFIX=release -DCMAKE_EXPORT_COMPILE_COMMANDS=YES
cmake --build . --target install

popd || exit

git checkout -

popd || exit

popd || exit

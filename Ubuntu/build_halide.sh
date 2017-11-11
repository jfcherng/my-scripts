#!/usr/bin/env bash

THREAD_CNT=$(nproc --all)

dir_base=/home/jfcherng/Desktop/repo
dir_build=${dir_base}/halide_build
dir_source=${dir_base}/Halide

export LLVM_CONFIG=/usr/bin/llvm-config
export CLANG=/usr/bin/clang

rm -rf "${dir_build}"
mkdir -p "${dir_build}"
pushd "${dir_build}" || exit

make -f "${dir_source}/Makefile" -j "${THREAD_CNT}"
rm -rf "${dir_build}/bin/build"

popd || exit

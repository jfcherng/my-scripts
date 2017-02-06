#!/usr/bin/env bash

export LLVM_CONFIG=/usr/bin/llvm-config
export CLANG=/usr/bin/clang

dir_base=/home/jfcherng/Desktop/repo
dir_build=${dir_base}/halide_build
dir_source=${dir_base}/Halide

build_threads=8



rm -rf ${dir_build}
mkdir -p ${dir_build}
cd ${dir_build}

make -f ${dir_source}/Makefile -j${build_threads}
rm -rf ${dir_build}/bin/build

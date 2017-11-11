#!/usr/bin/env bash

#------------------------------------------#
# This script ONLY works for PHP >= 7.0    #
#                                          #
# Author: Jack Cherng <jfcherng@gmail.com> #
#------------------------------------------#

SCIPRT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

THREAD_CNT=$(nproc --all)
PHP_BASE_DIR=/usr/local/php71

declare -A PHP_EXTS_CMD=(
    ["apcu"]="git clone https://github.com/krakjoe/apcu.git"
    ["ast"]="git clone https://github.com/nikic/php-ast.git ast"
    ["ds"]="git clone https://github.com/php-ds/extension.git ds"
    ["event"]="git clone https://bitbucket.org/osmanov/pecl-event.git event"
    ["igbinary"]="git clone https://github.com/igbinary/igbinary.git"
    ["msgpack"]="git clone https://github.com/msgpack/msgpack-php.git msgpack"
    ["redis"]="git clone https://github.com/phpredis/phpredis.git redis"
    ["swoole"]="git clone https://github.com/swoole/swoole-src.git swoole"
)

pushd "${SCIPRT_DIR}" || exit

for PHP_EXT_NAME in "${!PHP_EXTS_CMD[@]}"; do
    echo "==================================="
    echo "Begin compile ${PHP_EXT_NAME} ..."
    echo "==================================="

    # clone new repos
    if [ ! -d "${PHP_EXT_NAME}" ]; then
        eval "${PHP_EXTS_CMD[$PHP_EXT_NAME]}" || exit
    fi

    pushd "${PHP_EXT_NAME}/" || exit

    # fetch the latest source
    git submodule foreach git pull
    git fetch && git reset --hard "@{upstream}"

    # compile
    "${PHP_BASE_DIR}/bin/phpize"
    ./configure --with-php-config="${PHP_BASE_DIR}/bin/php-config"
    make -j "${THREAD_CNT}" && make install

    # clean up
    make clean
    "${PHP_BASE_DIR}/bin/phpize" --clean
    git clean -df
    git checkout -- .

    popd || exit

    echo "==================================="
    echo "End compile ${PHP_EXT_NAME} ..."
    echo "==================================="
done

popd || exit

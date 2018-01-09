#!/usr/bin/env bash

#------------------------------------------#
# This script ONLY works for PHP >= 7.0    #
#                                          #
# Author: Jack Cherng <jfcherng@gmail.com> #
#------------------------------------------#

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
THREAD_CNT=$(nproc --all)

PHP_BASE_DIRS=(
    "/usr/local/php70"
    "/usr/local/php71"
    "/usr/local/php72"
    "/usr/local/php73"
)

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

pushd "${SCRIPT_DIR}" || exit

# filter out useless PHP base directories
for IDX in "${!PHP_BASE_DIRS[@]}"; do
    PHP_BASE_DIR=${PHP_BASE_DIRS[$IDX]}

    # necessary files
    declare -A files=(
        ["phpize"]="${PHP_BASE_DIR}/bin/phpize"
        ["php_config"]="${PHP_BASE_DIR}/bin/php-config"
    )

    # eleminate PHP base directory if necessary files not found
    for file in "${files[@]}"; do
        if [ ! -f "${file}" ]; then
            echo "[*] Skip '${PHP_BASE_DIR}' because '${file}' is not a file..."
            unset PHP_BASE_DIRS["${IDX}"]
            continue 2
        fi
    done
done

for PHP_EXT_NAME in "${!PHP_EXTS_CMD[@]}"; do
    echo "==================================="
    echo "Begin compile '${PHP_EXT_NAME}'..."
    echo "==================================="

    # clone new repos
    if [ ! -d "${PHP_EXT_NAME}/.git" ]; then
        rm -rf "${PHP_EXT_NAME}"
        eval "${PHP_EXTS_CMD[$PHP_EXT_NAME]}" || exit
    fi

    pushd "${PHP_EXT_NAME}/" || exit

    # fetch the latest source
    git submodule foreach --recursive git pull
    git fetch && git reset --hard "@{upstream}"

    for PHP_BASE_DIR in "${PHP_BASE_DIRS[@]}"; do
        # paths
        phpize="${PHP_BASE_DIR}/bin/phpize"
        php_config="${PHP_BASE_DIR}/bin/php-config"

        # compile
        "${phpize}"
        ./configure --with-php-config="${php_config}"
        make -j "${THREAD_CNT}" && make install

        # clean up
        "${phpize}" --clean
        make clean
        git clean -dfx
        git checkout -- .
    done

    popd || exit

    echo "==================================="
    echo "End compile '${PHP_EXT_NAME}'..."
    echo "==================================="
done

popd || exit

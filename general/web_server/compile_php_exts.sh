#!/usr/bin/env bash

#--------------------------------------------------#
# This script compiles some extensions for PHP 7+. #
#                                                  #
# Author: Jack Cherng <jfcherng@gmail.com>         #
#--------------------------------------------------#

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
THREAD_CNT=$(getconf _NPROCESSORS_ONLN)

NOW="$(date +%Y%m%d%H%M%S)"
LOG_FILE="${SCRIPT_DIR}/compile_php_exts-${NOW}.log"

PHP_BASE_DIRS=(
    "/usr/local/php70"
    "/usr/local/php71"
    "/usr/local/php72"
    "/usr/local/php73"
    "/usr/local/php74"
    "/usr/local/php80"
    "/usr/local/php81"
    "/usr/local/php82"
    "/usr/local/php83"
)

# the command used to clone a repo
declare -A PHP_EXTS_CMD=(
    ["apcu"]="git clone https://github.com/krakjoe/apcu.git apcu"
    ["ast"]="git clone https://github.com/nikic/php-ast.git ast"
    ["ds"]="git clone https://github.com/php-ds/extension.git ds"
    ["event"]="git clone https://bitbucket.org/osmanov/pecl-event.git event"
    ["hashids"]="git clone https://github.com/cdoco/hashids.phpc.git hashids"
    ["igbinary"]="git clone https://github.com/igbinary/igbinary.git igbinary"
    ["imagick"]="git clone https://github.com/mkoppanen/imagick.git imagick"
    ["mcrypt"]="git clone https://github.com/php/pecl-encryption-mcrypt mcrypt"
    ["mongodb"]="git clone https://github.com/mongodb/mongo-php-driver.git mongodb"
    ["msgpack"]="git clone https://github.com/msgpack/msgpack-php.git msgpack"
    ["mysql"]="git clone https://github.com/php/pecl-database-mysql.git --recursive mysql"
    ["redis"]="git clone https://github.com/phpredis/phpredis.git redis"
    ["sodium"]="git clone https://github.com/jedisct1/libsodium-php.git sodium"
    ["ssh2"]="git clone https://github.com/php/pecl-networking-ssh2.git ssh2"
    ["swoole"]="git clone https://github.com/swoole/swoole-src.git swoole"
    ["xdebug"]="git clone https://github.com/xdebug/xdebug.git xdebug"
    ["xlswriter"]="git clone https://github.com/viest/php-ext-excel-export.git xlswriter"
)

# checkout repo to a specific commit before compilation
declare -A PHP_EXTS_CHECKOUT=(
    ["swoole"]="v4.8.8"
)

# extra flags appended to php-config
declare -A PHP_EXTS_CONFIG=(
    ["imagick"]="--with-imagick=/usr/local/imagemagick"
    ["redis"]="--enable-redis-igbinary --enable-redis-lzf"
    ["xdebug"]="--enable-xdebug"
)

function tab_title {
    if [ -z "$1" ]; then
        title=${PWD##*/} # current directory
    else
        title=$1 # first param
    fi

    echo -n -e "\033]0;${title}\007"
}

function git_repo_clean {
    make clean >/dev/null 2>&1
    git clean -dfx
    git checkout -- .
}

{

    #-------#
    # begin #
    #-------#

    pushd "${SCRIPT_DIR}" || exit

    # prefer the latest user-installed libs if possible
    PKG_CONFIG_PATH="/usr/local/lib/pkgconfig:/usr/local/lib64/pkgconfig:${PKG_CONFIG_PATH}"

    #-----------------------------------------#
    # filter out useless PHP base directories #
    #-----------------------------------------#

    for IDX in "${!PHP_BASE_DIRS[@]}"; do
        PHP_BASE_DIR=${PHP_BASE_DIRS[${IDX}]}

        # required files
        declare -A files=(
            ["phpize"]="${PHP_BASE_DIR}/bin/phpize"
            ["php_config"]="${PHP_BASE_DIR}/bin/php-config"
        )

        # eleminate PHP base directory if required files not found
        for file in "${files[@]}"; do
            if [ ! -f "${file}" ]; then
                echo "[*] Skip '${PHP_BASE_DIR}' because '${file}' is not a file..."
                unset PHP_BASE_DIRS["${IDX}"]
                continue 2
            fi
        done
    done

    #----------------------#
    # install dependencies #
    #----------------------#

    echo "==================================="
    echo "Begin install 'PHP' dependencies..."
    echo "==================================="

    # yum
    if command -v yum >/dev/null 2>&1; then
        yum install -y --skip-broken \
            mpdecimal mpdecimal-devel \
            libsodium libsodium-devel \
            liblzf liblzf-devel \
            ImageMagick ImageMagick-devel ImageMagick-perl
    # apt
    elif command -v apt >/dev/null 2>&1; then
        apt update
        apt install -y \
            libmpdec libmpdec-dev \
            libsodium23 libsodium-dev
    else
        echo "Could not find 'yum' or 'apt'..."
    fi

    #------------------------#
    # compile PHP extensions #
    #------------------------#

    BUILD_DIR="${SCRIPT_DIR}/php_exts_clone"

    mkdir -p "${BUILD_DIR}"

    pushd "${BUILD_DIR}" || exit

    for PHP_EXT_NAME in "${!PHP_EXTS_CMD[@]}"; do
        echo "==================================="
        echo "Begin compile '${PHP_EXT_NAME}'..."
        echo "==================================="

        # clone new repos
        if [ ! -d "${PHP_EXT_NAME}/.git" ]; then
            rm -rf "${PHP_EXT_NAME}"
            eval "${PHP_EXTS_CMD[${PHP_EXT_NAME}]}" || exit
        fi

        pushd "${PHP_EXT_NAME}/" || exit

        git_repo_clean

        # fetch the latest source
        git fetch --tags --force --prune --all && git reset --hard "@{upstream}"
        git submodule update --init
        git submodule foreach --recursive git pull

        # checkout a specific commit
        commit=${PHP_EXTS_CHECKOUT[${PHP_EXT_NAME}]}
        if [ "${commit}" != "" ]; then
            git checkout -f "${commit}"
        fi

        for PHP_BASE_DIR in "${PHP_BASE_DIRS[@]}"; do
            # paths
            phpize="${PHP_BASE_DIR}/bin/phpize"
            php_config="${PHP_BASE_DIR}/bin/php-config"
            config_options=${PHP_EXTS_CONFIG[${PHP_EXT_NAME}]}

            # set tab title (for tmux)
            tab_title "${PHP_BASE_DIR}: ${PHP_EXT_NAME}"

            # compile
            "${phpize}"
            ./configure --with-php-config="${php_config}" ${config_options}
            make -j"${THREAD_CNT}" install
            git_repo_clean
        done

        popd || exit

        # restore tab title
        tab_title

        echo "==================================="
        echo "End compile '${PHP_EXT_NAME}'..."
        echo "==================================="
    done

    popd || exit

    #-----#
    # end #
    #-----#

    # restore tab title
    tab_title

    popd || exit

} | tee "${LOG_FILE}"

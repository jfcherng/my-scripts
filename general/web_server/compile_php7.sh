#!/usr/bin/env bash

#------------------------------------------#
# This script ONLY works for PHP >= 7.0    #
#                                          #
# Author: Jack Cherng <jfcherng@gmail.com> #
#------------------------------------------#

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
THREAD_CNT=$(nproc --all)

declare -A PHP_CMD=(
    ["libzip"]="git clone https://github.com/nih-at/libzip.git"
    ["php-src"]="git clone https://github.com/php/php-src.git"
)

pushd "${SCRIPT_DIR}" || exit

# check repos
for repoName in "${!PHP_CMD[@]}"; do
    echo "==================================="
    echo "Check '${repoName}' repo..."
    echo "==================================="
    # clone new repos
    if [ ! -d "${repoName}/.git" ]; then
        rm -rf "${repoName}"
        eval "${PHP_CMD[$repoName]}" || exit
    # update existing repos
    else
        pushd "${repoName}" || exit

        # fetch the latest source
        git submodule foreach --recursive git pull
        git fetch && git reset --hard "@{upstream}"

        popd || exit
    fi
done

read -erp "PHP branch name to be compiled (such as 'PHP-7.2'): " php_branch

echo "==================================="
echo "Begin check 'PHP' branch..."
echo "==================================="

pushd "php-src" || exit

git checkout "${php_branch}"
if [ $? -ne 0 ]; then
    echo "[*] PHP branch '${php_branch}' dose not exist."
    exit 1
fi
git checkout -

popd || exit

echo "==================================="
echo "End check 'PHP' branch..."
echo "==================================="

read -erp "Where to install PHP (such as '/usr/local/php72'): " php_install_dir

if [ "${php_install_dir}" = "" ]; then
    echo "[*] Emtpy install dir is not allowed."
    exit 1
fi

read -erp "The user used to launch PHP executable (such as 'www'): " php_run_user

if [ "${php_run_user}" = "" ]; then
    php_run_user="www"
    echo "[*] Use '${php_run_user}' as the default user."
fi

echo
echo "==================================="
echo "php_branch      = ${php_branch}"
echo "php_install_dir = ${php_install_dir}"
echo "php_run_user    = ${php_run_user}"
echo "==================================="
echo
echo "Is the above information correct?"
echo "Press any key to start or Ctrl+C to cancel."
read -rn 1 # wait for a key press
echo

# compile libzip
echo "==================================="
echo "Begin compile 'libzip'..."
echo "==================================="

pushd "libzip" || exit

rm -rf "build" && mkdir "build"
pushd "build" || exit
cmake .. || exit
make -j "${THREAD_CNT}" && make install
popd || exit

popd || exit

echo "==================================="
echo "End compile 'libzip'..."
echo "==================================="

# compile PHP
echo "==================================="
echo "Begin compile 'PHP'..."
echo "==================================="

pushd "php-src" || exit

git checkout "${php_branch}"
git submodule foreach --recursive git pull
git fetch && git reset --hard "@{upstream}"

./buildconf --force

./configure \
--prefix="${php_install_dir}" \
--with-config-file-path="${php_install_dir}/etc" \
--with-config-file-scan-dir="${php_install_dir}/etc/php.d" \
--with-curl="/usr/local" --with-libzip \
--with-fpm-group="${php_run_user}" --with-fpm-user="${php_run_user}" \
--with-freetype-dir --with-gd --with-gettext \
--with-iconv-dir="/usr/local"--with-jpeg-dir --with-libxml-dir="/usr" \
--with-mcrypt --with-mhash --with-mysqli=mysqlnd --with-openssl \
--with-pdo-mysql=mysqlnd --with-png-dir --with-xmlrpc --with-xsl --with-zlib \
--enable-bcmath --enable-exif --enable-fpm --enable-ftp --enable-gd-native-ttf \
--enable-inline-optimization --enable-intl --enable-mbregex --enable-mbstring \
--enable-mysqlnd --enable-pcntl --enable-shmop --enable-soap --enable-sockets \
--enable-sysvsem --enable-xml --enable-zip \
--disable-debug --disable-rpath --disable-fileinfo

make -j "${THREAD_CNT}" ZEND_EXTRA_LIBS='-liconv' && make install

make clean
git clean -dfx
git checkout -- .

popd || exit

echo "==================================="
echo "End compile 'PHP'..."
echo "==================================="

popd || exit

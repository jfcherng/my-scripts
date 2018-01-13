#!/usr/bin/env bash

#------------------------------------------#
# This script compiles PHP 7+.             #
#                                          #
# Author: Jack Cherng <jfcherng@gmail.com> #
#------------------------------------------#

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
THREAD_CNT=$(nproc --all)

declare -A PHP_CMD=(
    ["libzip"]="git clone https://github.com/nih-at/libzip.git"
    ["php-src"]="git clone https://github.com/php/php-src.git"
)


#-------#
# begin #
#-------#

pushd "${SCRIPT_DIR}" || exit


#-------------#
# check repos #
#-------------#

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


#-------------------------#
# read option: php_branch #
#-------------------------#

read -erp "PHP branch name or version to be compiled (such as 'PHP-7.2' or '7.2'): " php_branch

# if php_branch is a version number, prepend "PHP-" to it
if [[ "${php_branch}" =~ ^[0-9]+([.][0-9]+)*$ ]]; then
    php_branch="PHP-${php_branch}"
fi

pushd "php-src" || exit
git checkout "${php_branch}"
if [ $? -ne 0 ]; then
    echo "[*] PHP branch '${php_branch}' dose not exist."
    exit 1
fi
git checkout -
popd || exit


#------------------------------#
# read option: php_install_dir #
#------------------------------#

read -erp "Where to install PHP (such as '/usr/local/php72'): " php_install_dir
if [ "${php_install_dir}" = "" ]; then
    echo "[*] Emtpy install dir is not allowed."
    exit 1
fi


#---------------------------#
# read option: php_run_user #
#---------------------------#

read -erp "Which user to launch PHP-FPM (such as 'www'): " php_run_user
if [ "${php_run_user}" = "" ]; then
    php_run_user="www"
    echo "[*] Use '${php_run_user}' as the default user."
fi


#-----------------------------#
# read option: compile_libzip #
#-----------------------------#

read -erp "Compile libzip library (Y/n): " compile_libzip
compile_libzip=${compile_libzip^^}
if [ "${compile_libzip}" != "N" ]; then
    compile_libzip="Y"
fi


#---------------------------#
# read option: thread_count #
#---------------------------#

read -erp "Parallel compilation with thread counts (default = ${THREAD_CNT}): " thread_count
if [ "${thread_count}" = "" ]; then
    thread_count=${THREAD_CNT}
fi


#--------------#
# confirmation #
#--------------#

echo
echo "==================================="
echo "compile_libzip  = ${compile_libzip}"
echo "thread_count    = ${thread_count}"
echo "php_branch      = ${php_branch}"
echo "php_install_dir = ${php_install_dir}"
echo "php_run_user    = ${php_run_user}"
echo "==================================="
echo
echo "Is the above information correct?"
echo "Press any key to start or Ctrl+C to cancel."
read -rn 1 # wait for a key press
echo


#-----------------#
# compile libdzip #
#-----------------#

if [ "${compile_libzip}" = "Y" ]; then

echo "==================================="
echo "Begin compile 'libzip'..."
echo "==================================="

pushd "libzip" || exit

rm -rf "build" && mkdir "build"
pushd "build" || exit
cmake .. || exit
make -j "${thread_count}" && make install
popd || exit

popd || exit

echo "==================================="
echo "End compile 'libzip'..."
echo "==================================="

fi


#-------------#
# compile PHP #
#-------------#

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

make -j "${thread_count}" ZEND_EXTRA_LIBS='-liconv' && make install

make clean
git clean -dfx
git checkout -- .

popd || exit

echo "==================================="
echo "End compile 'PHP'..."
echo "==================================="


#-----#
# end #
#-----#

popd || exit

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

read -erp "PHP version or branch name to be compiled (such as '7.2' or 'master'): " php_branch

# if php_branch is a version number, prepend "PHP-" to it
php_install_dir_default=
if [[ "${php_branch}" =~ ^[0-9]+([.][0-9]+)*$ ]]; then
    # concat the major and the minor version numbers as php_version_path
    php_version_path=$(echo "${php_branch}" | sed -r 's/^([0-9]+)(\.([0-9]+))?.*$/\1\3/g')
    php_install_dir_default="/usr/local/php${php_version_path}"
    php_branch="PHP-${php_branch}"
fi

pushd "php-src" || exit
git fetch origin
git rev-parse --verify "origin/${php_branch}"
if [ $? -ne 0 ]; then
    echo "[*] PHP branch '${php_branch}' dose not exist."
    exit 1
fi
popd || exit


#------------------------------#
# read option: php_install_dir #
#------------------------------#

if [ "${php_install_dir_default}" = "" ]; then
    php_install_dir_hint="such as '/usr/local/php72'"
else
    php_install_dir_hint="default = '${php_install_dir_default}'"
fi

read -erp "Where to install PHP (${php_install_dir_hint}): " php_install_dir

if [ "${php_install_dir}" = "" ]; then
    php_install_dir=${php_install_dir_default}
    if [ "${php_install_dir}" = "" ]; then
        echo "[*] Emtpy install dir is not allowed."
        exit 1
    else
        echo "[*] Use '${php_install_dir}' as the default install path."
    fi
fi


#---------------------------#
# read option: php_run_user #
#---------------------------#

php_run_user_default="www"

read -erp "Which user to launch PHP-FPM (default = '${php_run_user_default}'): " php_run_user

if [ "${php_run_user}" = "" ]; then
    php_run_user=${php_run_user_default}
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
make clean
make -j "${thread_count}" || exit
make install || exit
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
--with-curl="/usr/local" \
--with-fpm-group="${php_run_user}" \
--with-fpm-user="${php_run_user}" \
--with-libzip \
--with-freetype-dir \
--with-gettext \
--with-gz \
--with-iconv-dir="/usr/local" \
--with-jpeg-dir \
--with-libxml-dir="/usr" \
--with-mcrypt \
--with-mhash \
--with-mysqli=mysqlnd \
--with-openssl \
--with-pdo-mysql=mysqlnd \
--with-png-dir \
--with-xmlrpc \
--with-xsl \
--with-zlib \
--enable-bcmath \
--enable-exif \
--enable-fpm \
--enable-ftp \
--enable-gd-native-ttf \
--enable-inline-optimization \
--enable-intl \
--enable-mbregex \
--enable-mbstring \
--enable-mysqlnd \
--enable-pcntl \
--enable-shmop \
--enable-soap \
--enable-sockets \
--enable-sysvsem \
--enable-xml \
--enable-zip \
--disable-debug \
--disable-rpath \
--disable-fileinfo

make -j "${thread_count}" ZEND_EXTRA_LIBS='-liconv' || exit
make install || exit

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

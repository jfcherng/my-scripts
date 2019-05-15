#!/usr/bin/env bash

#------------------------------------------#
# This script compiles PHP 7+.             #
#                                          #
# Author: Jack Cherng <jfcherng@gmail.com> #
#------------------------------------------#

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
THREAD_CNT=$(getconf _NPROCESSORS_ONLN)
MEMSIZE_MB=$(free -m | awk '/^Mem:/{print $2}')

declare -A PHP_CMD=(
    ["libzip"]="git clone https://github.com/nih-at/libzip.git"
    ["php-src"]="git clone https://github.com/php/php-src.git"
)


#-------#
# begin #
#-------#

pushd "${SCRIPT_DIR}" || exit

# prefer the latest user-installed libs if possible
PKG_CONFIG_PATH="/usr/local/lib/pkgconfig:/usr/local/lib64/pkgconfig:${PKG_CONFIG_PATH}"


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
    fi

    pushd "${repoName}" || exit

    # fetch the latest source
    git fetch --tags --force --prune --all && git reset --hard "@{upstream}"
    git submodule update --init
    git submodule foreach --recursive git pull

    popd || exit
done


#-------------------------#
# read option: php_branch #
#-------------------------#

read -erp "PHP branch to be compiled (such as '7.2', '7.3.2', 'origin/master', etc): " php_branch

pushd "php-src" || exit

git fetch --tags --force --prune --all

# some branches to be tried
php_test_branches=(
    # tags
    "tags/${php_branch}"
    "tags/php-${php_branch^^}"
    # branches
    "origin/${php_branch}"
    "origin/PHP-${php_branch}"
    # customized
    "${php_branch}"
)

php_full_branch=""
for php_test_branch in "${php_test_branches[@]}"; do
    git rev-parse --verify "${php_test_branch}"
    if [ $? -eq 0 ]; then
        php_full_branch="${php_test_branch}"
        break
    fi
done

if [ "${php_full_branch}" = "" ]; then
    echo "[*] Cannot found related PHP branch: ${php_branch}"
    exit 1
fi

echo "[*] Use PHP branch: ${php_full_branch}"

# such as "7.3.0"
php_version=$(git show "${php_full_branch}:./NEWS" | command grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1)
# such as "7.3.0" => "73"
php_version_path=$(echo "${php_version}" | sed -r 's/^([0-9]+)(\.([0-9]+))?.*$/\1\3/g')
# such as "73" => "/usr/local/php73"
php_install_dir_default="/usr/local/php${php_version_path}"

popd || exit


#------------------------------#
# read option: php_install_dir #
#------------------------------#

read -erp "Where to install PHP (default = '${php_install_dir_default}'): " php_install_dir

if [ "${php_install_dir}" = "" ]; then
    php_install_dir=${php_install_dir_default}
    echo "[*] Use '${php_install_dir}' as the default install path."
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
echo "php_full_branch = ${php_full_branch}"
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
echo "Begin install 'PHP' dependencies..."
echo "==================================="

# yum
if command -v yum >/dev/null 2>&1; then
    yum install -y \
        aspell-en aspell-devel \
        bzip2 bzip2-devel \
        curl curl-devel \
        freetype-devel \
        gmp-devel \
        icu libicu libicu-devel \
        libsodium libsodium-devel \
        libjpeg-devel libpng-devel libwebp-devel \
        libxml2 libxml2-devel \
        libxslt libxslt-devel \
        ncurses ncurses-devel \
        pcre-devel oniguruma-devel \
        sqlite-devel \
        readline-devel
# apt
elif command -v apt >/dev/null 2>&1; then
    apt update
    apt install -y \
        bzip2 bzip2-dev \
        libgmp-dev \
        libonig libonig-dev \
        libxml2 libxml2-dev \
        libsodium23 libsodium-dev \
        libsqlite3 libsqlite3-dev
else
    echo "Could not find 'yum' or 'apt'..."
fi

echo "==================================="
echo "End install 'PHP' dependencies..."
echo "==================================="

echo "==================================="
echo "Begin compile 'PHP'..."
echo "==================================="

# update library link paths
ldconfig

LOW_MEMORY_FLAGS=()

if [ "${MEMSIZE_MB}" -lt "256" ]; then
    LOW_MEMORY_FLAGS+=('--disable-fileinfo')
fi

ZEND_EXTRA_LIBS=()

# if we could link to the iconv library, add a flag for it
if ldconfig -p | grep libiconv >/dev/null 2>&1; then
    ZEND_EXTRA_LIBS+=('-liconv')
fi

pushd "php-src" || exit

git clean -dfx
git checkout -- .
git checkout -f "${php_full_branch}"
git reset --hard "@{upstream}"
git submodule update --init
git submodule foreach --recursive git pull

# use the git commit hash to replace the "-dev" in the PHP version tag
sed -i"" -E "s/-dev/-dev@$(git rev-parse --short HEAD)/g" ./configure.ac

./buildconf --force

./configure \
    --prefix="${php_install_dir}" \
    --disable-debug \
    --disable-rpath \
    --enable-bcmath \
    --enable-calendar \
    --enable-exif \
    --enable-fpm \
    --enable-ftp \
    --enable-inline-optimization \
    --enable-intl \
    --enable-mbregex --enable-mbstring \
    --enable-pcntl \
    --enable-shmop \
    --enable-soap \
    --enable-sockets \
    --enable-sysvmsg --enable-sysvsem --enable-sysvshm \
    --enable-wddx \
    --enable-xml \
    --enable-zip \
    --with-bz2 \
    --with-config-file-path="${php_install_dir}/etc" \
    --with-config-file-scan-dir="${php_install_dir}/etc/php.d" \
    --with-curl="/usr/local" \
    --with-fpm-group="${php_run_user}" \
    --with-fpm-user="${php_run_user}" \
    --with-gd --with-freetype-dir --with-jpeg-dir --with-png-dir --with-webp-dir --enable-gd-native-ttf \
    --with-gettext \
    --with-gmp \
    --with-iconv-dir="/usr/local" \
    --with-libxml-dir="/usr" \
    --with-libzip \
    --with-mhash \
    --with-mysqli=mysqlnd --with-pdo-mysql=mysqlnd --enable-mysqlnd \
    --with-openssl \
    --with-pspell \
    --with-readline \
    --with-xmlrpc \
    --with-xsl \
    --with-zlib \
    ${LOW_MEMORY_FLAGS[*]}

# PEAR is no longer maintained, ignore errors about PEAR
sed -i"" -E "s/^(install-pear):/.IGNORE: \1\n\1:/g" ./Makefile

make -j "${thread_count}" ZEND_EXTRA_LIBS="${ZEND_EXTRA_LIBS[*]}" || exit
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

"${php_install_dir}/bin/php" -v

popd || exit

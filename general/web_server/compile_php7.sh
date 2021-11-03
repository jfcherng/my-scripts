#!/usr/bin/env bash

#------------------------------------------#
# This script compiles PHP 7+.             #
#                                          #
# Author: Jack Cherng <jfcherng@gmail.com> #
#------------------------------------------#

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
THREAD_CNT=$(getconf _NPROCESSORS_ONLN)
MEMSIZE_MB=$(free -m | awk '/^Mem:/{print $2}')

NOW="$(date +%Y%m%d%H%M%S)"
LOG_FILE="${SCRIPT_DIR}/compile_php7-${NOW}.log"

function git_repo_clean {
    make clean >/dev/null 2>&1
    git clean -dfx
    git checkout -- .
}

declare -A PHP_CMD=(
    ["libzip"]="git clone https://github.com/nih-at/libzip.git"
    ["php-src"]="git clone https://github.com/php/php-src.git"
)

{

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
        eval "${PHP_CMD[${repoName}]}" || exit
    fi

    pushd "${repoName}" || exit

    git_repo_clean

    # fetch the latest source
    git fetch --tags --force --prune --all && git reset --hard "@{upstream}"
    git submodule update --init
    git submodule foreach --recursive git pull

    popd || exit
done


#----------------------#
# read option: php_rev #
#----------------------#

read -erp "PHP revision to be compiled (such as '7.3.2', '3c3775fc38' or 'origin/master'): " php_rev

pushd "php-src" || exit

# some possible revisions to be tried
php_test_revs=(
    # tags
    "tags/${php_rev}"
    "tags/php-${php_rev}"
    "tags/php-${php_rev^^}" # all uppercase, such as "RC"
    "tags/php-${php_rev,,}" # all lowercase, such as "alpha"
    # branches
    "origin/${php_rev}"
    "origin/PHP-${php_rev}"
    "origin/PHP-${php_rev^^}" # all uppercase, such as "RC"
    "origin/PHP-${php_rev,,}" # all lowercase, such as "alpha"
    # customized
    "${php_rev}"
    "${php_rev^^}"
    "${php_rev,,}"
)

php_full_rev=""
for php_test_rev in "${php_test_revs[@]}"; do
    if git rev-parse --verify "${php_test_rev}" 2>/dev/null ; then
        php_full_rev="${php_test_rev}"
        break
    fi
done

if [ "${php_full_rev}" = "" ]; then
    echo "[*] Cannot found related PHP revision: ${php_rev}"
    exit 1
fi

echo "[*] Use PHP revision: ${php_full_rev}"

# such as "7.3.0"
php_version=$(git show "${php_full_rev}:./NEWS" | command grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1)
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
echo "php_full_rev    = ${php_full_rev}"
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
    yum install -y --skip-broken \
        aspell-en aspell-devel \
        bison \
        bzip2 bzip2-devel \
        curl curl-devel \
        freetype-devel \
        gmp-devel \
        icu libicu libicu-devel \
        libc-client uw-imap-devel \
        libffi libffi-devel \
        libjpeg-devel libpng-devel libwebp7-devel libwebp-devel libXpm-devel \
        libsodium libsodium-devel \
        libxml2 libxml2-devel \
        libxslt libxslt-devel \
        ncurses ncurses-devel \
        pcre-devel oniguruma-devel \
        re2c \
        readline-devel \
        sqlite-devel
# apt
elif command -v apt >/dev/null 2>&1; then
    apt update
    apt install -y \
        bison \
        bzip2 bzip2-dev \
        libc-client-dev libkrb5-dev \
        libffi libffi-dev \
        libfreetype6-dev \
        libgmp-dev \
        libjpeg-dev libpng-dev libwebp-dev libwebp7-dev libxpm-dev \
        libncurses libncurses-dev \
        libonig libonig-dev \
        libsodium23 libsodium-dev \
        libsqlite3 libsqlite3-dev \
        libxml2 libxml2-dev \
        re2c \
        sqlite-devel
else
    echo "Could not find 'yum' or 'apt'..."
fi

echo "==================================="
echo "End install 'PHP' dependencies..."
echo "==================================="

echo "==================================="
echo "Begin compile 'PHP'..."
echo "==================================="

# add user custom libs into search paths
cat <<EOT > /etc/ld.so.conf.d/usr-local.conf
/usr/local/lib
/usr/local/lib64
EOT

# update library link paths
ldconfig

LOW_MEMORY_FLAGS=()

if [ "${MEMSIZE_MB}" -lt "512" ]; then
    LOW_MEMORY_FLAGS+=('--disable-fileinfo')
fi

EXTRA_FLAGS=()

# if we could link to the iconv library, add a flag for it
if ldconfig -p | grep libiconv >/dev/null 2>&1; then
    EXTRA_FLAGS+=('-liconv')
fi

pushd "php-src" || exit

git_repo_clean

git checkout -f "${php_full_rev}"
git reset --hard "@{upstream}"
git submodule update --init
git submodule foreach --recursive git pull

# use the git commit hash to replace the "-dev" in the PHP version tag
sed -i"" -E "s/-dev/-dev@$(git rev-parse --short HEAD)/g" ./configure.ac

./buildconf --force

# there are some mixed --enable/--with switches because some of them are different among versions.
# for example, gd/zlib switches have been changed since PHP 7.4.
./configure \
    --prefix="${php_install_dir}" \
    --with-config-file-path="${php_install_dir}/etc" \
    --with-config-file-scan-dir="${php_install_dir}/etc/php.d" \
    --with-fpm-group="${php_run_user}" \
    --with-fpm-user="${php_run_user}" \
    --disable-debug \
    --disable-phpdbg \
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
    --with-curl="/usr/local" \
    --with-ffi \
    --with-gd --enable-gd \
        --enable-gd-native-ttf --enable-gd-jis-conv \
        --with-freetype-dir --with-freetype \
        --with-jpeg-dir --with-jpeg \
        --with-png-dir --with-png \
        --with-webp-dir --with-webp \
        --with-xpm-dir --with-xpm \
    --with-gettext \
    --with-gmp \
    --with-iconv-dir="/usr/local" \
    --with-imap --with-kerberos --with-imap-ssl --with-libdir="lib64" \
    --with-libxml-dir="/usr" \
    --with-libzip="/usr/local" \
    --with-mhash \
    --with-mysqli=mysqlnd --with-pdo-mysql=mysqlnd --enable-mysqlnd \
    --with-openssl \
    --with-pspell \
    --with-readline \
    --with-xmlrpc \
    --with-xsl \
    --with-zip \
    --with-zlib --with-zlib-dir \
    LDFLAGS="${EXTRA_FLAGS[*]}" \
    ${LOW_MEMORY_FLAGS[*]}

# PEAR is no longer maintained, ignore errors about PEAR
sed -i"" -E "s/^(install-pear):/.IGNORE: \1\n\1:/g" ./Makefile

make -j "${thread_count}" ZEND_EXTRA_LIBS="${EXTRA_FLAGS[*]}" || exit
make install || exit
git_repo_clean

popd || exit

echo "==================================="
echo "End compile 'PHP'..."
echo "==================================="


#-----#
# end #
#-----#

"${php_install_dir}/bin/php" -v

# try to restart the daemon if PHP works normally
if [ $? -eq 0 ]; then
    daemon="/etc/init.d/php${php_version_path}-fpm"

    [ -x "${daemon}" ] && "${daemon}" restart
fi

popd || exit

} | tee "${LOG_FILE}"

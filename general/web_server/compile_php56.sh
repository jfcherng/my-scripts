#!/usr/bin/env bash

#------------------------------------------#
# This script compiles PHP 5.6.            #
#                                          #
# Author: Jack Cherng <jfcherng@gmail.com> #
#------------------------------------------#

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
THREAD_CNT=$(getconf _NPROCESSORS_ONLN)
MEMSIZE_MB=$(free -m | awk '/^Mem:/{print $2}')


#----------------#
# configurations #
#----------------#

bison_version="2.7.1"
php_version="5.6.39"

# such as "5.6.39" => "56"
php_version_path=$(echo "${php_version}" | sed -r 's/^([0-9]+)(\.([0-9]+))?.*$/\1\3/g')

php_run_user="www"
php_install_dir="/usr/local/php${php_version_path}"
php_src_dir="php-${php_version}"


#----------------------#
# install dependencies #
#----------------------#

yum install -y \
    aspell-devel \
    bzip2 bzip2-devel \
    curl curl-devel \
    freetype-devel \
    gmp-devel \
    icu libicu libicu-devel \
    libjpeg-devel libpng-devel libwebp-devel \
    libmcrypt-devel \
    libssh2-devel \
    libtidy-devel \
    libxml2 libxml2-devel \
    libxslt libxslt-devel \
    ncurses ncurses-devel \
    openldap-devel \
    pcre-devel \
    readline-devel


#-----------------#
# fix lib linking #
#-----------------#

ln -sf /usr/lib64/libldap* /usr/lib/
ln -sf /usr/lib64/liblber* /usr/lib/

ldconfig


#-------#
# begin #
#-------#

pushd "${SCRIPT_DIR}" || exit


#-------------------------------#
# compile old bison for PHP 5.6 #
#-------------------------------#

bison_bin_dir="$(pwd)/bison-${bison_version}/build/bin"
if [ ! -f "${bison_bin_dir}/bison" ]; then
    bison_tarball="bison-${bison_version}.tar.gz"

    # remove possibly corrupted old tarball
    rm -f "${bison_tarball}"

    wget --no-check-certificate "https://ftp.gnu.org/gnu/bison/${bison_tarball}"

    if [ ! -s "${bison_tarball}" ]; then
        echo "Failed to download bison tarball from GitHub..."
        exit 1
    fi

    tar xf "${bison_tarball}"

    pushd "bison-${bison_version}" || exit

    mkdir -p build
    ./configure --prefix="$(pwd)/build"
    make -j"${THREAD_CNT}" && make install

    popd || exit
fi

# prefer using older bison
if ! bison --version | grep -F -q "${bison_version}"; then
    echo "* temporarily set bison executable into PATH"
    PATH="${bison_bin_dir}:$PATH"
fi


#-------------#
# compile PHP #
#-------------#

if [ ! -f "${php_src_dir}/buildconf" ]; then
    php_tarball="php-${php_version}.tar.gz"
    wget --no-check-certificate "https://github.com/php/php-src/archive/${php_tarball}"

    if [ ! -s "${php_tarball}" ]; then
        echo "Failed to download PHP tarball from GitHub..."
        exit 1
    fi

    tar xf "${php_tarball}"
    mv "php-src-${php_src_dir}" "${php_src_dir}"
fi


LOW_MEMORY_FLAGS=()

if [ "${MEMSIZE_MB}" -lt "256" ]; then
    LOW_MEMORY_FLAGS+=('--disable-fileinfo')
fi

ZEND_EXTRA_LIBS=()

# if we could link to the iconv library, add a flag for it
if ldconfig -p | grep libiconv >/dev/null 2>&1; then
    ZEND_EXTRA_LIBS+=('-liconv')
fi

# if we could link to the LDAP library, add a flag for it
if ldconfig -p | grep liblber >/dev/null 2>&1; then
    ZEND_EXTRA_LIBS+=('-llber')
fi


pushd "${php_src_dir}" || exit

./buildconf --force

./configure --prefix="${php_install_dir}" \
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
--with-gd --with-freetype-dir --with-jpeg-dir --with-png-dir --enable-gd-native-ttf \
--with-gettext \
--with-gmp \
--with-iconv-dir="/usr/local" \
--with-libxml-dir="/usr" \
--with-libzip \
--with-mhash \
--with-mysql=mysqlnd --with-mysqli=mysqlnd --with-pdo-mysql=mysqlnd --enable-mysqlnd \
--with-openssl \
--with-pspell \
--with-readline \
--with-xmlrpc \
--with-xsl \
--with-zlib \
${LOW_MEMORY_FLAGS[*]}

make -j"${THREAD_CNT}" ZEND_EXTRA_LIBS="${ZEND_EXTRA_LIBS[*]}" && make install && make clean

popd || exit


#-----#
# end #
#-----#

popd || exit

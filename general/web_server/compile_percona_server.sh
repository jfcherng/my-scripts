#!/usr/bin/env bash

#---------------------------------------------------#
# This script compiles the latest Percona server.   #
#                                                   #
# Author: Jack Cherng <jfcherng@gmail.com>          #
#---------------------------------------------------#

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
THREAD_CNT=$(getconf _NPROCESSORS_ONLN)

APP_NAME=Percona-Server-8.0.15-6
TAR_FILE_BASENAME=${APP_NAME,,}
TAR_FILE_NAME=${TAR_FILE_BASENAME}.tar.gz

INSTALL_DIR=/usr/local/mysql

function version { echo "$@" | awk -F. '{ printf("%d%03d%03d%03d\n", $1,$2,$3,$4); }'; }

#-------------------#
# check gcc version #
#-------------------#

GCC_MIN_VERSION=4.9.0
if [ $(version $(gcc -dumpversion)) -lt $(version "${GCC_MIN_VERSION}") ]; then
    echo "[*] GCC must be newer than ${GCC_MIN_VERSION}"
    exit 1
fi


#--------------#
# install deps #
#--------------#

yum install -y \
    scons socat openssl check cmake3 bison \
    boost-devel asio-devel libaio-devel ncurses-devel \
    readline-devel pam-devel libcurl-devel


#-------#
# begin #
#-------#

pushd "${SCRIPT_DIR}" || exit

# prefer the latest user-installed libs if possible
PKG_CONFIG_PATH="/usr/local/lib/pkgconfig:/usr/local/lib64/pkgconfig:${PKG_CONFIG_PATH}"


#---------------------#
# download the source #
#---------------------#

wget "https://www.percona.com/downloads/Percona-Server-LATEST/${APP_NAME}/source/tarball/${TAR_FILE_NAME}" -O "${TAR_FILE_NAME}"
tar xf "${TAR_FILE_NAME}"


#-----------------#
# compile Percona #
#-----------------#

pushd "${TAR_FILE_BASENAME}" || exit

rm -rf my_build && mkdir -p my_build
pushd my_build  || exit

cmake .. \
    -DCMAKE_INSTALL_PREFIX:PATH="${INSTALL_DIR}" \
    -DDOWNLOAD_BOOST=1 -DWITH_BOOST="$(pwd)/boost" \
    -DCMAKE_BUILD_TYPE=RelWithDebInfo \
    -DBUILD_CONFIG=mysql_release \
    -DFEATURE_SET=community

# it's quite possible that we run out of memory, so -j2
make -j2 || exit
make install || exit

popd || exit

popd || exit


#-----#
# end #
#-----#

"${INSTALL_DIR}/bin/mysql" -V || exit

groupadd mysql
useradd -g mysql -s /sbin/nologin -M mysql

mkdir -p /data/mysql
chown mysql.mysql -R /data/mysql

popd || exit

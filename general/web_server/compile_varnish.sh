#!/usr/bin/env bash

#---------------------------------------------------#
# This script compiles Varnish.                     #
# https://github.com/varnishcache/varnish-cache.git #
#                                                   #
# Author: Jack Cherng <jfcherng@gmail.com>          #
#---------------------------------------------------#

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
THREAD_CNT=$(getconf _NPROCESSORS_ONLN)
MEMSIZE_MB=$(free -m | awk '/^Mem:/{print $2}')


#-------#
# begin #
#-------#

pushd "${SCRIPT_DIR}" || exit


#--------------------------#
# read option: vsh_version #
#--------------------------#

read -erp "Varnish version to be compiled (such as '6.1.0'): " vsh_version

# check version format
if [[ ! "${vsh_version}" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    echo "[ERROR] '${vsh_version}' is not a valid version foramt"
    exit 1
fi

# such as "6.1.0" => "6"
vsh_version_path=$(echo "${vsh_version}" | sed -r 's/^([0-9]+)\..*$/\1/g')
# such as "6" => "/usr/local/varnish6"
vsh_install_dir_default="/usr/local/varnish${vsh_version_path}"


#------------------------------#
# read option: vsh_install_dir #
#------------------------------#

read -erp "Where to install vsh (default = '${vsh_install_dir_default}'): " vsh_install_dir

if [ "${vsh_install_dir}" = "" ]; then
    vsh_install_dir=${vsh_install_dir_default}
    echo "[*] Use '${vsh_install_dir}' as the default install path."
fi


#---------------------------#
# read option: vsh_run_user #
#---------------------------#

vsh_run_user_default="www"

read -erp "Which user to launch vsh-FPM (default = '${vsh_run_user_default}'): " vsh_run_user

if [ "${vsh_run_user}" = "" ]; then
    vsh_run_user=${vsh_run_user_default}
    echo "[*] Use '${vsh_run_user}' as the default user."
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
echo "thread_count    = ${thread_count}"
echo "vsh_version     = ${vsh_version}"
echo "vsh_install_dir = ${vsh_install_dir}"
echo "vsh_run_user    = ${vsh_run_user}"
echo "==================================="
echo
echo "Is the above information correct?"
echo "Press any key to start or Ctrl+C to cancel."
read -rn 1 # wait for a key press
echo


#-----------------#
# compile varnish #
#-----------------#

echo "==================================="
echo "Begin install 'varnish' dependencies..."
echo "==================================="

# yum
if command -v yum >/dev/null 2>&1; then
    yum install -y \
        make \
        autoconf \
        automake \
        jemalloc-devel \
        libedit-devel \
        libtool \
        ncurses-devel \
        pcre-devel \
        pkgconfig \
        python-docutils \
        python-sphinx
# apt
elif command -v apt >/dev/null 2>&1; then
    apt update
    apt install -y \
        make \
        automake \
        autotools-dev \
        libedit-dev \
        libjemalloc-dev \
        libncurses-dev \
        libpcre3-dev \
        libtool \
        pkg-config \
        python-docutils \
        python-sphinx
else
    echo "Could not find 'yum' or 'apt'..."
fi

echo "==================================="
echo "End install 'varnish' dependencies..."
echo "==================================="

echo "==================================="
echo "Begin download 'varnish'..."
echo "==================================="

# download the tarball
tarball="varnish-${vsh_version}.tar.gz"
tarball_url="https://github.com/varnishcache/varnish-cache/archive/${tarball}"
tarball_dir="varnish-cache-varnish-${vsh_version}"
wget "${tarball_url}" -O "${tarball}"

# make sure download successfully
if [ ! -f "${tarball}" ]; then
    echo "[ERROR] Fail to download '${tarball_url}'"
    exit 1
fi

# decompress the tarball
if ! tar xf "${tarball}"; then
    echo "[ERROR] Fail to decompress '${tarball}'"
    exit 1
fi

echo "==================================="
echo "End download 'varnish'..."
echo "==================================="

echo "==================================="
echo "Begin compile 'varnish'..."
echo "==================================="

ldconfig

EXTRA_FLAGS=()

if ldconfig -p | grep libjemalloc; then
    echo "[INFO] Found 'jemalloc' installed!"
    EXTRA_FLAGS+=('--with-jemalloc')
fi

pushd "${tarball_dir}" || exit

./autogen.sh

./configure --prefix="${vsh_install_dir}" \
${EXTRA_FLAGS[*]}

make -j "${thread_count}" || exit
make install || exit

mkdir -p "${vsh_install_dir}/etc"
cp etc/*.vcl "${vsh_install_dir}/etc"

make clean

popd || exit

echo "==================================="
echo "End compile 'varnish'..."
echo "==================================="

ldconfig

"${vsh_install_dir}/sbin/varnishd" -V

#-----#
# end #
#-----#

popd || exit

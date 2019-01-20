#!/usr/bin/env bash

#------------------------------------------#
# This script compiles the latest NGINX.   #
#                                          #
# Author: Jack Cherng <jfcherng@gmail.com> #
#------------------------------------------#

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
THREAD_CNT=$(getconf _NPROCESSORS_ONLN)
NGINX_FLAGS=()


#--------#
# config #
#--------#

LUAJIT2_VERSION="2.1-20190115"
OPENSSL_VERSION="1.1.1a"

declare -A NGINX_CMD=(
    ["nginx"]="git clone https://github.com/nginx/nginx.git"
    ["ngx_brotli"]="git clone https://github.com/google/ngx_brotli.git ngx_brotli"
    ["ngx_devel_kit"]="git clone https://github.com/simplresty/ngx_devel_kit.git ngx_devel_kit"
    ["ngx_headers_more"]="git clone https://github.com/openresty/headers-more-nginx-module.git ngx_headers_more"
    ["ngx_http_concat"]="git clone https://github.com/alibaba/nginx-http-concat.git ngx_http_concat"
    ["ngx_http_trim"]="git clone https://github.com/taoyuanyuan/ngx_http_trim_filter_module.git ngx_http_trim"
    ["ngx_lua"]="git clone https://github.com/openresty/lua-nginx-module.git ngx_lua"
)


#-------#
# begin #
#-------#

pushd "${SCRIPT_DIR}" || exit


#-------------#
# check repos #
#-------------#

for repoName in "${!NGINX_CMD[@]}"; do
    # clone new repos
    if [ ! -d "${repoName}/.git" ]; then
        rm -rf "${repoName}"
        eval "${NGINX_CMD[$repoName]}" || exit
    fi

    pushd "${repoName}" || exit

    # fetch the latest source
    git fetch --tags --force --prune --all && git reset --hard "@{upstream}"
    git submodule update --init
    git submodule foreach --recursive git pull

    popd || exit
done


#---------------#
# check luajit2 #
#---------------#

luajit2_tarball="luajit2-${LUAJIT2_VERSION}.tar.gz"
luajit2_src_dir="luajit2-${LUAJIT2_VERSION}"
if [ ! -d "${luajit2_src_dir}" ]; then
    rm -f "${luajit2_tarball}"
    wget --no-check-certificate "https://github.com/openresty/luajit2/archive/v${LUAJIT2_VERSION}.tar.gz" -O "${luajit2_tarball}"

    if [ ! -s "${luajit2_tarball}" ]; then
        echo "Failed to download luajit2 tarball..."
        exit 1
    fi

    tar xf "${luajit2_tarball}"
fi


#---------------#
# check openssl #
#---------------#

openssl_tarball="openssl-${OPENSSL_VERSION}.tar.gz"
openssl_src_dir="openssl-${OPENSSL_VERSION}"
if [ ! -d "${openssl_src_dir}" ]; then
    rm -f "${openssl_tarball}"
    wget --no-check-certificate "https://www.openssl.org/source/${openssl_tarball}"

    if [ ! -s "${openssl_tarball}" ]; then
        echo "Failed to download OpenSSL tarball..."
        exit 1
    fi

    tar xf "${openssl_tarball}"
fi


#----------------#
# check jemalloc #
#----------------#

if command -v jemalloc-config >/dev/null 2>&1; then
    echo "[*] Compile NGINX with jemalloc"
    NGINX_FLAGS+=( "--with-ld-opt='-ljemalloc'" )
fi


#-----------------#
# compile luajit2 #
#-----------------#

echo "==================================="
echo "Begin compile 'luajit2'..."
echo "==================================="

pushd "${luajit2_src_dir}" || exit

luajit2_install_dir="/usr/local"

make PREFIX="${luajit2_install_dir}" -j "${THREAD_CNT}" || exit
make install PREFIX="${luajit2_install_dir}" || exit

ldconfig

export LUAJIT_LIB="${luajit2_install_dir}/lib"
export LUAJIT_INC="${luajit2_install_dir}/include/luajit-2.1"

NGINX_FLAGS+=( "--with-ld-opt='-Wl,-rpath,${LUAJIT_LIB}'" )

popd || exit

echo "==================================="
echo "End compile 'luajit2'..."
echo "==================================="


#---------------#
# compile NGINX #
#---------------#

echo "==================================="
echo "Begin compile 'NGINX'..."
echo "==================================="

pushd nginx || exit

./auto/configure \
    --prefix=/usr/local/nginx \
    --user=www \
    --group=www \
    --with-http_flv_module \
    --with-http_gzip_static_module \
    --with-http_realip_module \
    --with-http_ssl_module \
    --with-http_stub_status_module \
    --with-http_v2_module \
    --with-openssl="${SCRIPT_DIR}/${openssl_src_dir}" \
    --add-module="${SCRIPT_DIR}/ngx_brotli" \
    --add-module="${SCRIPT_DIR}/ngx_devel_kit" \
    --add-module="${SCRIPT_DIR}/ngx_headers_more" \
    --add-module="${SCRIPT_DIR}/ngx_http_concat" \
    --add-module="${SCRIPT_DIR}/ngx_http_trim" \
    --add-module="${SCRIPT_DIR}/ngx_lua" \
    ${NGINX_FLAGS[@]}

make -j "${THREAD_CNT}" || exit
make install || exit


#----------#
# clean up #
#----------#

make clean
git clean -dfx
git checkout -- .

popd || exit

echo "==================================="
echo "End compile 'NGINX'..."
echo "==================================="


#-----#
# end #
#-----#

popd || exit

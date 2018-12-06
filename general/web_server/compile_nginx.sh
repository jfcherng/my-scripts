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

OPENSSL_VERSION="1.1.1a"

declare -A NGINX_CMD=(
    ["nginx"]="git clone https://github.com/nginx/nginx.git"
    ["ngx_brotli"]="git clone https://github.com/google/ngx_brotli.git ngx_brotli"
    ["ngx_headers_more"]="git clone https://github.com/openresty/headers-more-nginx-module.git ngx_headers_more"
    ["ngx_http_concat"]="git clone https://github.com/alibaba/nginx-http-concat.git ngx_http_concat"
    ["ngx_http_trim"]="git clone https://github.com/taoyuanyuan/ngx_http_trim_filter_module.git ngx_http_trim"
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
--add-module="${SCRIPT_DIR}/ngx_headers_more" \
--add-module="${SCRIPT_DIR}/ngx_http_concat" \
--add-module="${SCRIPT_DIR}/ngx_http_trim" \
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

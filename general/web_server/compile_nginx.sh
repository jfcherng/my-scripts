#!/usr/bin/env bash

#------------------------------------------#
# Author: Jack Cherng <jfcherng@gmail.com> #
#------------------------------------------#

SCIPRT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

THREAD_CNT=$(nproc --all)
NGINX_FLAGS=()

declare -A NGINX_CMD=(
    ["nginx"]="git clone https://github.com/nginx/nginx.git"
    ["ngx_http_concat"]="git clone https://github.com/alibaba/nginx-http-concat.git ngx_http_concat"
    ["ngx_http_trim"]="git clone https://github.com/taoyuanyuan/ngx_http_trim_filter_module.git ngx_http_trim"
)

pushd "${SCIPRT_DIR}" || exit

# check repos
for repoName in "${!NGINX_CMD[@]}"; do
    # clone new repos
    if [ ! -d "${repoName}" ]; then
        eval "${NGINX_CMD[$repoName]}" || exit
    # update existing repos
    else
        pushd "${repoName}" || exit

        git submodule foreach git pull
        git fetch && git reset --hard "@{upstream}"

        popd || exit
    fi
done

# check openssl
if [ ! -d "openssl" ]; then
    echo
    echo Directory "openssl" not found...
    echo Please download it manually from "https://www.openssl.org/source/"
    echo Unzip it and rename/link the directory to "openssl" here.
    exit
fi

# check jemalloc
if hash jemalloc-config 2>/dev/null; then
    NGINX_FLAGS+=( "--with-ld-opt='-ljemalloc'" )
fi

echo "==================================="
echo "Begin compile nginx ..."
echo "==================================="

pushd nginx || exit

./auto/configure --user=www --group=www --prefix=/usr/local/nginx --with-http_stub_status_module --with-http_ssl_module --with-http_gzip_static_module --with-http_realip_module --with-http_v2_module --with-http_flv_module --with-openssl="${SCIPRT_DIR}/openssl" --add-module="${SCIPRT_DIR}/ngx_http_concat" --add-module="${SCIPRT_DIR}/ngx_http_trim" ${NGINX_FLAGS[@]}

make -j "${THREAD_CNT}" && make install

# clean up
make clean
git clean -df

popd || exit

echo "==================================="
echo "End compile nginx ..."
echo "==================================="

popd || exit

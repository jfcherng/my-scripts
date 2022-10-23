#!/usr/bin/env bash

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
THREAD_CNT=$(getconf _NPROCESSORS_ONLN)
PREFIX=${PREFIX:-${HOME}/opt}

export LD_LIBRARY_PATH="${HOME}/opt/lib:${LD_LIBRARY_PATH}"
export PATH="${PREFIX}/bin:${PATH}"

gpgconf --kill dirmngr
gpgconf --kill gpg-agent

pushd "${SCRIPT_DIR}" || exit

mkdir -p _tmp

pushd _tmp || exit

wget -c https://www.gnupg.org/ftp/gcrypt/libgpg-error/libgpg-error-1.46.tar.gz
wget -c https://www.gnupg.org/ftp/gcrypt/libgcrypt/libgcrypt-1.10.1.tar.gz
wget -c https://www.gnupg.org/ftp/gcrypt/libassuan/libassuan-2.5.5.tar.bz2
wget -c https://www.gnupg.org/ftp/gcrypt/libksba/libksba-1.6.2.tar.bz2
wget -c https://www.gnupg.org/ftp/gcrypt/npth/npth-1.6.tar.bz2
wget -c https://www.gnupg.org/ftp/gcrypt/ntbtls/ntbtls-0.3.1.tar.bz2
wget -c https://www.gnupg.org/ftp/gcrypt/pinentry/pinentry-1.2.1.tar.bz2
wget -c https://www.gnupg.org/ftp/gcrypt/gnupg/gnupg-2.3.8.tar.bz2

tar -xzf libgpg-error-1.46.tar.gz
tar -xzf libgcrypt-1.10.1.tar.gz
tar -xjf libassuan-2.5.5.tar.bz2
tar -xjf libksba-1.6.2.tar.bz2
tar -xjf npth-1.6.tar.bz2
tar -xjf ntbtls-0.3.1.tar.bz2
tar -xjf pinentry-1.2.1.tar.bz2
tar -xjf gnupg-2.3.8.tar.bz2

(
    cd "libgpg-error-1.46" || exit
    ./configure --prefix="${PREFIX}" &&
        make -j"${THREAD_CNT}" &&
        make -j"${THREAD_CNT}" install
)
(
    cd "libgcrypt-1.10.1" || exit
    ./configure --prefix="${PREFIX}" &&
        make -j"${THREAD_CNT}" &&
        make -j"${THREAD_CNT}" install
)
(
    cd "libassuan-2.5.5" || exit
    ./configure --prefix="${PREFIX}" &&
        make -j"${THREAD_CNT}" &&
        make -j"${THREAD_CNT}" install
)
(
    cd "libksba-1.6.2" || exit
    ./configure --prefix="${PREFIX}" &&
        make -j"${THREAD_CNT}" &&
        make -j"${THREAD_CNT}" install
)
(
    cd "npth-1.6" || exit
    ./configure --prefix="${PREFIX}" &&
        make -j"${THREAD_CNT}" &&
        make -j"${THREAD_CNT}" install
)
(
    cd "ntbtls-0.3.1" || exit
    ./configure --prefix="${PREFIX}" &&
        make -j"${THREAD_CNT}" &&
        make -j"${THREAD_CNT}" install
)
(
    cd "pinentry-1.2.1" || exit
    ./configure --prefix="${PREFIX}" &&
        make -j"${THREAD_CNT}" &&
        make -j"${THREAD_CNT}" install
)
(
    cd "gnupg-2.3.8" || exit
    # This script is aken from https://gitlab.com/goeb/gnupg-static
    # Fix build failure ("undefined reference to `ks_ldap_free_state'" in
    # dirmngr/server.c). The source of this patch is the LFS project page at
    # <https://www.linuxfromscratch.org/blfs/view/svn/postlfs/gnupg.html>:
    sed \
        -e '/ks_ldap_free_state/i #if USE_LDAP' \
        -e '/ks_get_state =/a #endif' \
        -i "dirmngr/server.c"
    ./configure --prefix="${PREFIX}" &&
        make -j"${THREAD_CNT}" &&
        make -j"${THREAD_CNT}" install
)

popd || exit

rm -rf _tmp

echo "[INFO] Done."
echo "[INFO] Please add \"${PREFIX}/lib\" to your LD_LIBRARY_PATH."
echo "[INFO] Please add \"${PREFIX}/bin\" to your PATH."

popd || exit

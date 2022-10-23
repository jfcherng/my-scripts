#!/usr/bin/env bash

# This script is modified from https://gitlab.com/goeb/gnupg-static
# Usage: "$0" <prefix>
#
#     With <prefix> being the directory the static GPG distribution will
#     eventually be installed to (by you, not by this script). All built files
#     will be placed in the dst/ directory.

set   -o errexit
set   -o nounset

# shopt -s localvar_unset
# shopt -s shift_verbose
# shopt -u sourcepath

SKIP_DOWNLOAD_VERIFY=${SKIP_DOWNLOAD_VERIFY:-true}

v_musl_libc=1.2.3          # https://musl.libc.org/
v_libsqlite=3400000        # https://www.sqlite.org/download.html
v_zlib_zlib=1.2.13         # https://zlib.net/

v_gpg_lnpth=1.6            # https://gnupg.org/download/index.html
v_gpg_error=1.46
v_gpg_lassn=2.5.5
v_gpg_gcrpt=1.10.1
v_gpg_lksba=1.6.2
v_gpg_n_tls=0.3.1
v_gpg_gnupg=2.3.8
v_gpg_pntry=1.2.1

n_processes=$(getconf _NPROCESSORS_ONLN)

gpg_baseurl='https://gnupg.org/ftp/gcrypt'

all_dl_urls=(
   "https://musl.libc.org/releases/musl-${v_musl_libc}.tar.gz"{,.asc}
   "https://www.sqlite.org/2022/sqlite-autoconf-${v_libsqlite}.tar.gz"
   "https://zlib.net/zlib-${v_zlib_zlib}.tar.gz"{,.asc}
   "${gpg_baseurl}/npth/npth-${v_gpg_lnpth}.tar.bz2"{,.sig}
   "${gpg_baseurl}/libgpg-error/libgpg-error-${v_gpg_error}.tar.bz2"{,.sig}
   "${gpg_baseurl}/libassuan/libassuan-${v_gpg_lassn}.tar.bz2"{,.sig}
   "${gpg_baseurl}/libgcrypt/libgcrypt-${v_gpg_gcrpt}.tar.bz2"{,.sig}
   "${gpg_baseurl}/libksba/libksba-${v_gpg_lksba}.tar.bz2"{,.sig}
   "${gpg_baseurl}/ntbtls/ntbtls-${v_gpg_n_tls}.tar.bz2"{,.sig}
   "${gpg_baseurl}/gnupg/gnupg-${v_gpg_gnupg}.tar.bz2"{,.sig}
   "${gpg_baseurl}/pinentry/pinentry-${v_gpg_pntry}.tar.bz2"{,.sig}
)

import_keys=(
   '02F38DFF731FF97CB039A1DA549E695E905BA208'
   '5ED46A6721D365587791E2AA783FCD8E58BCAFBA'
   '6DAA6E64A76D2840571B4902528897B826403ADA'
   '836489290BB6B70F99FFDA0556BCDB593020450F'
   'AC8E115BF73E2D8D47FA9908E98E9B2D19C6C8BD'
   'D8692123C4065DEA5E0F3AB5249B39D24F25E3B6'
)

src="$( pwd )/src"
pfx="$( pwd )/pfx"
tmp="$( pwd )/tmp"

if [[ -z "${1:-}" ]] ; then
   printf 'Usage: %s <prefix>\n' "$0" >&2
   exit 1
fi

DST="$( pwd )/dst"
PFX="${1}"

export PATH="${pfx}/bin:${PATH}"

# create directories: ########################################################
#
mkdir -p "${src}" "${pfx}" "${tmp}" "${DST}"

# download all sources and signatures: #######################################
#
(
   cd tmp/
   curl -L --remote-name-all "${all_dl_urls[@]}"
)

# check signatures: ##########################################################
#
# disabled by short circuit...
[[ ${SKIP_DOWNLOAD_VERIFY} == "true" ]] || (
   # shellcheck disable=SC2174
   mkdir -m 0700 -p gpg/

   GNUPGHOME="$( pwd )/gpg/"
   export GNUPGHOME

   for k in "${import_keys[@]}" ; do
      case "${k}" in
         https://*) curl -L "${k}" | gpg --import - ;;
                 *) gpg --recv-keys "${k}"          ;;
      esac
   done

   cd tmp/

   gpg --verify "musl-${v_musl_libc}.tar.gz"{.asc,}
   gpg --verify "zlib-${v_zlib_zlib}.tar.gz"{.asc,}

   gpg --verify "npth-${v_gpg_lnpth}.tar.bz2"{.sig,}
   gpg --verify "libgpg-error-${v_gpg_error}.tar.bz2"{.sig,}
   gpg --verify "libassuan-${v_gpg_lassn}.tar.bz2"{.sig,}
   gpg --verify "libgcrypt-${v_gpg_gcrpt}.tar.bz2"{.sig,}
   gpg --verify "libksba-${v_gpg_lksba}.tar.bz2"{.sig,}
   gpg --verify "ntbtls-${v_gpg_n_tls}.tar.bz2"{.sig,}
   gpg --verify "pinentry-${v_gpg_pntry}.tar.bz2"{.sig,}
   gpg --verify "gnupg-${v_gpg_gnupg}.tar.bz2"{.sig,}

   gpgconf --kill dirmngr
   gpgconf --kill gpg-agent

   # Note: SQLite doesn't provide a signature, only a SHA3 checksum.
   #
   if command -v sha3sum >/dev/null 2>&1 ; then
      sqlite_file=''
      for url in "${all_dl_urls[@]}" ; do
         # shellcheck disable=SC2249
         case "${url}" in
            *sqlite*) sqlite_file=$( basename "${url}" ) ; break ;;
         esac
      done
      if [[ -z "${sqlite_file}" ]] ; then
         exit 1
      fi
      sha3=$(
         curl https://sqlite.org/download.html 2>/dev/null | \
            awk -F, "/^PRODUCT,.*\/${sqlite_file},/{print\$5}"
      )
      sha3sum -a 256 -c - <<<"${sha3} ${sqlite_file}" >/dev/null
   fi
)

# build musl-gcc: ############################################################
#
(
   cd src/
   tar -xzf "../tmp/musl-${v_musl_libc}.tar.gz"
   mkdir -p musl/ && cd musl/
   "../musl-${v_musl_libc}/configure"  \
      --prefix="${pfx}"                \
      --enable-wrapper=gcc             \
      --syslibdir="${pfx}/lib"
   make -j"${n_processes}"
   make install
)

export GCC="${pfx}/bin/musl-gcc"
export CC="${pfx}/bin/musl-gcc"

# build sqlite: ##############################################################
#
(
   cd src/
   tar -xzf "../tmp/sqlite-autoconf-${v_libsqlite}.tar.gz"
   mkdir -p sqlite/ && cd sqlite/
   "../sqlite-autoconf-${v_libsqlite}/configure" CC="${GCC}"   \
      --prefix="${pfx}"                                        \
      --enable-shared=no                                       \
      --enable-static=yes
   make -j"${n_processes}"
   make install
)

# build zlib: ################################################################
#
(
   cd src/
   tar -xzf "../tmp/zlib-${v_zlib_zlib}.tar.gz"
   mkdir -p zlib/ && cd zlib/
   "../zlib-${v_zlib_zlib}/configure"  \
      --prefix="${pfx}"                \
      --static
   make -j"${n_processes}"
   make install
)

# build npth: ################################################################
#
(
   cd src/
   tar -xjf "../tmp/npth-${v_gpg_lnpth}.tar.bz2"
   mkdir -p npth/ && cd npth/
   "../npth-${v_gpg_lnpth}/configure" CC="${GCC}"  \
      --prefix="${pfx}"                            \
      --enable-shared=no                           \
      --enable-static=yes
   make -j"${n_processes}"
   make install
)

# build libgpg-error: ########################################################
#
(
   cd src/
   tar -xjf "../tmp/libgpg-error-${v_gpg_error}.tar.bz2"
   mkdir -p libgpg-error/ && cd libgpg-error/
   "../libgpg-error-${v_gpg_error}/configure" CC="${GCC}"   \
      --prefix="${pfx}"                                     \
      --enable-shared=no                                    \
      --enable-static=yes                                   \
      --disable-nls                                         \
      --disable-languages                                   \
      --disable-doc
   make -j"${n_processes}"
   make install
   # This is required by following builds but not copied for some reason:
   cp src/gpg-error-config "${pfx}/bin/"
)

# build libassuan: ###########################################################
#
(
   cd src/
   tar -xjf "../tmp/libassuan-${v_gpg_lassn}.tar.bz2"
   mkdir -p libassuan/ && cd libassuan/
   "../libassuan-${v_gpg_lassn}/configure" CC="${GCC}"   \
      --prefix="${pfx}"                                  \
      --enable-shared=no                                 \
      --enable-static=yes                                \
      --disable-doc                                      \
      --with-libgpg-error-prefix="${pfx}"
   make -j"${n_processes}"
   make install
)

# build libgcrypt: ###########################################################
#
(
   cd src/
   tar -xjf "../tmp/libgcrypt-${v_gpg_gcrpt}.tar.bz2"
   mkdir -p libgcrypt/ && cd libgcrypt/
   "../libgcrypt-${v_gpg_gcrpt}/configure" CC="${GCC}"   \
      --prefix="${pfx}"                                  \
      --enable-shared=no                                 \
      --enable-static=yes                                \
      --disable-padlock-support                          \
      --disable-ppc-crypto-support                       \
      --disable-doc                                      \
      --with-libgpg-error-prefix="${pfx}"
   make -j"${n_processes}"
   make install
)

# build libksba: #############################################################
#
(
   cd src/
   tar -xjf "../tmp/libksba-${v_gpg_lksba}.tar.bz2"
   mkdir -p libksba/ && cd libksba/
   "../libksba-${v_gpg_lksba}/configure" CC="${GCC}"  \
      --prefix="${pfx}"                               \
      --enable-shared=no                              \
      --enable-static=yes                             \
      --with-libgpg-error-prefix="${pfx}"
   make -j"${n_processes}"
   make install
)

# build ntbtls: ##############################################################
#
(
   cd src/
   tar -xjf "../tmp/ntbtls-${v_gpg_n_tls}.tar.bz2"
   mkdir -p ntbtls/ && cd ntbtls/
   "../ntbtls-${v_gpg_n_tls}/configure" CC="${GCC}"   \
      --prefix="${pfx}"                               \
      --enable-shared=no                              \
      --enable-static=yes                             \
      --with-libgpg-error-prefix="${pfx}"             \
      --with-libgcrypt-prefix="${pfx}"                \
      --with-libksba-prefix="${pfx}"                  \
      --with-zlib="${pfx}"
   make -j"${n_processes}"
   make install
)

# build gnupg: ###############################################################
#
(
   cd src/
   tar -xjf "../tmp/gnupg-${v_gpg_gnupg}.tar.bz2"
   # Fix build failure ("undefined reference to `ks_ldap_free_state'" in
   # dirmngr/server.c). The source of this patch is the LFS project page at
   # <https://www.linuxfromscratch.org/blfs/view/svn/postlfs/gnupg.html>:
   sed                                             \
      -e '/ks_ldap_free_state/i #if USE_LDAP'      \
      -e '/ks_get_state =/a #endif'                \
      -i "gnupg-${v_gpg_gnupg}/dirmngr/server.c"
   mkdir -p gnupg/ && cd gnupg/
   "../gnupg-${v_gpg_gnupg}/configure" CC="${GCC}" LDFLAGS='-static -s' \
      --prefix="${PFX}"                                                 \
      --enable-tofu                                                     \
      --disable-scdaemon                                                \
      --disable-keyboxd                                                 \
      --disable-tpm2d                                                   \
      --disable-doc                                                     \
      --disable-gpgtar                                                  \
      --disable-wks-tools                                               \
      --disable-libdns                                                  \
      --disable-gpg-idea                                                \
      --disable-gpg-cast5                                               \
      --disable-gpg-blowfish                                            \
      --disable-gpg-twofish                                             \
      --disable-gpg-md5                                                 \
      --disable-gpg-rmd160                                              \
      --enable-zip                                                      \
      --disable-bzip2                                                   \
      --disable-photo-viewers                                           \
      --disable-card-support                                            \
      --disable-ccid-driver                                             \
      --enable-sqlite                                                   \
      --disable-dirmngr-auto-start                                      \
      --disable-gnutls                                                  \
      --disable-ldap                                                    \
      --disable-nls                                                     \
      --with-agent-pgm="${PFX}/bin/gpg-agent"                           \
      --with-pinentry-pgm="${PFX}/bin/pinentry"                         \
      --with-libgpg-error-prefix="${pfx}"                               \
      --with-libgcrypt-prefix="${pfx}"                                  \
      --with-libassuan-prefix="${pfx}"                                  \
      --with-libksba-prefix="${pfx}"                                    \
      --with-npth-prefix="${pfx}"                                       \
      --with-ntbtls-prefix="${pfx}"                                     \
      --with-zlib="${pfx}"
   make -j"${n_processes}"
   make install DESTDIR="${DST}"
)

# build pinentry: ############################################################
#
(
   cd src/
   tar -xjf "../tmp/pinentry-${v_gpg_pntry}.tar.bz2"
   mkdir -p pinentry/ && cd pinentry/
   "../pinentry-${v_gpg_pntry}/configure" CC="${GCC}" LDFLAGS='-static -s' \
      --prefix="${PFX}"                                                    \
      --enable-pinentry-tty                                                \
      --disable-ncurses                                                    \
      --disable-pinentry-qt5                                               \
      --disable-doc                                                        \
      --disable-libsecret                                                  \
      --disable-pinentry-curses                                            \
      --disable-pinentry-emacs                                             \
      --disable-inside-emacs                                               \
      --disable-pinentry-gtk2                                              \
      --disable-pinentry-gnome3                                            \
      --disable-pinentry-qt                                                \
      --disable-pinentry-tqt                                               \
      --disable-pinentry-fltk                                              \
      --with-libgpg-error-prefix="${pfx}"                                  \
      --with-libassuan-prefix="${pfx}"
   make -j"${n_processes}"
   make install DESTDIR="${DST}"
)


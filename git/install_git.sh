#!/usr/bin/env bash

thread_count_default=$(nproc --all)

if [ "$(id -u)" != "0" ]; then
    is_root=false
else
    is_root=true
fi


echo "========================================================================="
if [ "${is_root}" = true ]; then
    echo "[INFO] You are 'root'!!!"
    git_install_prefix=/usr/local
else
    echo "[INFO] You are not 'root'..."
    git_install_prefix=$HOME/opt
fi
echo "This script will install git to '${git_install_prefix}'."
echo "Author: Jack Cherng <jfcherng@gmail.com>"
echo "========================================================================="


git_ver_old=$("${git_install_prefix}/bin/git" --version | cut -d ' ' -f 3)
if [ "${git_ver_old}" = "" ]; then
    git_ver_old="None"
fi
echo "Current git Version: ${git_ver_old}"
echo "You can find version number from 'https://github.com/git/git/releases'"
echo "Note: the latest build may not work properly!"

# input version
read -rp "What's the git version you want to install? (For example, '2.14.1' or 'latest'): " git_ver_new
if [ "${git_ver_new}" = "" ]; then
    echo "[Error] No git version is given."
    exit 1
fi

# input thread counts
read -rp "Parallel compilation with thread counts (default = ${thread_count_default}): " thread_count
if [ "${thread_count}" = "" ]; then
    thread_count=${thread_count_default}
fi

echo ""
echo "You want to install git to '${git_ver_new}'."
echo "Press any key to start or Ctrl+C to cancel."
read -rn 1 # wait for a key press


git_archive="git-${git_ver_new}.tar.gz"
echo ""
echo "===================== Download Package: Start ==========================="
rm -rf "git-${git_ver_new}"* # remove old sources
if [ "${git_ver_new}" = "latest" ]; then
    wget --no-check-certificate -O "${git_archive}" "https://github.com/git/git/archive/master.tar.gz"
else
    wget --no-check-certificate -O "${git_archive}" "https://github.com/git/git/archive/v${git_ver_new}.tar.gz"
fi
if [ $? -eq 0 ]; then
    echo "Download '${git_archive}' successfully!"
else
    echo "[Error] Maybe the git version you input was wrong, please check!"
    echo "The git version you just input was: ${git_ver_new}"
    exit 1
fi
echo "===================== Download Package: End ============================="


if [ "${is_root}" = true ]; then
echo ""
echo "You are a ROOT, let's install dependencies..."
echo "=================== Install dependencies: Start ========================="
    # if there is `yum`, install dependencies
    if command -v yum >/dev/null 2>&1; then
        yum install -y autoconf curl curl-devel zlib-devel openssl-devel perl perl-devel cpio expat-devel gettext-devel unzip gcc autoconf
    # if there is `apt`, install dependencies
    elif command -v apt >/dev/null 2>&1; then
        apt update
        apt install -y autoconf build-essential gettext libcurl4-gnutls-dev libexpat1-dev libnl-dev libnl1 libreadline6-dev libssl-dev libssl-dev zlib1g-dev
    else
        echo "Did not find 'yum' or 'apt'..."
    fi
echo "=================== Install dependencies: End ==========================="
fi


git_source_dir_name="git-${git_ver_new}"
echo ""
echo "===================== Extract Package: Start ==========================="
tar xvf "${git_archive}"
if [ "${git_ver_new}" = "latest" ]; then
    # correct the source dir name
    mv git-master "${git_source_dir_name}"
fi
echo "===================== Extract Package: End ============================="


echo ""
echo "===================== Install Package: Start ==========================="
mkdir -p "${git_install_prefix}"
cd "${git_source_dir_name}" || exit
# if there is autoconf, we use it
if command -v autoconf >/dev/null 2>&1; then
    autoconf
    ./configure --prefix="${git_install_prefix}"
fi
make -j${thread_count} all #CFLAGS="-liconv"
make -j${thread_count} install #CFLAGS="-liconv"

# error during compilation?
if [ $? -ne 0 ]; then
    exit 1
fi

# compile modules
git_modules=(subtree)
for git_module in "${git_modules[@]}"
do
    cd "contrib/${git_module}" || exit
    make -j${thread_count}
    make -j${thread_count} prefix="${git_install_prefix}" install
    cd -
done

cd .. || exit
echo "===================== Install Package: End ============================="


git_ver_new=$("${git_install_prefix}/bin/git" --version | cut -d ' ' -f 3)
if [ "${git_ver_new}" = "" ]; then
    git_ver_new="None"
fi


echo ""
echo "========================================================================="
echo "You have successfully installed/upgraded from '${git_ver_old}' to '${git_ver_new}'"
echo "You may have to add '${git_install_prefix}/bin' to your PATH"
echo "========================================================================="
echo ""


# remove sources
rm -f "${git_archive}"*
rm -rf "${git_source_dir_name}"

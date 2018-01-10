#!/usr/bin/env bash

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"


#---------#
# configs #
#---------#

package_src_dir=".Sublime-Official-Packages"
package_tmp_dir=".Sublime-Official-Packages_tmp"
package_remote_repo="https://github.com/sublimehq/Packages.git"

st_search_dirs=(
    # Windows
    "C:/Program Files/Sublime Text 3"
    # Linux
    "/opt/sublime_text"
    # Mac
    "/Applications/Sublime Text.app/Contents/MacOS"
)


#-------#
# begin #
#-------#

pushd "${SCRIPT_DIR}" || exit


#-------------------------------------------#
# try to find the ST installation directory #
#-------------------------------------------#

st_packages_dir=""

for st_search_dir in "${st_search_dirs[@]}"; do
    _st_packages_dir="${st_search_dir}/Packages"
    if [ -d "${_st_packages_dir}" ]; then
        echo "[INFO] Found ST installation directory: '${_st_packages_dir}'"
        st_packages_dir="${_st_packages_dir}"
        break
    else
        echo "[INFO] NOT found ST installation directory: '${_st_packages_dir}'"
    fi
done

if [ "${st_packages_dir}" = "" ]; then
    echo "[ERROR] Cannot find the ST installation directory..."
    exit 1
fi


#-------------------------------#
# get the latest package source #
#-------------------------------#

rm -rf "${package_src_dir}"
git clone --depth=1 "${package_remote_repo}" "${package_src_dir}"


#------------------#
# pack up packages #
#------------------#

rm -rf "${package_tmp_dir}"
mkdir -p "${package_tmp_dir}"

pushd "${package_src_dir}" || exit

# traverse all packages
for dir in */; do
    # strip the trailing slash in dir name
    dir=${dir//\/}
    pushd "${dir}" || exit

    # the package name is the dir name
    zip -9r "../../${package_tmp_dir}/${dir}.sublime-package" ./*

    popd || exit
done

popd || exit

rm -rf "${package_src_dir}"


#------------------#
# replace packages #
#------------------#

echo "Update ST packages..."
mv -f "${package_tmp_dir}"/*.sublime-package "${st_packages_dir}"

echo "Clean up..."
rm -rf "${package_tmp_dir}"


#-----#
# end #
#-----#

popd || exit

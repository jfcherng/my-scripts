#!/usr/bin/env bash

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"


#---------#
# configs #
#---------#

TEMP_DIR=".Sublime-Official-Packages"
PKG_GITHUB_URL="https://github.com/sublimehq/Packages"
PKG_REMOTE_REPO="${PKG_GITHUB_URL}.git"

ST_INSTALL_DIRS=(
    # this script's dir and its parent
    "${SCRIPT_DIR}"
    "${SCRIPT_DIR}/.."
    # Windows
    "C:/Program Files/Sublime Text"
    "C:/Program Files/Sublime Text 3"
    # Linux
    "/opt/sublime_text"
    "/opt/sublime_text_3"
    # Mac
    "/Applications/Sublime Text.app/Contents/MacOS"
    "/Applications/Sublime Text 3.app/Contents/MacOS"
)


#-----------#
# functions #
#-----------#

pushd() {
    # suppress messages from pushd, which is usually verbose
    command pushd "$@" > /dev/null
}

popd() {
    # suppress messages from popd, which is usually verbose
    command popd > /dev/null
}

clone_repo_ref() {
    local repo_dir="$1"
    local commit_ref="$2"

    rm -rf "${repo_dir}" && mkdir -p "${repo_dir}"
    pushd "${repo_dir}" || exit

    # @see https://stackoverflow.com/questions/3489173
    git init
    git remote add origin "${PKG_REMOTE_REPO}"
    git fetch --depth=1 origin "${commit_ref}"
    git reset --hard FETCH_HEAD
    local retcode="$?"

    popd || exit

    return "${retcode}"
}


#-------#
# begin #
#-------#

pushd "${SCRIPT_DIR}" || exit

rm -rf "${TEMP_DIR}" && mkdir -p "${TEMP_DIR}"

pushd "${TEMP_DIR}" || exit


#-------------------------------------------#
# try to find the ST installation directory #
#-------------------------------------------#

paths_to_check=(
    "Packages/"
    "changelog.txt"
)

for st_install_dir in "${ST_INSTALL_DIRS[@]}"; do
    st_install_dir="${st_install_dir%/}"

    is_passed=1
    for path_to_check in "${paths_to_check[@]}"; do
        path_to_check="${st_install_dir}/${path_to_check}"

        # if the path under checking is a dir, it ends with a slash
        if [[ "${path_to_check}" =~ /$ ]]; then
            if [ ! -d "${path_to_check}" ]; then
                is_passed=0
                break
            fi
        else
            if [ ! -f "${path_to_check}" ]; then
                is_passed=0
                break
            fi
        fi
    done

    if [ "${is_passed}" = "1" ]; then
        echo "[✔️] Found ST installation directory: '${st_install_dir}'"
        break
    else
        st_install_dir=""
    fi
done

if [ "${st_install_dir}" = "" ]; then
    echo "[❌] Could not find ST installation directory..."
    exit 1
fi

st_pkgs_dir="${st_install_dir}/Packages"


#-------------------------#
# read option: commit_ref #
#-------------------------#

echo "[💡] You can use either branch, tag or even SHA as the reference."
echo "[💡] You can check out references on '${PKG_GITHUB_URL}/commits'."
read -erp "[❓] Which reference you want to used (such as 'v4126', default = 'master'): " commit_ref

if [ "${commit_ref}" = "" ]; then
    commit_ref="master"
    echo "[⚠️] Use default '${commit_ref}' as the reference."
fi


#-------------------------------#
# get the latest package source #
#-------------------------------#

repo_dir="repo"

echo "[💬] Downloading repository..."

if clone_repo_ref "${repo_dir}" "${commit_ref}"; then
    echo "[✔️] Download repository successfully!"
else
    echo "[❌] Fail to checkout reference '${commit_ref}'."
    exit 1
fi


#------------------#
# pack up packages #
#------------------#

packed_pkgs_dir="packages"

mkdir -p "${packed_pkgs_dir}"

pushd "${repo_dir}" || exit

echo "[💬] Pack up packages..."

# traverse all packages in the repo
for dir in */; do
    pushd "${dir}" || exit

    pkg_name=${dir%/}

    echo "[📦] Packaging '${pkg_name}'..."

    zip -9rq "../../${packed_pkgs_dir}/${pkg_name}.sublime-package" .

    popd || exit
done

popd || exit


#------------------#
# replace packages #
#------------------#

echo "[💬] Update ST packages to '${commit_ref}'..."
cp -rf "${packed_pkgs_dir}"/*.sublime-package "${st_pkgs_dir}"


#----------#
# clean up #
#----------#

popd || exit

echo "[💬] Clean up..."
rm -rf "${TEMP_DIR}"


#-----#
# end #
#-----#

popd || exit

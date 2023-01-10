#!/usr/bin/env bash

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

ST_LSP_PACKAGE_PATH="${APPDATA}\Sublime Text\Installed Packages\LSP.sublime-package"
INTERESTED_REF="main"

pushd "${SCRIPT_DIR}" || exit

if [[ ! -d "LSP/.git" ]]; then
    rm -rf "LSP/"
    git clone "https://github.com/sublimelsp/LSP.git"
fi

pushd "${SCRIPT_DIR}/LSP" || exit

git checkout -f "${INTERESTED_REF}" || exit 1
git clean -dfx

# fetch latest source
git fetch --tags --force --prune --all || exit 1
git reset --hard "@{upstream}" || exit 1

# create package
git archive HEAD -o out.zip
7za x -aoa "${ST_LSP_PACKAGE_PATH}" "package-metadata.json"
7za a -aoa out.zip "package-metadata.json"

# replace ST's package
mv -f out.zip "${ST_LSP_PACKAGE_PATH}"

git checkout -f - || exit 1
git clean -dfx

popd || exit

popd || exit

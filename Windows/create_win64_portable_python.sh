#!/usr/bin/env bash

# This script creates a Win64 portable Python environment.
# Pre-installed packages: certifi, pip, setuptools, wheel

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)

pushd "${SCRIPT_DIR}" || exit 1

PY_PIP_DL_URL="https://bootstrap.pypa.io/get-pip.py"

# ask user to input Python version
echo '[INFO] Visit "https://www.python.org/downloads/windows/" to find available Python versions.'
read -rp "Enter wanted Python version (e.g. 3.12.0rc1): " PY_FULL_VER

PY_FULL_VER="${PY_FULL_VER// /}"
# legal form: 3.12.0, 3.12.0a1, 3.12.0b1, 3.12.0rc1
if ! [[ ${PY_FULL_VER} =~ ^[0-9]+\.[0-9]+\.[0-9]+(([ab]|rc)[0-9]+)?$ ]]; then
    echo "[ERROR] Invalid Python version." && exit 1
fi

[[ ${PY_FULL_VER} =~ ^([0-9]+\.[0-9]+) ]] &&
    PYTHON_JOINED_BASE_VER=${BASH_REMATCH[1]//./} # e.g., 312
[[ ${PY_FULL_VER} =~ ^([0-9]+\.[0-9]+\.[0-9]+) ]] &&
    PY_BASE_VER=${BASH_REMATCH[1]} # e.g., 3.12.0

PY_ZIP_BASRNAME="python-${PY_FULL_VER}-embed-amd64"
PY_ZIP_DL_URL="https://www.python.org/ftp/python/${PY_BASE_VER}/${PY_ZIP_BASRNAME}.zip"

wget "${PY_ZIP_DL_URL}" -O "${PY_ZIP_BASRNAME}.zip" || exit 1 &&
    unzip "${PY_ZIP_BASRNAME}.zip" -d "${PY_ZIP_BASRNAME}" &&
    rm -f "${PY_ZIP_BASRNAME}.zip"

pushd "${PY_ZIP_BASRNAME}" || exit 1

# add installed packages path
sed -i'' -E "s/^#[ \t]*(import site)/\1/g" "python${PYTHON_JOINED_BASE_VER}._pth" || exit 1

wget "${PY_PIP_DL_URL}" -qO- | ./python &&
    ./python -m pip install -U certifi

popd || exit 1

7za a "${PY_ZIP_BASRNAME}.7z" "${PY_ZIP_BASRNAME}" -mx9 -xr'!__pycache__' &&
    rm -rf "${PY_ZIP_BASRNAME}"

popd || exit 1

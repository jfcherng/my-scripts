#!/usr/bin/env bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

pushd "${SCRIPT_DIR}" || exit

[[ ${UID} == "0" ]] || {
    echo "run as sudo to execute"
    exit 1
}

apt install -y curl jq

REPO="https://github.com/BurntSushi/ripgrep/releases/download/"
RG_LATEST=$(curl -sSL "https://api.github.com/repos/BurntSushi/ripgrep/releases/latest" | jq --raw-output .tag_name)
RELEASE="${RG_LATEST}/ripgrep-${RG_LATEST}-x86_64-unknown-linux-musl.tar.gz"

TMPDIR=$(mktemp -d)

pushd "${TMPDIR}" || exit

wget -O - "${REPO}${RELEASE}" | tar zxf - --strip-component=1
mv -f rg /usr/local/bin/
mv -f rg.1 /usr/local/share/man/man1/
mv -f complete/rg.bash-completion /usr/share/bash-completion/completions/rg
mandb

popd || exit

rm -rf "${TMPDIR}"

popd || exit

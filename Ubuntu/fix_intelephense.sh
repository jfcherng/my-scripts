#!/usr/bin/env bash

export FORCE_COLOR=0

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
NOW="$(date +%Y%m%d-%H%M%S)"

SUB_PATH="intelephense/lib/intelephense.js"

SERVER_BIN_LOCATIONS=(
    # the first argument
    "$1"
    # this script's directory
    "${SCRIPT_DIR}/$(basename "${SUB_PATH}")"
    "${SCRIPT_DIR}/node_modules/${SUB_PATH}"
    # ...
    "$(npm -g root 2>nul)/${SUB_PATH}"
    "$(yarn global dir 2>nul)/node_modules/${SUB_PATH}"
)

VERSION="1.0.1"
PATCHED_MARKER_DETECTION="/** FILE HAS BEEN PATCHED **/"
PATCHED_MARKER="${PATCHED_MARKER_DETECTION}/** ${VERSION} **/"

LICENSE_OBJECT_JS='{"message":{"timestamp":0,"machineId":"YOUR_MACHINE_ID","licenceKey":"YOUR_LICENCE_KEY","expiryTimestamp":99999999999,"resultCode":1},"signature":"THE_CALCULATED_SIGNATURE"}'

##
## @brief Change like "C:\Users\..." into "/C/Users/..."
##
## @param $1 The target path
##
function windows_path_fix {
    path="$1"

    path="/${path//\\//}"
    path="${path//:/}"

    # fix for Unix path
    path="${path//\/\///}"

    echo "${path}"
}

function patch_intelephense {
    intelephense_js="$1"

    # backup the source file
    file_backup="${intelephense_js}.bak"
    if [ ! -f "${file_backup}" ]; then
        cp "${intelephense_js}" "${file_backup}"
        echo "- Backup '${intelephense_js}' to '${file_backup}'"
    else
        echo "- Backup already exists: '${file_backup}'"
    fi

    search_replace_pairs=(
        # force convert licenceKey into a non-empty string even if it is undefined
        "s@(\.initializationOptions\.licenceKey)(?![;)\]}])@\1 + 'FOO_BAR'@g"
        "s@(\.initializationOptions\.licenceKey)(?=[;)\]}])@\1 = 'FOO_BAR'@g"
        # license always active
        "s@\b(activationResult\([^)]*\)[[:space:]]*\{)@\1return this._activationResult = ${LICENSE_OBJECT_JS};@g"
        "s@\b(readActivationResultFromCache\([^)]*\)[[:space:]]*\{)@\1return this.activationResult = ${LICENSE_OBJECT_JS};@g"
        # nullify potential telemetry
        "s@\b(intelephense\.com)@localhost@g"
    )

    # do patches
    for pair in "${search_replace_pairs[@]}"; do
        perl -pi.my_bak -e "${pair}" "${intelephense_js}"
    done
    rm -f "${intelephense_js}.my_bak"

    # add patched marker
    echo -e "\n\n${PATCHED_MARKER}" >>"${intelephense_js}"
}

for INTELEPHENSE_JS in "${SERVER_BIN_LOCATIONS[@]}"; do
    if [ "${INTELEPHENSE_JS}" = "" ]; then
        continue
    fi

    INTELEPHENSE_JS="$(windows_path_fix "${INTELEPHENSE_JS}")"

    echo "- Test file: ${INTELEPHENSE_JS}"

    if [ -f "${INTELEPHENSE_JS}" ]; then
        echo "- Target file: ${INTELEPHENSE_JS}"

        if grep -qF "${PATCHED_MARKER_DETECTION}" "${INTELEPHENSE_JS}"; then
            echo "- File seems to be patched already hence skipped."
            continue
        fi

        patch_intelephense "${INTELEPHENSE_JS}"

        echo "- Patch has been applied."

        break
    fi
done

echo
echo 'Done.'
echo

#!/usr/bin/env bash

# Here's an example of activation response from the intelephense server.
# {"statusCode":200,"data":{"message":{"timestamp":0,"machineId":"YOUR_MACHINE_ID","licenceKey":"YOUR_LICENCE_KEY","expiryTimestamp":999999999,"resultCode":1},"signature":"THE_CALCULATED_SIGNATURE"}}

export FORCE_COLOR=0

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

NODE_MODULES_LOCATIONS=(
    # This script's directory
    "${SCRIPT_DIR}"
    # ...
    "$(npm -g root)"
    "$(yarn global dir)/node_modules"
    "/usr/local/share/.config/yarn/global"
)

# array unique @see https://stackoverflow.com/questions/13648410
NODE_MODULES_LOCATIONS=($(printf "%s\n" "${NODE_MODULES_LOCATIONS[@]}" | sort -u))

PATCHED_MARKER="// [PATCHED] Intelephense"

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

    sed -i"" \
        $(: license always active ) \
        -e "s@\bisActive()[[:space:]]*{@\0 return 1;@g" \
        $(: enable all capabilities ) \
        -e "s@\bdocumentFormattingProvider:@\0 1 ||@g" \
        -e "s@\bdocumentRangeFormattingProvider:@\0 1 ||@g" \
        -e "s@\bfoldingRangeProvider:@\0 1 ||@g" \
        -e "s@\bimplementationProvider:@\0 1 ||@g" \
        -e "s@\bdeclarationProvider:@\0 1 ||@g" \
        -e "s@\brenameProvider:@\0 1 ||@g" \
        -e "s@\btypeDefinitionProvider:@\0 1 ||@g" \
        $(: nullify telemetry ) \
        -e "s@\bintelephense\.com@example.com@g" \
        "${intelephense_js}"

    # add patched marker
    echo -e "\n${PATCHED_MARKER}" >> "${intelephense_js}"
}

for NODE_MODULES in "${NODE_MODULES_LOCATIONS[@]}"; do
    NODE_MODULES="$(windows_path_fix "${NODE_MODULES}")"

    echo "Test node_modules directory: ${NODE_MODULES}"

    INTELEPHENSE_JS="${NODE_MODULES}/intelephense/lib/intelephense.js"

    if [ -f "${INTELEPHENSE_JS}" ]; then
        echo "- Target file: ${INTELEPHENSE_JS}"

        if grep -qF "${PATCHED_MARKER}" "${INTELEPHENSE_JS}"; then
            echo "- File seems to be patched already hence skipped."
            continue
        fi

        patch_intelephense "${INTELEPHENSE_JS}"

        echo "- Patch has been applied."
    fi
done

echo
echo 'Done. You may have to fill "licenceKey" with arbitrary text.'
echo

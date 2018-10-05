#!/usr/bin/env bash

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

PYTHON3_EXECUTABLE="python3"

case "$(uname -s)" in
    Darwin|Linux)
        SM_EXECUTABLE_FALLBACK="/opt/sublime_merge/sublime_merge"

        # try to find system sublime_merge executable
        SM_EXECUTABLE_SYSTEM="$( \
            # get the "exec SUBLIME_EXECUTABLE $@" line
            command grep -o -m 1 -E "(^| )exec .*$" "$(command -v smerge)" | \
            # remove leading spaces
            awk '{$1=$1}1' | \
            # remove exec
            cut -d" " -f2- | \
            # get the maybe-quoted executable path
            sed -re 's/("[^"]*"|[^ ]+).*/\1/g' | \
            # remove quotes if any
            sed -re 's/"//g'
        )"
        ;;

    # Windows
    CYGWIN*|MINGW*|MSYS*)
        SM_EXECUTABLE_FALLBACK="C:/Program Files/Sublime Merge/sublime_merge.exe"
        SM_EXECUTABLE_SYSTEM=""
        ;;

    *)
        echo "Unknown OS..."
        exit 1
        ;;
esac

if [ -f "${SM_EXECUTABLE_SYSTEM}" ]; then
    SM_EXECUTABLE=${SM_EXECUTABLE_SYSTEM}
else
    SM_EXECUTABLE=${SM_EXECUTABLE_FALLBACK}
fi

echo "[Sublime Merge] Using executable: ${SM_EXECUTABLE}"


pushd "${SCRIPT_DIR}" || exit

# update remote repo
git submodule init
git submodule update --recursive --remote

# do patching
if command -v sudo >/dev/null 2>&1; then
    sudo "${PYTHON3_EXECUTABLE}" ./slm-patcher/slm.py "${SM_EXECUTABLE}"
else
    "${PYTHON3_EXECUTABLE}" ./slm-patcher/slm.py "${SM_EXECUTABLE}"
fi

popd || exit

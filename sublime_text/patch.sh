#!/usr/bin/env bash

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

PYTHON3_EXECUTABLE="python3"

case "$(uname -s)" in
    Darwin|Linux)
        ST_EXECUTABLE_FALLBACK="/opt/sublime_text/sublime_text"

        # try to find system sublime_text executable
        ST_EXECUTABLE_SYSTEM=\
            cat "$(which subl)" | \
            command grep -m 1 "^exec" | \
            cut -d" " -f2- | \
            awk -F '"' '{print $1}'
        ;;

    # Windows
    CYGWIN*|MINGW*|MSYS*)
        ST_EXECUTABLE_FALLBACK="C:/Program Files/Sublime Text 3/sublime_text.exe"
        ST_EXECUTABLE_SYSTEM=""
        ;;

    *)
        echo "Unknown OS..."
        exit 1
        ;;
esac

if [ -f "${ST_EXECUTABLE_SYSTEM}" ]; then
    ST_EXECUTABLE=${ST_EXECUTABLE_SYSTEM}
else
    ST_EXECUTABLE=${ST_EXECUTABLE_FALLBACK}
fi

echo "[Sublime Text] Using executable: ${ST_EXECUTABLE}"


pushd "${SCRIPT_DIR}" || exit

# update remote repo
git submodule init
git submodule update --recursive --remote

# do patching
if command -v sudo >/dev/null 2>&1; then
    sudo "${PYTHON3_EXECUTABLE}" ./slt-patcher/slt.py "${ST_EXECUTABLE}"
else
    "${PYTHON3_EXECUTABLE}" ./slt-patcher/slt.py "${ST_EXECUTABLE}"
fi

popd || exit

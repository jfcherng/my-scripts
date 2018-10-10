#!/usr/bin/env bash

ST_EXECUTABLE_FALLBACK="/opt/sublime_text/sublime_text"

# try to find system sublime_text executable
ST_EXECUTABLE_SYSTEM="$( \
    command grep -m 1 "^exec" "$(command -v subl)" | \
    cut -d" " -f2- | \
    awk -F '"' '{print $1}'
)"

if [ -f "${ST_EXECUTABLE_SYSTEM}" ]; then
    ST_EXECUTABLE=${ST_EXECUTABLE_SYSTEM}
else
    ST_EXECUTABLE=${ST_EXECUTABLE_FALLBACK}
fi

if [ "$(getconf LONG_BIT)" -eq "32" ];then
    OS_BIT=32
else
    OS_BIT=64
fi

ST_HOME="$(dirname "${ST_EXECUTABLE}")"

# install input method
# sudo apt-get install -y fcitx fcitx-im

# install necessary dependencies
sudo apt update
sudo apt install -y build-essential libgtk2.0-dev

# compile source codes
gcc -m"${OS_BIT}" -Os -shared -o "libsublime-imfix.so" "sublime_imfix.c" $(pkg-config --libs --cflags gtk+-2.0) -fPIC

# install patches
sudo mv -f "libsublime-imfix.so" "${ST_HOME}"
sudo cp -f "subl" "${ST_EXECUTABLE}"
sudo cp -f "sublime_text.desktop" "/usr/share/applications/"
sudo cp -f "sublime_text.desktop" "${ST_HOME}"

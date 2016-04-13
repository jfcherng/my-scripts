#!/usr/bin/env bash

SUBLIME_HOME="/opt/sublime_text"

# install input method
# apt-get install -y fcitx fcitx-im

# install necessary dependencies
apt-get update
apt-get install -y build-essential libgtk2.0-dev

# compile source codes
gcc -Os -shared -o libsublime-imfix.so sublime_imfix.c $(pkg-config --libs --cflags gtk+-2.0) -fPIC

# install patches
mv -f libsublime-imfix.so $SUBLIME_HOME
cp -f subl "$(which subl)"
cp -f sublime_text.desktop /usr/share/applications/
cp -f sublime_text.desktop $SUBLIME_HOME

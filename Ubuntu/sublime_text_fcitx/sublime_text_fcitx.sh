#!/usr/bin/env bash

SUBLIME_HOME="/opt/sublime_text"

# install input method
# apt-get install -y fcitx fcitx-im

# install necessary dependencies
sudo apt update
sudo apt install -y build-essential libgtk2.0-dev

# compile source codes
gcc -Os -shared -o libsublime-imfix.so sublime_imfix.c $(pkg-config --libs --cflags gtk+-2.0) -fPIC

# install patches
sudo mv -f libsublime-imfix.so $SUBLIME_HOME
sudo cp -f subl "$(which subl)"
sudo cp -f sublime_text.desktop /usr/share/applications/
sudo cp -f sublime_text.desktop $SUBLIME_HOME

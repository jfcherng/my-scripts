#!/bin/bash

# apt-get install -y fcitx fcitx-im

SUBLIME_HOME="/opt/sublime_text"

apt-get install -y build-essential libgtk2.0-dev
gcc -Os -shared -o libsublime-imfix.so sublime_imfix.c `pkg-config --libs --cflags gtk+-2.0` -fPIC
mv -f libsublime-imfix.so $SUBLIME_HOME
cp -f subl `which subl`
cp -f sublime_text.desktop /usr/share/applications/

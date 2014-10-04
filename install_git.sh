#!/bin/bash

if [ $(id -u) != "0" ]; then
     is_root=false
else
     is_root=true
fi

echo "========================================================================="
if [ "$is_root" = true ]; then
     echo "*** You are 'root'!!!"
     git_exe_dir=/usr/local/bin
else
     echo "*** You are not 'root'..."
     git_exe_dir=$HOME/opt/bin
fi
echo "This script will install/upgrade git to '$git_exe_dir'."
echo "Author: Jack Cherng <jfcherng@gmail.com>"
echo "========================================================================="

git_ver_old=$($git_exe_dir/git --version | cut -d ' ' -f 3)
if [ "$git_ver_old" = "" ]; then
     git_ver_old="None"
fi
echo "Current git Version: $git_ver_old"
echo "You can get version number from 'https://github.com/git/git/releases'"
echo "Please input the git version you want install/upgrade..."
echo "Note: the latest build may not work as usaully!"
read -p "For example, '2.1.0' or 'latest': " git_ver_new
if [ "$git_ver_new" = "" ]; then
     echo "*** Error: No git version is given."
     exit 1
fi

echo ""
echo "You want to install/upgrade git to '$git_ver_new'."
echo "Press any key to start or Ctrl+C to cancel."
read -n 1 # wait for a key press

echo ""
echo "===================== Download Package: Start ==========================="
rm -rf git-$git_ver_new* # remove old sources
if [ "$git_ver_new" = "latest" ]; then
     wget --no-check-certificate -O git-latest.zip https://github.com/git/git/archive/master.zip
else
     wget --no-check-certificate -O git-$git_ver_new.zip https://github.com/git/git/archive/v$git_ver_new.zip
fi
if [ $? -eq 0 ]; then
     echo "Download 'git-$git_ver_new' successfully!"
else
     echo "*** WARNING! Maybe the git version you input was wrong, please check!"
     echo "The git version you just input was: $git_ver_new"
     exit 1
fi
echo "===================== Download Package: End   ==========================="


echo ""
echo "===================== Extract Package: Start ==========================="
if [ "$git_ver_new" = "latest" ]; then
     unzip git-latest.zip
     rm -f git-latest.zip*
     mv git-master git-latest
else
     unzip git-$git_ver_new.zip
     rm -f git-$git_ver_new.zip*
fi
echo "===================== Extract Package: End   ==========================="

echo ""
echo "===================== Install Package: Start ==========================="
mkdir -p $git_exe_dir
cd git-$git_ver_new
make prefix=$(dirname $git_exe_dir) all #CFLAGS="-liconv"
make prefix=$(dirname $git_exe_dir) install #CFLAGS="-liconv"
cd ..
rm -rf git-$git_ver_new
echo "===================== Install Package: End   ==========================="

git_ver_new=$($git_exe_dir/git --version | cut -d ' ' -f 3)
if [ "$git_ver_new" = "" ]; then
    git_ver_new="None"
fi

echo ""
echo "========================================================================="
echo "You have successfully installed/upgraded from '$git_ver_old' to '$git_ver_new'"
echo "You may have to add '$git_exe_dir' to your PATH"
echo "========================================================================="
echo ""

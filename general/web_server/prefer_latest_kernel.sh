#!/usr/bin/env bash

grep CentOS <"/boot/grub2/grub.cfg"

if [ "$?" = "1" ]; then
    echo "This script only designed to work on CentOS..."
    exit 1
fi

grub2-set-default 0
grub2-editenv list
grub2-mkconfig -o "/etc/grub2.cfg"

echo "The system will use the latest kernel as of next boot..."

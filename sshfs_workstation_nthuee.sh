#!/bin/bash

# Install sshfs
#     $ sudo apt-get install -y sshfs
# Add yourself to the fuse group
#     $ sudo adduser YOURNAME fuse
# Logout and login again
# Enable non-root users can modify mounted filesystems
#     $ sudo vim /etc/fuse.conf
#     discomment the "user_allow_other"

mntDir=~/Desktop/workstation_ee

# for example, account=m102061999
account=YOUR_STUDENT_ID
# may be daisy/bigbird
server=daisy.ee.nthu.edu.tw

# some routine jobs
grade=$(echo "$account" | sed -E 's/^([umd])([^1][0-9]|1[0-9]{2}).*/\1\2/')
remoteDir=/home/$grade/$account

mkdir -p $mntDir
fusermount -u $mntDir
sshfs $account@$server:$remoteDir $mntDir -o allow_other

#!/usr/bin/expect

# Usage: ./yppasswd.sh USERNAME NEW_PASSWORD

set rootpwd "Your root password"
set newpwd [lindex $argv 1]

spawn yppasswd [lindex $argv 0]

expect "*?root password:"
send "$rootpwd\r"
expect "*?new password:"
send "$newpwd\r"
expect "*?new password:"
send "$newpwd\r"

expect eof

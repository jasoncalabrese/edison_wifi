#!/bin/bash

killall -g --older-than 60m ssh
killall -g --older-than 60m autossh

if ! /bin/ps -ef | /bin/grep autossh | /bin/grep 2221 | /bin/grep -v grep > /dev/null; then
  echo no autossh process, opening new tunnel
  autossh -M 0 -N -f -o "ServerAliveInterval 30" -o "ServerAliveCountMax 3" -o "PubkeyAuthentication=yes" -o "PasswordAuthentication=no" -R 2221:localhost:22 glu@nightscout.cbrese.com &
fi


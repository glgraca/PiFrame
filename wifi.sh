#!/bin/bash

router=`ip route | awk '/default/ {print $3}'`
/bin/ping -q -c1 $router > /dev/null

if [ $? -eq  0 ]
then
  # echo "Network active"
  :
else
  # echo "Network down, fixing..."
  /bin/kill -9 `pidof wpa_supplicant`
  /sbin/ifup --force wlan0
  /sbin/ip route add default via $router dev wlan0
  /bin/mount -a
fi

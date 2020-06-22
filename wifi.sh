#!/bin/bash

if ifconfig wlan0 | grep -Pq "inet\s\d+\.\d+\.\d+\.\d+" ; then
  echo "Wifi connected"
else
  ifup --force wlan0
fi

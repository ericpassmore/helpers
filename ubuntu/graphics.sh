#!/usr/bin/bash

if [ "$1" -eq "enable" ]; then
   sudo systemctl set-default graphical
   sudo systemctl start gdm3
fi

if [ "$1" -eq "disable" ]; then
   sudo systemctl set-default multi-user
   gnome-session-guit
fi
   

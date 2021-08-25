#!/bin/bash
#set -x

#****************************************************************************
#
# Licensed to the Apache Software Foundation (ASF) under one or more
# contributor license agreements.  See the NOTICE file distributed with
# this work for additional information regarding copyright ownership.  The
# ASF licenses this file to you under the Apache License, Version 2.0 (the
# "License"); you may not use this file except in compliance with the
# License.  You may obtain a copy of the License at
#
#   http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
# WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.  See the
# License for the specific language governing permissions and limitations
# under the License.
#
#****************************************************************************

# USB Ethernet Gadget interface helper script - sets up nuttx to access
# the internet via a host route and IP Tables.

IP_NET="10.0.0.0/24"
IP_NETMASK="255.255.255.0"
IP_BROADCAST="10.0.0.255"
IP_HOST="10.0.0.1"
IP_NUTTX="10.0.0.2"

IF_HOST=$1
IF_USB=$2
STATUS=$3

if [ "$1" != "show" ] && [ $# -ne 3 ]; then
  echo "Usage: $0 <main-interface> <usb-net-interface> <on|off>"
  echo " or to show USB Ethernet gadget interface:"
  echo "       $0 show" 
  exit 1
fi

find_interface() {
    interface="$(ip -o link | egrep '(enx|usb)' | awk '{ print $2 }'| sed 's/://g')"
    echo $interface
}

net_off() {
  # delete routes if necessary
  [ $(ip route show $IP_NET | wc -l) -eq 0 ] || ip route delete $IP_NET 
  [ $(ip route show $IP_NUTTX/32 | wc -l) -eq 0 ] || ip route delete $IP_NUTTX/32

  # delete nat rules to clean up
  iptables --table nat -C POSTROUTING -o $IF_HOST -j MASQUERADE || iptables --table nat -D POSTROUTING -o $IF_HOST -j MASQUERADE  
  iptables -C FORWARD -i $IF_HOST -o $IF_USB -m state --state RELATED,ESTABLISHED -j ACCEPT || iptables -D FORWARD -i $IF_HOST -o $IF_USB -m state --state RELATED,ESTABLISHED -j ACCEPT
  iptables -C FORWARD -i $IF_USB -o $IF_HOST -j ACCEPT || iptables -D FORWARD -i $IF_USB -o $IF_HOST -j ACCEPT

  ip route show
  ifconfig $IF_USB down
}

if [ "$STATUS" == "on" ]; then
  net_off
  ifconfig $IF_USB up
  echo
  ifconfig $IF_USB
  echo
  #ifconfig $IF_USB add $IP_HOST
  ifconfig $IF_USB $IP_HOST
  #ifconfig $IF_USB:0 broadcast $IP_BROADCAST netmask $IP_NETMASK
  ifconfig $IF_USB broadcast $IP_BROADCAST netmask $IP_NETMASK
  ip route add $IP_NET dev $IF_USB src $IP_HOST
  ip route add $IP_NUTTX/32 dev $IF_USB src $IP_HOST

  # nat to allow NuttX to access the internet
  iptables -t nat -A POSTROUTING -o $IF_HOST -j MASQUERADE
  iptables -A FORWARD -i $IF_HOST -o $IF_USB -m state --state RELATED,ESTABLISHED -j ACCEPT
  iptables -A FORWARD -i $IF_USB -o $IF_HOST -j ACCEPT

  ip route show
  echo
  ping -c 1 10.0.0.2
elif [ "$STATUS" == "off" ]; then
  net_off
elif [ "$IF_HOST" == "show" ]; then
  # show interface  
  ifconfig "$(find_interface)"
fi
echo

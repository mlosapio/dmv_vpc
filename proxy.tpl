#!/bin/bash

sudo sysctl -w net.ipv4.ip_forward=1
sudo iptables -A FORWARD -i eth0 -o eth0:1 -m state –state ESTABLISHED,RELATED -j ACCEPT
sudo iptables -A FORWARD -i eth0:1 -o eth0 -j ACCEPT
sudo iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE

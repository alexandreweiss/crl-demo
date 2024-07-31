#!/bin/bash

# Inputs: ${name} ${admin_password}

HOME="/root"

# Set hostname
hostnamectl set-hostname ${name}

# Change Ubuntu password
echo "ubuntu:${admin_password}" | chpasswd

sed -i "s/#PasswordAuthentication no/PasswordAuthentication yes/g" /etc/ssh/sshd_config
sed -i "s/KbdInteractiveAuthentication no/KbdInteractiveAuthentication yes/g" /etc/ssh/sshd_config

systemctl restart sshd
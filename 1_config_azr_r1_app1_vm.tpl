#!/bin/sh

# Inputs: ${storage_account_pe_ip} ${storage_account_name} ${storage_account_key} ${storage_file_share_name}

HOME="/root"

# Auto restart services during apt rather than prompt for restart (new in Ubuntu 22)
sudo sed -i "/#\$nrconf{restart} = 'i';/s/.*/\$nrconf{restart} = 'a';/" /etc/needrestart/needrestart.conf

# Install all the needed packages
sudo apt-get update 

# Install SMB Client
sudo apt-get install smbclient -y

# Insert private endpoint IP of Storage Account into /etc/hosts
echo ${storage_account_pe_ip} ${storage_account_name}.file.core.windows.net >>/etc/hosts

# Mount the Azure File Share
sudo mkdir /mnt/${storage_account_name}
sudo mount -t cifs //${storage_account_name}.file.core.windows.net/${storage_file_share_name} /mnt/${storage_account_name} -o vers=3.0,username=${storage_account_name},password=${storage_account_key},dir_mode=0777,file_mode=0777,serverino
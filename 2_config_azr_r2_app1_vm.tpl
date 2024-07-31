#!/bin/sh

# Inputs: 

# Auto restart services during apt rather than prompt for restart (new in Ubuntu 22)yes
sudo sed -i "/#\$nrconf{restart} = 'i';/s/.*/\$nrconf{restart} = 'a';/" /etc/needrestart/needrestart.conf

# Install all the needed packages
sudo apt-get update 

sudo apt-get install nginx -y

# Inject hostname into default nginx page
sudo sed -i "s/Welcome to nginx/Welcome to nginx on ${application_1} server in ${region} region/g" /var/www/html/index.nginx-debian.html

sudo systemctl start nginx 
sudo systemctl enable nginx
sudo service nginx restart
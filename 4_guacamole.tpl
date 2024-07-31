#!/bin/sh

# Inputs: ${username} ${vm_password} ${hostname_r1_app1} ${hostname_r1_app2} ${hostname_r2_app1} ${hostname_r2_app2} ${hostname_r1_spoke_a_app1_nat} ${hostname_r1_spoke_b_app1_nat} ${azr_r1_location_short} ${azr_r2_location_short} ${aws_r1_location_short} ${hostname_aws_r1_app1}  ${hostname_aws_r1_app2} ${application_1} ${application_2}

# Auto restart services during apt rather than prompt for restart (new in Ubuntu 22)
sudo sed -i "/#\$nrconf{restart} = 'i';/s/.*/\$nrconf{restart} = 'a';/" /etc/needrestart/needrestart.conf

# Install all the needed packages
sudo apt-get update 

sudo apt-get install python3-bottle python-pip make gcc g++ libcairo2-dev libjpeg-turbo8-dev libtool-bin libossp-uuid-dev libavcodec-dev libswscale-dev freerdp2-dev libpango1.0-dev libssh2-1-dev libvncserver-dev libtelnet-dev libvorbis-dev libwebp-dev tomcat9 tomcat9-admin tomcat9-user nginx -y

sudo pip install requests bottle

# Start and enable Tomcat
sudo systemctl start tomcat9
sudo systemctl enable tomcat9

# Download and install Guacamole Server
wget https://downloads.apache.org/guacamole/1.5.4/source/guacamole-server-1.5.4.tar.gz -P /tmp/
tar xzf /tmp/guacamole-server-1.5.4.tar.gz -C /tmp/

(
    cd /tmp/guacamole-server-1.5.4 
    sudo ./configure --with-init-dir=/etc/init.d
    sudo make
    sudo make install
    sudo ldconfig
)

sudo systemctl start guacd
sudo systemctl enable guacd 


####
sudo mkdir /etc/guacamole

echo "<user-mapping>
  <authorize username=\"guacadmin\" password=\"${vm_password}\">
    <connection name=\"Region 1 Azure : ${azr_r1_location_short}-${application_1}\">
      <protocol>ssh</protocol>
      <param name=\"hostname\">${hostname_r1_app1}</param>
      <param name=\"username\">admin-lab</param>
      <param name=\"password\">${vm_password}</param>
    </connection>
    <connection name=\"Region 1 Azure: ${azr_r1_location_short}-${application_2}\">
      <protocol>ssh</protocol>
      <param name=\"hostname\">${hostname_r1_app2}</param>
      <param name=\"username\">admin-lab</param>
      <param name=\"password\">${vm_password}</param>
    </connection>
    <connection name=\"Region 2 Azure : ${azr_r2_location_short}-${application_1}\">
      <protocol>ssh</protocol>
      <param name=\"hostname\">${hostname_r2_app1}</param>
      <param name=\"username\">admin-lab</param>
      <param name=\"password\">${vm_password}</param>
    </connection>
    <connection name=\"Region 2 Azure : ${azr_r2_location_short}-${application_2}\">
      <protocol>ssh</protocol>
      <param name=\"hostname\">${hostname_r2_app2}</param>
      <param name=\"username\">admin-lab</param>
      <param name=\"password\">${vm_password}</param>
    </connection>
    <connection name=\"Region 1 Azure : ${azr_r1_location_short}-${application_1}-nat-a (vip: ${hostname_r1_spoke_a_app1_nat})\">
      <protocol>ssh</protocol>
      <param name=\"hostname\">${hostname_r1_spoke_a_app1_nat}</param>
      <param name=\"username\">admin-lab</param>
      <param name=\"password\">${vm_password}</param>
    </connection>
    <connection name=\"Region 1 Azure : ${azr_r1_location_short}-${application_1}-nat-b (vip: ${hostname_r1_spoke_b_app1_nat})\">
      <protocol>ssh</protocol>
      <param name=\"hostname\">${hostname_r1_spoke_b_app1_nat}</param>
      <param name=\"username\">admin-lab</param>
      <param name=\"password\">${vm_password}</param>
    </connection>
    <connection name=\"Region 1 AWS : ${aws_r1_location_short}-${application_1}\">
      <protocol>ssh</protocol>
      <param name=\"hostname\">${hostname_aws_r1_app1}</param>
      <param name=\"username\">ubuntu</param>
      <param name=\"password\">${vm_password}</param>
    </connection>
    <connection name=\"Region 1 AWS : ${aws_r1_location_short}-${application_2}\">
      <protocol>ssh</protocol>
      <param name=\"hostname\">${hostname_aws_r1_app2}</param>
      <param name=\"username\">ubuntu</param>
      <param name=\"password\">${vm_password}</param>
    </connection>
    <connection name=\"Region 2 AWS : ${aws_r2_location_short}-${application_1}\">
      <protocol>ssh</protocol>
      <param name=\"hostname\">${hostname_aws_r2_app1}</param>
      <param name=\"username\">ubuntu</param>
      <param name=\"password\">${vm_password}</param>
    </connection>
    <connection name=\"Region 2 AWS : ${aws_r2_location_short}-${application_2}\">
      <protocol>ssh</protocol>
      <param name=\"hostname\">${hostname_aws_r2_app2}</param>
      <param name=\"username\">ubuntu</param>
      <param name=\"password\">${vm_password}</param>
    </connection>
  </authorize>
</user-mapping>" | sudo tee -a /etc/guacamole/user-mapping.xml


sudo wget https://downloads.apache.org/guacamole/1.5.4/binary/guacamole-1.5.4.war -O /etc/guacamole/guacamole.war 
sudo ln -s /etc/guacamole/guacamole.war /var/lib/tomcat9/webapps/ 
sleep 10 
sudo mkdir /etc/guacamole/{extensions,lib} 
sudo bash -c 'echo "GUACAMOLE_HOME=/etc/guacamole" >> /etc/default/tomcat9'

echo "guacd-hostname: localhost
guacd-port:    4822
user-mapping:    /etc/guacamole/user-mapping.xml
auth-provider:    net.sourceforge.guacamole.net.basic.BasicFileAuthenticationProvider"  | sudo tee -a /etc/guacamole/guacamole.properties

sudo ln -s /etc/guacamole /usr/share/tomcat9/.guacamole

sudo systemctl restart tomcat9 
sudo systemctl restart guacd 

# Deploy nginx proxy config
sudo mv /etc/nginx/sites-available/default /etc/nginx/default.save

echo "server {
    listen 80;
    return 301 https://\$host\$request_uri;
}
server {
	listen 443 ssl;
  ssl_certificate /etc/nginx/cert.crt;
	ssl_certificate_key /etc/nginx/cert.key;
	ssl_protocols TLSv1.2;
	ssl_prefer_server_ciphers on;
	add_header X-Frame-Options DENY;
	add_header X-Content-Type-Options nosniff;
	access_log  /var/log/nginx/guac_access.log;
	error_log  /var/log/nginx/guac_error.log;
	location /app {
		    proxy_pass http://${hostname_r2_app1}/;
		    proxy_buffering off;
		    proxy_http_version 1.1;
	}
	location / {
		    proxy_pass http://localhost:8080/guacamole/;
		    proxy_buffering off;
		    proxy_http_version 1.1;
		    proxy_cookie_path /guacamole/ /;
	}
}" | sudo tee -a /etc/nginx/sites-available/default

sudo openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout /etc/nginx/cert.key -out /etc/nginx/cert.crt -subj "/CN=guacamole\/emailAddress=someone@somedomin.com/C=US/ST=Ohio/L=Columbus/O=Aviatrix Inc/OU=IT"

sudo systemctl start nginx 
sudo systemctl enable nginx
sudo service nginx restart
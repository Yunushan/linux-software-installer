#!/bin/bash

#20-PhpMyAdmin
printf "\nPlease Choose Your Desired PhpMyAdmin Version\n\n1-) PhpMyAdmin (For Apache(httpd))\n\
2-) PhpMyAdmin (For Nginx)\n\nPlease Select Your PhpMyAdmin Version:"
read -r phpmyadmin_version
if [ "$phpmyadmin_version" = "1" ];then
    phpmyadmin_link=$(lynx -dump https://www.phpmyadmin.net/files/ | awk '/http/ {print $2}' \
    | grep -iv "sha256\|asc\|rc\|alpha\|beta\|all-languages\|feed" | grep -i files | head -n 1)
    phpmyadmin_link=$(lynx -dump "$phpmyadmin_link" | awk '/http/ {print $2}' | grep -iv "asc\|sha256\|rc" \
    | grep -i ".tar.gz" | grep -i "all-languages" | head -n 1)
    wget -O /root/Downloads/phpmyadmin.tar.gz "$phpmyadmin_link" 
    sudo mkdir -pv /var/www/html/phpmyadmin
    tar -xvf /root/Downloads/phpmyadmin.tar.gz -C /var/www/html/phpmyadmin --strip-components 1
    chown -R apache:apache /var/www/html/phpmyadmin
    cd /var/www/html/phpmyadmin
    sudo mv -v /var/www/html/phpmyadmin/config.sample.inc.php config.inc.php
    sed -i "s/''/'MeFZGYawNmtMYGdR.Zs8hQ4dQ1[plUgV'/g" /var/www/html/phpmyadmin/config.inc.php
    echo "Alias /phpmyadmin /var/www/html/phpmyadmin

<Directory /var/www/html/phpmyadmin/>
	AddDefaultCharset UTF-8
	<IfModule mod_authz_core.c>
		# Apache 2.4
		<RequireAny>
			Require all granted
		</RequireAny>
	</IfModule>
	<IfModule !mod_authz_core.c>
		# Apache 2.2
		Order Deny,Allow
		Deny from All
		Allow from 127.0.0.1
		Allow from ::1
	</IfModule>
</Directory>
<Directory /var/www/html/phpmyadmin/setup/>
	<IfModule mod_authz_core.c>
		# Apache 2.4
		<RequireAny>
			Require all granted
		</RequireAny>
	</IfModule>
	<IfModule !mod_authz_core.c>
			# Apache 2.2
			Order Deny,Allow
			Deny from All
			Allow from 127.0.0.1
			Allow from ::1
	</IfModule>
</Directory>" > /etc/httpd/conf.d/phpmyadmin.conf
    systemctl restart httpd
elif [ "$phpmyadmin_version" = "2" ];then
    phpmyadmin_link=$(lynx -dump https://www.phpmyadmin.net/files/ | awk '/http/ {print $2}' \
    | grep -iv "sha256\|asc\|rc\|alpha\|beta\|all-languages\|feed" | grep -i files | head -n 1)
    phpmyadmin_link=$(lynx -dump "$phpmyadmin_link" | awk '/http/ {print $2}' | grep -iv "asc\|sha256\|rc" \
    | grep -i ".tar.gz" | grep -i "all-languages" | head -n 1)
    wget -O /root/Downloads/phpmyadmin.tar.gz "$phpmyadmin_link" 
    sudo mkdir -pv /var/www/html/phpmyadmin
    tar -xvf /root/Downloads/phpmyadmin.tar.gz -C /var/www/html/phpmyadmin --strip-components 1
    chown -R nginx:nginx /var/www/html/phpmyadmin
    cd /var/www/html/phpmyadmin
    sudo mv -v /var/www/html/phpmyadmin/config.sample.inc.php config.inc.php
    sed -i "s/''/'MeFZGYawNmtMYGdR.Zs8hQ4dQ1[plUgV'/g" /var/www/html/phpmyadmin/config.inc.php
    echo "server {
   listen 80;
   server_name http://192.168.0.45/phpmyadmin/;
   root /var/www/html/phpmyadmin;

   location / {
      index index.php;
   }

## Images and static content is treated different
   location ~* ^.+.(jpg|jpeg|gif|css|png|js|ico|xml)$ {
      access_log off;
      expires 30d;
   }

   location ~ /\.ht {
      deny all;
   }

   location ~ /(libraries|setup/frames|setup/libs) {
      deny all;
      return 404;
   }

   location ~ \.php$ {
      include /etc/nginx/fastcgi_params;
      fastcgi_pass 127.0.0.1:9000;
      fastcgi_index index.php;
      fastcgi_param SCRIPT_FILENAME /var/www/html/phpmyadmin$fastcgi_script_name;
   }
}" > /etc/nginx/conf.d/phpmyadmin.conf
    systemctl restart nginx
else
    echo "Out of options please choose between 1-2"
fi
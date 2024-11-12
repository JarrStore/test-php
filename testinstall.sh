#!/bin/bash

# Variables
DB_USER="namadatabase"
DB_PASS="pwdatabase"
DB_HOST="ipdatabase"
DOMAIN="domain"
TOKEN="fajaroffc"
EXPECTED_TOKEN="fajaroffc"

# Token Verification
read -p "Enter your token: " user_token

if [ "$user_token" != "$EXPECTED_TOKEN" ]; then
    echo "Invalid token. Exiting."
    exit 1
fi

# Menu for selecting action
echo "INSTAL PHPMYADMIN OTOMATIS BY FAJAR"
echo "Select an option:"
echo "1. Buat Database"
echo "2. Install phpMyAdmin"
read -p "Enter your choice [1 or 2]: " choice

case $choice in
    1)
        # Create Database User
        mysql -u root -p <<MYSQL_SCRIPT
CREATE USER '${DB_USER}'@'${DB_HOST}' IDENTIFIED BY '${DB_PASS}';
GRANT ALL PRIVILEGES ON *.* TO '${DB_USER}'@'${DB_HOST}' WITH GRANT OPTION;
MYSQL_SCRIPT
        echo "Database user created."
        ;;

    2)
        # Install phpMyAdmin
        mkdir -p /var/www/phpmyadmin && mkdir /var/www/phpmyadmin/tmp/ && cd /var/www/phpmyadmin
        wget https://www.phpmyadmin.net/downloads/phpMyAdmin-latest-english.tar.gz
        tar xvzf phpMyAdmin-latest-english.tar.gz
        mv /var/www/phpmyadmin/phpMyAdmin-*-english/* /var/www/phpmyadmin
        echo "phpMyAdmin installed."

        # Create SSL Certificate
        certbot certonly --nginx -d ${DOMAIN}
        echo "SSL certificate created for ${DOMAIN}."

        # Set Permissions and Configuration
        chown -R www-data:www-data /var/www/phpmyadmin
        mkdir /var/www/phpmyadmin/config
        chmod o+rw /var/www/phpmyadmin/config
        cp /var/www/phpmyadmin/config.sample.inc.php /var/www/phpmyadmin/config/config.inc.php
        chmod o+w /var/www/phpmyadmin/config/config.inc.php
        echo "Permissions and configuration set."

        # Configure Nginx for phpMyAdmin
        cat > /etc/nginx/sites-available/phpmyadmin.conf <<EOL
server {
    listen 80;
    server_name ${DOMAIN};
    return 301 https://\$server_name\$request_uri;
}

server {
    listen 443 ssl http2;
    server_name ${DOMAIN};

    root /var/www/phpmyadmin;
    index index.php;

    # allow larger file uploads and longer script runtimes
    client_max_body_size 100m;
    client_body_timeout 120s;

    sendfile off;

    # SSL Configuration
    ssl_certificate /etc/letsencrypt/live/${DOMAIN}/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/${DOMAIN}/privkey.pem;
    ssl_session_cache shared:SSL:10m;
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers 'ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-SHA384:ECDHE-RSA-AES256-SHA384:ECDHE-ECDSA-AES128-SHA256:ECDHE-RSA-AES128-SHA256';
    ssl_prefer_server_ciphers on;

    # See https://hstspreload.org/ before uncommenting the line below.
    # add_header Strict-Transport-Security "max-age=15768000; preload;";
    add_header X-Content-Type-Options nosniff;
    add_header X-XSS-Protection "1; mode=block";
    add_header X-Robots-Tag none;
    add_header Content-Security-Policy "frame-ancestors 'self'";
    add_header X-Frame-Options DENY;
    add_header Referrer-Policy same-origin;

    location / {
        try_files \$uri \$uri/ /index.php?\$query_string;
    }

    location ~ \.php$ {
        fastcgi_split_path_info ^(.+\.php)(/.+)\$;
        fastcgi_pass unix:/run/php/php8.1-fpm.sock;
        fastcgi_index index.php;
        include fastcgi_params;
        fastcgi_param PHP_VALUE "upload_max_filesize = 100M \n post_max_size=100M";
        fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
        fastcgi_param HTTP_PROXY "";
        fastcgi_intercept_errors off;
        fastcgi_buffer_size 16k;
        fastcgi_buffers 4 16k;
        fastcgi_connect_timeout 300;
        fastcgi_send_timeout 300;
        fastcgi_read_timeout 300;
        include /etc/nginx/fastcgi_params;
    }

    location ~ /\.ht {
        deny all;
    }
}
EOL

        echo "Nginx configuration set for phpMyAdmin."

        # Enable site and restart Nginx
        ln -s /etc/nginx/sites-available/phpmyadmin.conf /etc/nginx/sites-enabled/phpmyadmin.conf
        systemctl restart nginx

        echo "phpMyAdmin setup complete. You can access it at https://${DOMAIN}"
        ;;
        
    *)
        echo "Invalid option selected."
        exit 1
        ;;
esac

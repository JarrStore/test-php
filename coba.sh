#!/bin/bash

# Function to print text in color
print_color() {
    echo -e "\e[$2m$1\e[0m"
}

# Display big text in color at the center
print_color "=============================================" "32"
print_color "           AUTO INSTALLER BY FAJAR OFFICIAL            " "32"
print_color "=============================================" "32"

# Token Verification
EXPECTED_TOKEN="fajaroffc"
read -p "Enter your token: " user_token

if [ "$user_token" != "$EXPECTED_TOKEN" ]; then
    print_color "Invalid token. Exiting. Please buy it from Fajar Offc." "31"
    exit 1
fi

print_color "Login successful!" "32"

# Walking text effect
while true; do
    for i in $(seq 0 100); do
        tput cup 1 $i
        print_color "Welcome, I am Fajar Offc Auto Installer!" "34"
        sleep 0.1
        tput cup 1 $i
        echo -n "                                         "
    done
done &

# Menu for selecting action
print_color "===============================" "36"
print_color "INSTAL PHPMYADMIN OTOMATIS BY FAJAR" "36"
print_color "===============================" "36"
print_color "Select an option:" "33"
echo "1. Buat Database"
echo "2. Install phpMyAdmin"
echo "3. Exit"
read -p "Enter your choice [1, 2, or 3]: " choice

case $choice in
    1)
        # Database details input
        read -p "Enter the database name: " DB_NAME
        read -p "Enter the database user: " DB_USER
        read -p "Enter the database password: " DB_PASS
        read -p "Enter the database host: " DB_HOST

        # Create Database User
        mysql -u root -p <<MYSQL_SCRIPT
CREATE USER '${DB_USER}'@'${DB_HOST}' IDENTIFIED BY '${DB_PASS}';
GRANT ALL PRIVILEGES ON *.* TO '${DB_USER}'@'${DB_HOST}' WITH GRANT OPTION;
MYSQL_SCRIPT
        print_color "Database user created." "32"
        ;;

    2)
        # Domain input
        read -p "Enter the domain: " DOMAIN

        # Install phpMyAdmin
        mkdir -p /var/www/phpmyadmin && mkdir /var/www/phpmyadmin/tmp/ && cd /var/www/phpmyadmin
        wget https://www.phpmyadmin.net/downloads/phpMyAdmin-latest-english.tar.gz
        tar xvzf phpMyAdmin-latest-english.tar.gz
        mv /var/www/phpmyadmin/phpMyAdmin-*-english/* /var/www/phpmyadmin
        print_color "phpMyAdmin installed." "32"

        # Create SSL Certificate
        certbot certonly --nginx -d ${DOMAIN}
        print_color "SSL certificate created for ${DOMAIN}." "32"

        # Set Permissions and Configuration
        chown -R www-data:www-data /var/www/phpmyadmin
        mkdir /var/www/phpmyadmin/config
        chmod o+rw /var/www/phpmyadmin/config
        cp /var/www/phpmyadmin/config.sample.inc.php /var/www/phpmyadmin/config/config.inc.php
        chmod o+w /var/www/phpmyadmin/config/config.inc.php
        print_color "Permissions and configuration set." "32"

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

        print_color "Nginx configuration set for phpMyAdmin." "32"

        # Enable site and restart Nginx
        ln -s /etc/nginx/sites-available/phpmyadmin.conf /etc/nginx/sites-enabled/phpmyadmin.conf
        systemctl restart nginx

        print_color "phpMyAdmin setup complete. You can access it at https://${DOMAIN}" "32"
        ;;

    3)
        print_color "Exiting the installer." "31"
        exit 0
        ;;

    *)
        print_color "Invalid option selected." "31"
        exit 1
        ;;
esac

# Return to menu
exec "$0"

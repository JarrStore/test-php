#!/bin/bash

# Warna teks
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
RESET='\033[0m'

# Menampilkan pesan besar dengan warna
echo -e "${BLUE}"
echo "##########################################"
echo "##                                      ##"
echo "##       AUTO INSTALLER BY FAJAR        ##"
echo "##            OFFICIAL                  ##"
echo "##                                      ##"
echo "##########################################"
echo -e "${RESET}"

# Verifikasi Token
EXPECTED_TOKEN="fajaroffc"
echo -e "${YELLOW}Masukkan token Anda: ${RESET}"
read -p "Token: " user_token

if [ "$user_token" != "$EXPECTED_TOKEN" ]; then
    echo -e "${RED}Token salah. Silakan beli di FAJAR OFFC.${RESET}"
    exit 1
else
    echo -e "${GREEN}Login sukses!${RESET}"
    echo -e "${CYAN}Selamat datang, saya adalah FAJAR OFFC Auto Installer.${RESET}"
fi

# Menu untuk memilih tindakan
echo -e "${MAGENTA}INSTAL PHPMYADMIN OTOMATIS BY FAJAR${RESET}"
echo -e "${CYAN}Pilih opsi:${RESET}"
echo "1. Buat Database"
echo "2. Install phpMyAdmin"
read -p "Masukkan pilihan Anda [1 atau 2]: " choice

case $choice in
    1)
        # Input detail database
        read -p "Masukkan nama pengguna database: " DB_USER
        read -p "Masukkan host database: " DB_HOST
        read -p "Masukkan kata sandi database: " DB_PASS

        # Membuat pengguna database
        mysql -u root -p <<MYSQL_SCRIPT
CREATE USER '${DB_USER}'@'${DB_HOST}' IDENTIFIED BY '${DB_PASS}';
GRANT ALL PRIVILEGES ON *.* TO '${DB_USER}'@'${DB_HOST}' WITH GRANT OPTION;
MYSQL_SCRIPT
        echo -e "${GREEN}Pengguna database dibuat.${RESET}"
        ;;

    2)
        # Input domain
        read -p "Masukkan domain: " DOMAIN

        # Install phpMyAdmin
        mkdir -p /var/www/phpmyadmin && mkdir /var/www/phpmyadmin/tmp/ && cd /var/www/phpmyadmin
        wget https://www.phpmyadmin.net/downloads/phpMyAdmin-latest-english.tar.gz
        tar xvzf phpMyAdmin-latest-english.tar.gz
        mv /var/www/phpmyadmin/phpMyAdmin-*-english/* /var/www/phpmyadmin
        echo -e "${GREEN}phpMyAdmin terinstal.${RESET}"

        # Membuat Sertifikat SSL
        certbot certonly --nginx -d ${DOMAIN}
        echo -e "${GREEN}Sertifikat SSL dibuat untuk ${DOMAIN}.${RESET}"

        # Mengatur Izin dan Konfigurasi
        chown -R www-data:www-data /var/www/phpmyadmin
        mkdir /var/www/phpmyadmin/config
        chmod o+rw /var/www/phpmyadmin/config
        cp /var/www/phpmyadmin/config.sample.inc.php /var/www/phpmyadmin/config/config.inc.php
        chmod o+w /var/www/phpmyadmin/config/config.inc.php
        echo -e "${GREEN}Izin dan konfigurasi diatur.${RESET}"

        # Konfigurasi Nginx untuk phpMyAdmin
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

        echo -e "${GREEN}Konfigurasi Nginx diatur untuk phpMyAdmin.${RESET}"

        # Mengaktifkan situs dan restart Nginx
        ln -s /etc/nginx/sites-available/phpmyadmin.conf /etc/nginx/sites-enabled/phpmyadmin.conf
        systemctl restart nginx

        echo -e "${GREEN}phpMyAdmin selesai diatur. Anda dapat mengaksesnya di https://${DOMAIN}${RESET}"
        ;;
        
    *)
        echo -e "${RED}Opsi tidak valid.${RESET}"
        exit 1
        ;;
esac
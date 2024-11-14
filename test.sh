#!/bin/bash

# Fungsi untuk mencetak teks dengan warna
print_color() {
    local color="$1"
    local text="$2"
    case "$color" in
        "red") echo -e "\033[31m$text\033[0m" ;;
        "green") echo -e "\033[32m$text\033[0m" ;;
        "yellow") echo -e "\033[33m$text\033[0m" ;;
        "blue") echo -e "\033[34m$text\033[0m" ;;
        "cyan") echo -e "\033[36m$text\033[0m" ;;
        "purple") echo -e "\033[35m$text\033[0m" ;;
        "white") echo -e "\033[37m$text\033[0m" ;;
        *) echo "$text" ;;
    esac
}

# Fungsi untuk clear screen
clear_screen() {
    clear
}

# Tampilkan header
clear_screen
print_color "blue" "############################################"
print_color "green" "AUTO INSTALLER FAJAR OFFC"
print_color "blue" "############################################"
print_color "cyan" "Kode Token: fajarofficial"
print_color "yellow" "AUTO INSTALLER BY FAJAR OFFICIAL"
print_color "purple" "Silakan pilih:"
print_color "white" "1. Install PHPMyAdmin"
print_color "white" "2. Create Database"
print_color "white" "3. Exit"

# Pilih menu
read -p "Masukkan pilihan Anda [1-3]: " pilihan

# Fungsi instalasi PHPMyAdmin
install_phpmyadmin() {
    print_color "green" "AUTO INSTALL PHPMYADMIN BY FAJAR OFFICIAL"

    # Konfirmasi instalasi
    read -p "Apakah Anda yakin ingin melanjutkan? (y/n): " confirm
    if [[ "$confirm" != "y" ]]; then
        print_color "red" "Instalasi dibatalkan."
        return
    fi

    # Instalasi PHPMyAdmin
    print_color "cyan" "Memulai instalasi PHPMyAdmin..."
    mkdir /var/www/phpmyadmin && mkdir /var/www/phpmyadmin/tmp/ && cd /var/www/phpmyadmin
    wget https://www.phpmyadmin.net/downloads/phpMyAdmin-latest-english.tar.gz
    tar xvzf phpMyAdmin-latest-english.tar.gz
    mv /var/www/phpmyadmin/phpMyAdmin-*-english/* /var/www/phpmyadmin
    chown -R www-data:www-data /var/www/phpmyadmin
    mkdir config
    chmod o+rw config
    cp config.sample.inc.php config/config.inc.php
    chmod o+w config/config.inc.php

    # Konfigurasi SSL dengan Certbot
    print_color "cyan" "Menjalankan Certbot untuk SSL..."
    read -p "Masukkan domain untuk Certbot: " domain
    certbot certonly --nginx -d "$domain"

    # Konfigurasi Nginx untuk PHPMyAdmin
    print_color "cyan" "Mengonfigurasi Nginx..."
    cat > /etc/nginx/sites-available/phpmyadmin.conf <<EOF
server {
    listen 80;
    server_name $domain;
    return 301 https://\$server_name\$request_uri;
}

server {
    listen 443 ssl http2;
    server_name $domain;

    root /var/www/phpmyadmin;
    index index.php;

    # Allow larger file uploads and longer script runtimes
    client_max_body_size 100m;
    client_body_timeout 120s;

    sendfile off;

    # SSL Configuration
    ssl_certificate /etc/letsencrypt/live/$domain/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/$domain/privkey.pem;
    ssl_session_cache shared:SSL:10m;
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers 'ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-SHA384:ECDHE-RSA-AES256-SHA384:ECDHE-ECDSA-AES128-SHA256:ECDHE-RSA-AES128-SHA256';
    ssl_prefer_server_ciphers on;

    location / {
        try_files \$uri \$uri/ /index.php?\$query_string;
    }

    location ~ \.php$ {
        fastcgi_split_path_info ^(.+\.php)(/.+)$;
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
EOF

    # Aktifkan konfigurasi PHPMyAdmin dan restart Nginx
    ln -s /etc/nginx/sites-available/phpmyadmin.conf /etc/nginx/sites-enabled/phpmyadmin.conf
    systemctl restart nginx

    print_color "green" "TERIMAKASIH SUDAH PAKAI AUTO INSTALLER PHPMYADMIN BY FAJAR OFFICIAL"
}

# Fungsi untuk membuat database
create_database() {
    print_color "green" "CREATE DATABASE dbuser ipdb pwdb"
    
    # Konfirmasi pembuatan database
    read -p "Apakah Anda yakin ingin melanjutkan? (y/n): " confirm
    if [[ "$confirm" != "y" ]]; then
        print_color "red" "Pembuatan database dibatalkan."
        return
    fi

    # Pembuatan database
    print_color "cyan" "Memulai pembuatan database..."
    read -p "Masukkan username untuk database: " dbuser
    read -p "Masukkan IP untuk akses database: " ipdb
    read -sp "Masukkan password untuk database: " pwdb
    echo

    # Perintah MySQL
    mysql -u root -p -e "
        CREATE USER '$dbuser'@'$ipdb' IDENTIFIED BY '$pwdb';
        GRANT ALL PRIVILEGES ON *.* TO '$dbuser'@'$ipdb' WITH GRANT OPTION;
    "

    print_color "green" "DATABASE SUDAH DI BUAT BY FAJAR OFFC YAITU"
}

# Menangani pilihan user
case $pilihan in
    1)
        install_phpmyadmin
        ;;
    2)
        create_database
        ;;
    3)
        print_color "red" "Terima kasih telah menggunakan Auto Installer!"
        exit 0
        ;;
    *)
        print_color "red" "Pilihan tidak valid!"
        exit 1
        ;;
esac

# Kembali ke menu utama setelah selesai
clear_screen
exec "$0"  # Restart script untuk kembali ke menu utama
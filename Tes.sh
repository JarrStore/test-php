#!/bin/bash

# Fungsi untuk menampilkan pesan dengan warna
function print_color() {
    color=$1
    message=$2
    echo -e "\033[${color}m${message}\033[0m"
}

# Tampilan pesan pembuka
clear
print_color "1;34" "##########################################"
print_color "1;34" "#         AUTO INSTALLER BY FAJAR OFFICIAL          #"
print_color "1;34" "##########################################"
echo ""

# Meminta masukan token dan kode token
read -p "Masukkan token Anda: " token
if [[ "$token" != "fajarganteng" ]]; then
    print_color "1;31" "Token salah! Program dihentikan."
    exit 1
fi

# Clear pesan sebelumnya
clear

# Pilihan menu
PS3='Silakan pilih opsi: '
options=("Install PHPMyAdmin" "Create Database" "Exit")
select opt in "${options[@]}"
do
    case $opt in
        "Install PHPMyAdmin")
            # Menginstal PHPMyAdmin
            clear
            print_color "1;32" "AUTO INSTALLER PHPMyAdmin by Fajar Official"
            read -p "Masukkan domain PHP: " domainphp
            read -p "Setujui untuk membuat database dan menginstal PHPMyAdmin (yes/no): " approve
            if [[ "$approve" == "yes" ]]; then
                # Instalasi PHPMyAdmin dimulai
                echo "Instalasi PHPMyAdmin dimulai..."
                mkdir /var/www/phpmyadmin && mkdir /var/www/phpmyadmin/tmp/ && cd /var/www/phpMyAdmin

                wget https://www.phpmyadmin.net/downloads/phpMyAdmin-latest-english.tar.gz
                tar xvzf phpMyAdmin-latest-english.tar.gz
                mv /var/www/phpmyadmin/phpMyAdmin-*-english/* /var/www/phpMyAdmin

                # Instalasi SSL
                certbot certonly --nginx -d $domainphp

                # Konfigurasi PHPMyAdmin
                chown -R www-data:www-data *
                mkdir config
                chmod o+rw config
                cp config.sample.inc.php config/config.inc.php
                chmod o+w config/config.inc.php

                # Konfigurasi Nginx
                cat > /etc/nginx/sites-available/phpmyadmin.conf <<EOF
server {
    listen 80;
    server_name $domainphp;
    return 301 https://$server_name$request_uri;
}

server {
    listen 443 ssl http2;
    server_name $domainphp;

    root /var/www/phpmyadmin;
    index index.php;

    # Allow larger file uploads and longer script runtimes
    client_max_body_size 100m;
    client_body_timeout 120s;

    sendfile off;

    # SSL Configuration
    ssl_certificate /etc/letsencrypt/live/$domainphp/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/$domainphp/privkey.pem;
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

                # Aktifkan konfigurasi PHPMyAdmin
                sudo ln -s /etc/nginx/sites-available/phpmyadmin.conf /etc/nginx/sites-enabled/phpmyadmin.conf

                # Restart Nginx
                systemctl restart nginx

                print_color "1;32" "PHPMyAdmin berhasil diinstal dan dikonfigurasi!"

            else
                print_color "1;31" "Instalasi dibatalkan."
            fi
            break
            ;;
        "Create Database")
            # Membuat database
            clear
            print_color "1;32" "Pilih opsi untuk membuat database"
            read -p "Masukkan username database: " usernamedb
            read -p "Masukkan IP database: " ipdb
            read -p "Masukkan password database: " passworddb

            # Membuat database
            mysql -u root -p <<EOF
CREATE USER '$usernamedb'@'$ipdb' IDENTIFIED BY '$passworddb';
GRANT ALL PRIVILEGES ON *.* TO '$usernamedb'@'$ipdb' WITH GRANT OPTION;
EOF

            print_color "1;32" "Database berhasil dibuat!"
            break
            ;;
        "Exit")
            print_color "1;34" "Terima kasih telah menggunakan AUTO INSTALLER BY FAJAR OFFICIAL!"
            exit 0
            ;;
        *)
            print_color "1;31" "Opsi tidak valid. Silakan pilih kembali."
            ;;
    esac
done

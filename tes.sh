#!/bin/bash

# Fungsi untuk menampilkan teks berwarna
function print_color() {
    local color="$1"
    local text="$2"
    case "$color" in
        "red")
            echo -e "\033[31m$text\033[0m"
            ;;
        "green")
            echo -e "\033[32m$text\033[0m"
            ;;
        "yellow")
            echo -e "\033[33m$text\033[0m"
            ;;
        "blue")
            echo -e "\033[34m$text\033[0m"
            ;;
        "magenta")
            echo -e "\033[35m$text\033[0m"
            ;;
        "cyan")
            echo -e "\033[36m$text\033[0m"
            ;;
        "white")
            echo -e "\033[37m$text\033[0m"
            ;;
        *)
            echo -e "$text"
            ;;
    esac
}

# Clear screen and show the header
clear
print_color "magenta" "AUTO INSTALLER FAJAR OFFICIAL"
echo ""
print_color "cyan" "========================================="
print_color "yellow" "AUTO INSTALLER BY FAJAR OFFICIAL"
print_color "yellow" "Silahkan Pilih:"
print_color "yellow" "1. Instal PHPMyAdmin"
print_color "yellow" "2. Create Database"
print_color "yellow" "3. Exit"
print_color "cyan" "========================================="
echo ""

# Prompt for the token
read -p "Masukkan Token Anda: " token
if [[ "$token" != "fajarofficial" ]]; then
    print_color "red" "Token yang Anda masukkan salah!"
    exit 1
fi

# Main menu loop
while true; do
    # Read user choice
    read -p "Pilih (1/2/3): " choice
    clear

    # Jika memilih instal PHPMyAdmin
    if [[ "$choice" == "1" ]]; then
        print_color "magenta" "AUTO INSTALL PHPMYADMIN BY FAJAR OFFICIAL"
        echo ""
        print_color "cyan" "Masukkan domain PHPMyAdmin Anda (contoh: domainphp.com):"
        read -p "Domain: " domainphp
        print_color "yellow" "Anda memilih domain: $domainphp"
        
        read -p "Apakah Anda yakin untuk melanjutkan instalasi PHPMyAdmin? (y/n): " confirm
        if [[ "$confirm" == "y" || "$confirm" == "Y" ]]; then
            # Instalasi PHPMyAdmin
            print_color "blue" "Memulai instalasi PHPMyAdmin..."

            mkdir /var/www/phpmyadmin && mkdir /var/www/phpmyadmin/tmp/ && cd /var/www/phpMyAdmin
            wget https://www.phpmyadmin.net/downloads/phpMyAdmin-latest-english.tar.gz
            tar xvzf phpMyAdmin-latest-english.tar.gz
            mv /var/www/phpmyadmin/phpMyAdmin-*-english/* /var/www/phpMyAdmin

            # SSL Configuration
            print_color "blue" "Menyiapkan SSL..."
            certbot certonly --nginx -d "$domainphp"

            # Permissions and config
            chown -R www-data:www-data *
            mkdir config
            chmod o+rw config
            cp config.sample.inc.php config/config.inc.php
            chmod o+w config/config.inc.php

            # Nginx configuration for PHPMyAdmin
            print_color "blue" "Menyiapkan konfigurasi Nginx..."
            nano /etc/nginx/sites-available/phpmyadmin.conf

            # Restart nginx
            systemctl restart nginx
            print_color "green" "TERIMAKASIH SUDAH PAKAI AUTO INSTALLER PHPMYADMIN BY FAJAR OFFICIAL"
            break

        else
            print_color "yellow" "Instalasi PHPMyAdmin dibatalkan."
            break
        fi

    # Jika memilih Create Database
    elif [[ "$choice" == "2" ]]; then
        print_color "magenta" "CREATE DATABASE BY FAJAR OFFC"
        echo ""
        
        # Masukkan detail database
        read -p "Masukkan Username Database: " dbuser
        read -p "Masukkan IP untuk akses database: " ipdb
        read -p "Masukkan Password Database: " pwdb
        print_color "yellow" "Anda memilih Database User: $dbuser, IP: $ipdb"

        read -p "Apakah Anda yakin untuk membuat database dan user? (y/n): " confirm
        if [[ "$confirm" == "y" || "$confirm" == "Y" ]]; then
            # Membuat Database dan User
            print_color "blue" "Membuat Database dan User..."
            
            mysql -u root -p <<EOF
CREATE USER '$dbuser'@'$ipdb' IDENTIFIED BY '$pwdb';
GRANT ALL PRIVILEGES ON *.* TO '$dbuser'@'$ipdb' WITH GRANT OPTION;
FLUSH PRIVILEGES;
EOF

            print_color "green" "DATABASE SUDAH DI BUAT BY FAJAR OFFC YAITU: $dbuser"
            break

        else
            print_color "yellow" "Pembuatan database dibatalkan."
            break
        fi

    # Jika memilih Exit
    elif [[ "$choice" == "3" ]]; then
        print_color "cyan" "Keluar dari Auto Installer..."
        break

    else
        print_color "red" "Pilihan tidak valid. Silakan pilih 1, 2, atau 3."
    fi
done

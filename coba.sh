#!/bin/bash

# Fungsi untuk menampilkan teks besar dengan warna
function print_title() {
    echo -e "\e[1;32m"  # Mengaktifkan warna hijau dan teks tebal
    echo "=========================================="
    echo "        AUTO INSTALLER BY FAJAR OFFICIAL"
    echo "=========================================="
    echo -e "\e[0m"  # Menonaktifkan format warna dan teks tebal
}

# Fungsi untuk menampilkan teks berjalan dengan warna
function print_scrolling_text() {
    echo -ne "\e[1;33mSelamat datang, saya adalah FAJAR OFFC Auto Installer\e[0m"
    for i in {1..5}; do
        echo -ne "."; sleep 0.5
    done
    echo ""
}

# Menampilkan judul besar
print_title

# Meminta token pengguna
read -p "Masukkan token Anda: " user_token
EXPECTED_TOKEN="YOUR_EXPECTED_TOKEN"

# Verifikasi token
if [ "$user_token" != "$EXPECTED_TOKEN" ]; then
    echo -e "\e[1;31mToken salah. Silakan beli di FAJAR OFFC.\e[0m"  # Teks merah untuk kesalahan token
    exit 1
fi

echo -e "\e[1;32mLogin sukses!\e[0m"  # Teks hijau untuk login sukses

# Menampilkan teks berjalan
print_scrolling_text

while true; do
    # Menu untuk memilih aksi
    echo "Pilih opsi:"
    echo "1. Buat Database"
    echo "2. Install phpMyAdmin"
    echo "3. Keluar"
    read -p "Masukkan pilihan Anda [1, 2, atau 3]: " choice

    case $choice in
        1)
            # Meminta detail database dari pengguna
            read -p "Masukkan nama pengguna database: " DB_USER
            read -p "Masukkan host database: " DB_HOST
            read -sp "Masukkan kata sandi pengguna database: " DB_PASS
            echo ""

            # Membuat pengguna database
            mysql -u root -p <<MYSQL_SCRIPT
CREATE USER '${DB_USER}'@'${DB_HOST}' IDENTIFIED BY '${DB_PASS}';
GRANT ALL PRIVILEGES ON *.* TO '${DB_USER}'@'${DB_HOST}' WITH GRANT OPTION;
MYSQL_SCRIPT
            echo "Pengguna database dibuat."
            ;;
        
        2)
            # Meminta domain untuk phpMyAdmin
            read -p "Masukkan domain Anda: " DOMAIN
            
            # Install phpMyAdmin
            mkdir -p /var/www/phpmyadmin && mkdir /var/www/phpmyadmin/tmp/ && cd /var/www/phpmyadmin
            wget https://www.phpmyadmin.net/downloads/phpMyAdmin-latest-english.tar.gz
            tar xvzf phpMyAdmin-latest-english.tar.gz
            mv /var/www/phpmyadmin/phpMyAdmin-*-english/* /var/www/phpmyadmin
            echo "phpMyAdmin terpasang."

            # Membuat sertifikat SSL
            certbot certonly --nginx -d ${DOMAIN}
            echo "Sertifikat SSL dibuat untuk ${DOMAIN}."

            # Mengatur izin dan konfigurasi
            chown -R www-data:www-data /var/www/phpmyadmin
            mkdir /var/www/phpmyadmin/config
            chmod o+rw /var/www/phpmyadmin/config
            cp /var/www/phpmyadmin/config.sample.inc.php /var/www/phpmyadmin/config/config.inc.php
            chmod o+w /var/www/phpmyadmin/config/config.inc.php
            echo "Izin dan konfigurasi disetel."

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

    # Izinkan unggahan file yang lebih besar dan runtime skrip yang lebih lama
    client_max_body_size 100m;
    client_body_timeout 120s;

    sendfile off;

    # Konfigurasi SSL
    ssl_certificate /etc/letsencrypt/live/${DOMAIN}/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/${DOMAIN}/privkey.pem;
    ssl_session_cache shared:SSL:10m;
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers 'ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-SHA384:ECDHE-RSA-AES256-SHA384:ECDHE-ECDSA-AES128-SHA256:ECDHE-RSA-AES128-SHA256';
    ssl_prefer_server_ciphers on;

    # Lihat https://hstspreload.org/ sebelum mengomentari baris di bawah ini.
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

            echo "Konfigurasi Nginx disetel untuk phpMyAdmin."

            # Mengaktifkan situs dan restart Nginx
            ln -s /etc/nginx/sites-available/phpmyadmin.conf /etc/nginx/sites-enabled/phpmyadmin.conf
            systemctl restart nginx

            echo "Setup phpMyAdmin selesai. Anda dapat mengaksesnya di https://${DOMAIN}"
            ;;
        
        3)
            echo "Terima kasih telah menggunakan FAJAR OFFC Auto Installer!"
            break
            ;;
        
        *)
            echo -e "\e[43dcd9a7-70db-4a1f-b0ae-981daa162054](https://github.com/RyzeZR/Ryze_Study/tree/c4ba1268831197a3f3df58b4c14bff5968d0475d/henauOJ%2Fdocker_typecho.md?citationMarker=43dcd9a7-70db-4a1f-b0ae-981daa162054 "1")[43dcd9a7-70db-4a1f-b0ae-981daa162054](https://github.com/Palmik/palmik.github.io/tree/d8fce61349ec45cba99d506f25995fb0f17ada62/docs%2Fsearch_index.en.js?citationMarker=43dcd9a7-70db-4a1f-b0ae-981daa162054 "2")[43dcd9a7-70db-4a1f-b0ae-981daa162054](https://github.com/temp69/yiimp_install_script/tree/929950dcedf3af1cd0a830bda6c3acf7ec229a17/install.sh?citationMarker=43dcd9a7-70db-4a1f-b0ae-981daa162054 "3")[43dcd9a7-70db-4a1f-b0ae-981daa162054](https://github.com/devserge/Pterodactyl-Installation-Script/tree/ca49e08ea407dd35192deca1c6e48e37fb7f5a90/install.sh?citationMarker=43dcd9a7-70db-4a1f-b0ae-981daa162054 "4")[43dcd9a7-70db-4a1f-b0ae-981daa162054](https://github.com/sharletp/cubeshostvpsservice/tree/f67dd7680c5fea3bb37a25947e9fb82c02fa48a5/panel%2Fpterodactyl%2Finstaller.sh?citationMarker=43dcd9a7-70db-4a1f-b0ae-981daa162054 "5")[43dcd9a7-70db-4a1f-b0ae-981daa162054](https://github.com/ArnyDaHamsta/nginxconfigcreator/tree/5ad40a18d56f5049452707ee8028bba457c21757/makenginx.sh?citationMarker=43dcd9a7-70db-4a1f-b0ae-981daa162054 "6")[43dcd9a7-70db-4a1f-b0ae-981daa162054](https://github.com/youthfulzone/karaokemumbe/tree/4c9b2e821ab559d6f0943aa3a82a6feb791ae973/setup.sh?citationMarker=43dcd9a7-70db-4a1f-b0ae-981daa162054 "7")
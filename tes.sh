#!/bin/bash

# Define colors
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

clear

# Display the title
echo -e "${BLUE}=========================="
echo -e "    AUTO INSTALLER FAJAR OFFC"
echo -e "==========================${NC}"

# Menu function
menu() {
    clear
    echo -e "${YELLOW}AUTO INSTALLER BY FAJAR OFFICIAL${NC}"
    echo -e "${BLUE}Please select an option:${NC}"
    echo -e "${GREEN}1) Install phpMyAdmin${NC}"
    echo -e "${GREEN}2) Create Database${NC}"
    echo -e "${RED}3) Exit${NC}"
}

# Confirm function
confirm() {
    read -p "Are you sure? (y/n): " choice
    case "$choice" in
        y|Y ) return 0 ;;
        n|N ) return 1 ;;
        * ) echo -e "${RED}Invalid choice!${NC}"; confirm ;;
    esac
}

# Install phpMyAdmin
install_phpmyadmin() {
    clear
    echo -e "${BLUE}==============================="
    echo -e "AUTO INSTALL PHPMYADMIN BY FAJAR OFFICIAL"
    echo -e "===============================${NC}"
    echo -e "${YELLOW}Installing phpMyAdmin...${NC}"

    # Commands to install phpMyAdmin
    mkdir /var/www/phpmyadmin && mkdir /var/www/phpmyadmin/tmp/ && cd /var/www/phpmyadmin
    wget https://www.phpmyadmin.net/downloads/phpMyAdmin-latest-english.tar.gz
    tar xvzf phpMyAdmin-latest-english.tar.gz
    mv /var/www/phpmyadmin/phpMyAdmin-*-english/* /var/www/phpmyadmin
    chown -R www-data:www-data *
    mkdir config
    chmod o+rw config
    cp config.sample.inc.php config/config.inc.php
    chmod o+w config/config.inc.php

    echo -e "${GREEN}phpMyAdmin installed successfully.${NC}"
    echo -e "${GREEN}Thank you for using AUTO INSTALLER PHPMYADMIN BY FAJAR OFFICIAL${NC}"
}

# Create Database
create_database() {
    clear
    echo -e "${BLUE}==============================="
    echo -e "CREATE DATABASE BY FAJAR OFFC"
    echo -e "===============================${NC}"
    echo -e "${YELLOW}Creating Database...${NC}"

    # Collect database details
    read -p "Enter database user: " dbuser
    read -p "Enter database user IP: " dbhost
    read -sp "Enter database password: " dbpass
    echo

    # MySQL commands
    mysql -u root -p -e "CREATE USER '$dbuser'@'$dbhost' IDENTIFIED BY '$dbpass';"
    mysql -u root -p -e "GRANT ALL PRIVILEGES ON *.* TO '$dbuser'@'$dbhost' WITH GRANT OPTION;"

    echo -e "${GREEN}Database created successfully by FAJAR OFFC.${NC}"
    echo -e "${GREEN}DATABASE SUDAH DI BUAT BY FAJAR OFFC YAITU${NC}"
}

# Main loop
while true; do
    menu
    read -p "Select an option [1-3]: " opt
    case $opt in
        1)
            if confirm; then
                install_phpmyadmin
            else
                echo -e "${RED}Operation canceled.${NC}"
            fi
            ;;
        2)
            if confirm; then
                create_database
            else
                echo -e "${RED}Operation canceled.${NC}"
            fi
            ;;
        3)
            echo -e "${GREEN}Exiting...${NC}"
            break
            ;;
        *)
            echo -e "${RED}Invalid option!${NC}"
            ;;
    esac
    # Wait for user input to return to menu
    read -p "Press Enter to continue..."
done

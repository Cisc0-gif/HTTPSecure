#! /bin/bash

RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

wait_func() {
read -p "PRESS ENTER TO CONTINUE" wait
}

printf "${BLUE}[*] Setting Up SSL Configuration For Apache2 Server...${NC}\n"
sudo mkdir /tmp/sslcerts
cd /tmp/sslcerts
printf "${BLUE}[*] Creating SSL Server Key...${NC}\n"
sudo openssl genrsa -des3 -out server.key 4096
if [ -f "server.key" ]; then
  printf "${BLUE}[*] Creating and Encrypting Certificate Signing Request...${NC}\n"
  sudo openssl req -new -key server.key -out server.csr
  if [ -f "server.csr" ]; then
    printf "${BLUE}[*] Creating, Encrypting, and Signing Certificate...${NC}\n"
    sudo openssl x509 -req -days 365 -in server.csr -signkey server.key -out server.crt
    if [ -f "server.crt" ]; then
      printf "${BLUE}[*] Creating Nopass Key for Apache2 Server...${NC}\n"
      sudo mkdir /etc/apache2/ssl_certs
      sudo openssl rsa -in server.key -out server.key.nopass
      if [ -f "server.key.nopass" ]; then
        printf "${BLUE}[*] Moving Certificate and Key to Apache2 dir and configuring apache2 SSL server...${NC}\n"
        sudo cp server.crt /etc/apache2/ssl_certs
        sudo cp server.key.nopass /etc/apache2/ssl_certs
        cd /etc/apache2/ssl_certs
        sudo mv server.key.nopass server.key
        sudo service apache2 start
        sudo a2enmod ssl
        sudo cp /etc/apache2/sites-enabled/000-default-ssl.conf ./
        sudo mv 000-default.conf 000-default-ssl.conf.backup
        sudo rm /etc/apache2/sites-enabled/000-default-ssl.conf
        sudo ln -s /etc/apache2/sites-available/default-ssl.conf /etc/apache2/sites-enabled/000-default-ssl.conf
        printf "${BLUE}[*] Type 'ServerName YOURIP:443' under '<VirtualHost_default_:443>' ${NC}\n"
        printf "${BLUE}[*] Change SSLCertificateFile to '/etc/apache2/ssl_certs/server.crt'${NC}\n"
        printf "${BLUE}[*] Change SSLCertificateKeyFile to '/etc/apache2/ssl_certs/server.key'${NC}\n"
        wait_func
        sudo nano /etc/apache2/sites-available/default-ssl.conf
        sudo service apache2 restart
        printf "${GREEN}[+] Server Migrated To SSL Scheme (HTTPS)!${NC}\n"
        exit 1
      else
        printf "${RED}[!] Error Creating Passwordless Key...${NC}\n"
        exit 1
      fi
    else
      printf "${RED}[!] Error Creating Certificate...${NC}\n"
      exit 1
    fi
  else
    printf "${RED}[!] Error Creating Certificate Signing Requests...${NC}\n"
    exit 1
  fi
else
  printf "${RED}[!] Error Creating SSL Key...${NC}\n"
  exit 1
fi

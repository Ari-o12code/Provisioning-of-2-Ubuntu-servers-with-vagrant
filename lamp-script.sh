#!/bin/bash

# Database Configuration
DB_CONNECTION=mysql
DB_DATABASE=laravel
DB_HOST=localhost
DB_PORT=3306
DB_USERNAME=root
DB_PASSWORD=alameenalm

# Update package repositories
sudo add-apt-repository ppa:ondrej/php
sudo apt update

# Install MySQL server
sudo apt install -y mysql-server
sudo systemctl enable --now mysql

# Secure MySQL installation
sudo mysql -u $DB_USERNAME -p"$DB_PASSWORD" -e "ALTER USER 'root'@'localhost' IDENTIFIED WITH mysql_native_password BY '$DB_PASSWORD'; FLUSH PRIVILEGES;"

# Create MySQL database
sudo mysql -u $DB_USERNAME -p"$DB_PASSWORD" -e "CREATE DATABASE IF NOT EXISTS $DB_DATABASE DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"

# Install Apache and PHP
sudo apt install -y apache2
sudo apt install -y php8.2 php8.2-xml php8.2-mbstring php8.2-dom php8.2-zip php8.2-curl php8.2-redis php8.2-gd php8.2-intl php8.2-bcmath php8.2-mysql zip unzip

# Install Git
sudo apt install -y git

# Check if PHP is installed and install Composer
if command -v php &>/dev/null; then
    sudo php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');"
    sudo php composer-setup.php --install-dir=/usr/local/bin --filename=composer
    sudo rm composer-setup.php
else
    echo "PHP is not installed. Please install PHP before running this script."
    exit 1
fi

# Clone Laravel application
cd /var/www/html
sudo git clone https://github.com/laravel/laravel.git 
cd laravel

# Set up Laravel environment file
sudo cp .env.example .env
sed -i "s/^DB_CONNECTION=.*/DB_CONNECTION=$DB_CONNECTION/" .env
sed -i "s/^# DB_DATABASE=.*/DB_DATABASE=$DB_DATABASE/" .env
sed -i "s/^# DB_HOST=.*/DB_HOST=$DB_HOST/" .env
sed -i "s/^# DB_PORT=.*/DB_PORT=$DB_PORT/" .env
sed -i "s/^# DB_USERNAME=.*/DB_USERNAME=$DB_USERNAME/" .env
sed -i "s/^# DB_PASSWORD=.*/DB_PASSWORD=$DB_PASSWORD/" .env
sudo chmod 660 .env
sudo chown www-data:www-data .env

# Install Laravel dependencies
composer install --no-interaction
composer update

# Generate Laravel application key
sudo -u www-data php artisan key:generate
sudo php artisan migrate --seed

# Configure Apache virtual host
sudo tee /etc/apache2/sites-available/laravel-app.conf >/dev/null <<EOF
<VirtualHost *:80>
    ServerAdmin quadrameen@gmail.com
    ServerName laravel-app.local
    DocumentRoot /var/www/html/laravel/public
    <Directory /var/www/html/laravel/public>
        Options -Indexes +FollowSymLinks
        AllowOverride All
        Require all granted
    </Directory>
    ErrorLog \${APACHE_LOG_DIR}/laravel-error.log
    CustomLog \${APACHE_LOG_DIR}/laravel-access.log combined
    <IfModule mod_dir.c>
        DirectoryIndex index.php
    </IfModule>
</VirtualHost>
EOF

# Set permissions for Laravel storage and cache directories
sudo chown -R www-data:www-data /var/www/html/laravel/
sudo chown -R www-data:www-data /var/www/html/laravel/storage 
sudo chown -R www-data:www-data /var/www/html/laravel/bootstrap/cache
sudo chmod -R ug+rwx /var/www/html/laravel/storage 
sudo chmod -R ug+rwx /var/www/html/laravel/bootstrap/cache

# Enable the Laravel virtual host
sudo a2dissite 000-default.conf
sudo a2ensite laravel-app.conf
sudo systemctl reload apache2
sudo systemctl restart apache2

echo "LAMP stack set up and Laravel application deployment is complete."

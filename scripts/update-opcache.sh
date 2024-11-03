#!/bin/bash
# scripts/update-opcache.sh

# Load environment variables
if [ -f .env ]; then
    export $(cat .env | grep -E "^PHP_OPCACHE_" | xargs)
fi

# Default value if not set
PHP_OPCACHE_ENABLE="${PHP_OPCACHE_ENABLE:-1}"

echo "Updating OPcache settings..."

# Update php.ini in the running container
docker compose exec php bash -c "sed -i 's/opcache.enable =.*/opcache.enable = ${PHP_OPCACHE_ENABLE}/' /usr/local/etc/php/php.ini"
docker compose exec php bash -c "sed -i 's/opcache.enable_cli =.*/opcache.enable_cli = ${PHP_OPCACHE_ENABLE}/' /usr/local/etc/php/php.ini"

# Reload PHP-FPM
docker compose exec php bash -c "kill -USR2 1"

# Verify the changes
echo "Current OPcache settings:"
docker compose exec php bash -c "php -i | grep -i opcache.enable"
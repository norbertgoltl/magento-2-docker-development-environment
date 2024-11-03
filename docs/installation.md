# Magento 2.4.7 Installation Guide

## Verify Prerequisites

✅ PHP 8.3 - Satisfied (php:8.3-fpm image)
✅ MariaDB 10.6 - Satisfied (mariadb:10.6 image)
✅ OpenSearch 2.12 - Satisfied (opensearchproject/opensearch:2.12.0 image)
✅ Redis 7.2 - Satisfied (redis:7.2-alpine image)
✅ RabbitMQ 3.13 - Satisfied (rabbitmq:3.13-management-alpine image)
✅ Nginx 1.24 - Satisfied (nginx:1.24-alpine image)
✅ Composer 2.7 - Satisfied (composer:2.7 image)

## 1. Set Environment Variables

Create/Modify the `.env` file in the project root to configure the Docker services:

```env
# Project
COMPOSE_PROJECT_NAME=magento-local

# Database
MYSQL_ROOT_PASSWORD=magento
MYSQL_DATABASE=magento
MYSQL_USER=magento
MYSQL_PASSWORD=magento

# Redis
REDIS_PASSWORD=magento

# RabbitMQ
RABBITMQ_DEFAULT_USER=magento
RABBITMQ_DEFAULT_PASS=magento

# PHP
PHP_MEMORY_LIMIT=4G
PHP_OPCACHE_REVALIDATE_FREQ=0
PHP_MAX_EXECUTION_TIME=1800

# OpenSearch
OPENSEARCH_DISABLE_SECURITY=true
OPENSEARCH_DISABLE_DEMO=true
OPENSEARCH_JAVA_OPTS=-Xms512m -Xmx512m
```

## 2. Start the Docker Environment

```bash
# Start all services
docker compose --profile full up -d

# Check services status
docker compose ps
```

Wait until all services are in "healthy" status.

## 3. Install Magento

### 3.1. Prepare Directory Structure

```bash
# Delete src directory (if exists)
rm -rf src
mkdir src
```

### 3.2. Download Magento

```bash
# Download Magento with Composer
docker compose run --rm php composer create-project --repository-url=https://repo.magento.com/ magento/project-community-edition:2.4.7 .
```

When prompted:

1. Provide your Magento Marketplace authentication credentials:
   - Username: Your `Public Key`
   - Password: Your `Private Key`
2. Answer `yes` to the "Do you want to store credentials for repo.magento.com in /var/www/.composer/auth.json ?" question

### 3.3. Set Permissions

```bash
# Set permissions
docker compose exec php chmod -R 777 var generated pub/static pub/media app/etc
```

### 3.4. Install Magento

```bash
docker compose exec php bin/magento setup:install \
  --base-url=http://localhost/ \
  --db-host=mariadb \
  --db-name=magento \
  --db-user=magento \
  --db-password=magento \
  --admin-firstname=Admin \
  --admin-lastname=User \
  --admin-email=admin@example.com \
  --admin-user=admin \
  --admin-password=admin123 \
  --language=en_US \
  --currency=USD \
  --timezone=America/New_York \
  --use-rewrites=1 \
  --search-engine=opensearch \
  --opensearch-host=opensearch \
  --opensearch-port=9200 \
  --opensearch-index-prefix=magento2 \
  --opensearch-enable-auth=0 \
  --cache-backend=redis \
  --cache-backend-redis-server=redis \
  --cache-backend-redis-port=6379 \
  --cache-backend-redis-password=magento \
  --cache-backend-redis-db=0 \
  --page-cache=redis \
  --page-cache-redis-server=redis \
  --page-cache-redis-port=6379 \
  --page-cache-redis-password=magento \
  --page-cache-redis-db=1 \
  --session-save=redis \
  --session-save-redis-host=redis \
  --session-save-redis-port=6379 \
  --session-save-redis-password=magento \
  --session-save-redis-db=2 \
  --amqp-host=rabbitmq \
  --amqp-port=5672 \
  --amqp-user=magento \
  --amqp-password=magento
```

## 4. Post-Installation Setup

### 4.1. Set Developer Mode

```bash
# Set developer mode
docker compose exec php bin/magento deploy:mode:set developer

# Deploy static content
docker compose exec php bin/magento setup:static-content:deploy -f en_US

# Flush cache
docker compose exec php bin/magento cache:flush
```

### 4.2. Rebuild Indexes

```bash
docker compose exec php bin/magento indexer:reindex
```

## 5. Disable Two-Factor Authentication (2FA)

Magento 2.4.7 is installed with 2FA enabled by default. It is usually disabled in a development environment:

```bash
# Disable Adobe IMS 2FA module
docker compose exec php bin/magento module:disable Magento_AdminAdobeImsTwoFactorAuth

# Disable base 2FA module
docker compose exec php bin/magento module:disable Magento_TwoFactorAuth

# Flush cache
docker compose exec php bin/magento cache:flush

# Update database schema and data
docker compose exec php bin/magento setup:upgrade
```

## 6. Verify Installation

After the installation, check the following URLs:

- Frontend: http://localhost/
- Admin: http://localhost/admin_XXXXX
  - The admin URL is unique, generated during installation
  - Username: admin
  - Password: admin123
- OpenSearch: http://localhost:9200
- RabbitMQ: http://localhost:15672
  - Username: magento
  - Password: magento

## 7. Troubleshooting

### Cache Issues

```bash
# Flush all caches
docker compose exec php bin/magento cache:flush

# Clean var directory
docker compose exec php rm -rf var/cache/* var/page_cache/* var/view_preprocessed/*
```

### Permissions Issues

```bash
# Reset permissions
docker compose exec php chmod -R 777 var generated pub/static pub/media app/etc
```

### Database Issues

```bash
# Check database access
docker compose exec mariadb mysql -u magento -pmagento magento

# Check user permissions
docker compose exec mariadb mysql -u root -pmagento -e "SHOW GRANTS FOR 'magento'@'%';"

# Recreate database (if needed)
docker compose exec mariadb mysql -u root -pmagento -e "DROP DATABASE magento; CREATE DATABASE magento;"
```

### OpenSearch Issues

```bash
# Check OpenSearch status
curl http://localhost:9200/_cluster/health?pretty

# List indices
curl http://localhost:9200/_cat/indices?v
```

### Restart Services

```bash
# Restart all services
docker compose --profile full restart

# Restart a specific service
docker compose restart [service-name]
```

### Rebuild Environment

```bash
# Stop and remove containers with volumes
docker compose down -v

# Check and remove volumes if needed
docker volume ls
docker volume rm magento-local_mariadb_data

# Restart the environment
docker compose --profile full up -d
```

## Additional Notes

- Use the `.env` file only for configuring Docker services
- Explicitly provide Magento installation parameters for secure operation
- The Docker environment has different profiles (web, db, cache, search, queue, full)
- Monitor the health status of the services during the installation
- Composer authentication credentials are preserved for future installations
- Do not version control the `.env` file, use `.env.example` instead
- The Docker environment meets all system requirements for Magento 2.4.7
- Magento 2.4.x versions are installed with two-factor authentication (2FA) enabled by default
- It is recommended to disable 2FA in a development environment for easier access

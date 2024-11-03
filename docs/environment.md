# Magento 2 Development Environment Documentation

## Overview

This document provides a comprehensive overview of the Docker-based development environment for Magento 2. The environment is designed to meet the requirements of Magento 2.4.x and follows modern Docker best practices.

Last updated: 2024-11-03

## Environment Structure

### Directory Layout

```
.
├── .docker/                   # Docker configuration files
│   ├── nginx/                 # Nginx configurations
│   │   ├── Dockerfile
│   │   ├── nginx.conf         # Main Nginx config
│   │   └── default.conf       # Magento-specific config
│   └── php/                   # PHP configurations
│       ├── Dockerfile
│       ├── php.ini            # PHP settings
│       └── php-fpm.conf       # PHP-FPM settings
├── backups/                   # Environment backups
├── docs/                      # Project documentation
│   ├── environment.md         # Environment documentation
│   ├── installation_hu.md     # Installation guide (Hungarian)
│   ├── installation.md        # Installation guide
│   ├── profiles.md            # Docker Compose profiles doc
│   └── README.md              # Main documentation overview
├── src/                       # Magento source code
├── volumes/                   # Docker volume data
│   ├── mysql_data/            # MySQL data
│   ├── redis_data/            # Redis data
│   ├── opensearch_data/       # OpenSearch data
│   └── rabbitmq_data/         # RabbitMQ data
├── .env                       # Environment variables (not in git)
└── .env.example               # Example environment variables template
```

### Core Services

| Service    | Version | Purpose                 | Port(s)         | Default Credentials                  |
| ---------- | ------- | ----------------------- | --------------- | ------------------------------------ |
| Nginx      | 1.24    | Web Server              | 80, 443         | N/A                                  |
| PHP        | 8.3     | Application Server      | 9000 (internal) | N/A                                  |
| MySQL      | 8.0     | Database                | 3306            | user: magento<br>password: from .env |
| Redis      | 7.2     | Cache & Session Storage | 6379            | password: from .env                  |
| OpenSearch | 2.12    | Search Engine           | 9200, 9300      | disabled security                    |
| RabbitMQ   | 3.13    | Message Queue           | 5672, 15672     | user: magento<br>password: from .env |

## Initial Setup Steps

### 1. Create Directory Structure

```bash
# Create base directories
mkdir -p src volumes/{mysql_data,redis_data,opensearch_data,rabbitmq_data} var/log/{nginx,php,mysql} var/composer backups
```

### 2. Setup Environment File

```bash
# Copy example environment file
cp .env.example .env

# Edit the .env file with your preferred settings
# Especially change the passwords for security
```

### 3. Setup Magento Source

```bash
# For new projects
git clone <magento-repository-url> src

# OR for existing projects
cp -r /path/to/your/existing/magento/project src/
```

### 4. Set Magento Permissions

```bash
# Set write permissions for www-data user
chmod -R 777 src/var src/generated src/pub/static src/pub/media app/etc
```

### 5. Start Docker Environment

```bash
# Start full stack
docker compose --profile full up -d

# OR start specific services
docker compose --profile web --profile db up -d
```

### 6. Verify Installation

```bash
# Check service status
docker compose ps

# Check logs
docker compose logs

# Access PHP container
docker compose exec php bash
```

## Environment Configuration

### PHP Configuration

#### General Settings

All PHP configurations are managed through environment variables in the `.env` file:

| Variable                    | Default | Purpose                                        |
| --------------------------- | ------- | ---------------------------------------------- |
| PHP_MEMORY_LIMIT            | 4G      | PHP memory limit                               |
| PHP_MAX_EXECUTION_TIME      | 1800    | Maximum execution time                         |
| PHP_OPCACHE_REVALIDATE_FREQ | 0       | How often to check file timestamps for changes |

#### OPcache Management

OPcache is enabled by default in the PHP configuration. Here's how to manage it:

1. **View Current OPcache Status**:

```bash
docker compose exec php php -i | grep -i "opcache\.enable"
```

2. **Disable OPcache** (both web and CLI modes):

```bash
docker compose exec -u root php bash -c 'echo -e "opcache.enable=0\nopcache.enable_cli=0" > /usr/local/etc/php/conf.d/custom-opcache.ini'
docker compose restart php
```

3. **Re-enable OPcache** (return to default settings):

```bash
docker compose exec -u root php bash -c 'rm -f /usr/local/etc/php/conf.d/custom-opcache.ini'
docker compose restart php
```

The status output should show something like:

```
# When disabled:
opcache.enable => Off => Off
opcache.enable_cli => Off => Off

# When enabled (default):
opcache.enable => On => On
opcache.enable_cli => On => On
```

> **Note**: Changes to OPcache settings require a container restart to take effect.
> **Note**: The commands use root user (-u root) because the configuration directory requires elevated permissions.
> **Note**: These settings affect both web (PHP-FPM) and CLI modes of PHP operation.

### Database Configuration

MySQL settings are configured through environment variables:

```env
MYSQL_ROOT_PASSWORD=change_this_password
MYSQL_DATABASE=magento
MYSQL_USER=magento
MYSQL_PASSWORD=change_this_password
```

### Cache Configuration

Redis settings for caching:

```env
REDIS_PASSWORD=change_this_password
```

### Search Configuration

OpenSearch settings:

```env
OPENSEARCH_DISABLE_SECURITY=true
OPENSEARCH_DISABLE_DEMO=true
OPENSEARCH_JAVA_OPTS=-Xms512m -Xmx512m
```

### Message Queue Configuration

RabbitMQ settings:

```env
RABBITMQ_DEFAULT_USER=magento
RABBITMQ_DEFAULT_PASS=change_this_password
```

## Service Profiles

The environment uses Docker Compose profiles for flexible service management:

| Profile | Services Included | Use Case             |
| ------- | ----------------- | -------------------- |
| web     | nginx, php        | Frontend development |
| db      | mysql             | Database work        |
| cache   | redis             | Cache management     |
| search  | opensearch        | Search development   |
| queue   | rabbitmq          | Queue management     |
| full    | all services      | Full stack           |

### Using Profiles

```bash
# Start all services
docker compose --profile full up -d

# Start only web and database
docker compose --profile web --profile db up -d
```

## Resource Management

### Memory Allocation

- PHP: 4GB
- MySQL: 2GB
- OpenSearch: 2GB (1GB reserved)
- Redis: 512MB
- RabbitMQ: 512MB
- Nginx: 1GB

### CPU Allocation

- PHP: 2 cores
- MySQL: 2 cores
- OpenSearch: 1 core
- Redis: 0.5 core
- RabbitMQ: 0.5 core
- Nginx: 1 core

## Development Features

### Auto-reload

- Source code changes are automatically synced
- Nginx configuration changes are monitored
- PHP configuration changes require container restart or update script

### Debugging

- Xdebug ready (disabled by default)
- Log access through mounted volumes
- Health checks for all services

## Backup and Restore

### Environment Backup

The environment comes with comprehensive backup capabilities through the `env-backup.sh` script:

```bash
./scripts/env-backup.sh
```

This creates a timestamped backup in the `backups/` directory containing:

- Database dump (with triggers and routines)
- Redis data snapshot
- Media files
- Environment configuration

Each backup includes:

- `database.sql`: Complete database dump
- `redis_data/`: Redis data snapshot
- `media.tar.gz`: Media files archive
- `.env.backup`: Environment configuration backup
- `backup-info.txt`: Backup metadata and status

### Environment Restore

To restore a complete environment backup:

```bash
./scripts/env-restore.sh backups/[timestamp]
# OR
./scripts/env-restore.sh backups/latest
```

The restore process:

1. Stops all services
2. Restores environment configuration
3. Starts core services
4. Restores database with all structures
5. Restores Redis data
6. Restores media files
7. Restarts all services

### Backup Safety Features

- Timestamped backups
- Latest backup symlink
- Pre-restore validation
- Service health checks
- Detailed logging
- Error handling

### Best Practices

1. Create regular backups
2. Verify backup contents before restore
3. Keep multiple backup versions
4. Test restore process periodically
5. Document any custom configurations in backup-info.txt

## Known Issues and Solutions

1. **Permission Issues**

   - Symptom: File permission errors
   - Solution: Run `docker compose exec php chown -R www-data:www-data .`

2. **Memory Limits**

   - Symptom: PHP out of memory
   - Solution: Increase `PHP_MEMORY_LIMIT` in `.env`

3. **Container Startup Order**

   - Symptom: Services fail to start due to dependencies
   - Solution: Use `docker compose --profile full up -d` to ensure proper startup order

4. **Redis Authentication Issues**

   - Symptom: Redis connection errors
   - Solution: Ensure `REDIS_PASSWORD` is set in `.env`

5. **Configuration Changes Not Applied**
   - Symptom: Environment variable changes not taking effect after restart
   - Solution: Use `docker compose up -d --force-recreate [service]` instead of `restart`

## Version History

| Date       | Version | Changes                                       |
| ---------- | ------- | --------------------------------------------- |
| 2024-11-03 | 1.0     | Initial setup with Docker Compose 2.x support |

## Additional Resources

- Project README: [README.md](README.md)
- Docker Compose Documentation: [https://docs.docker.com/compose/](https://docs.docker.com/compose/)
- Magento DevDocs: [https://devdocs.magento.com/](https://devdocs.magento.com/)

## Contributing

Please read our [Contributing Guidelines](CONTRIBUTING.md) before making any changes.

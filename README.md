# Magento 2 Docker Development Environment

This is a modern Docker development environment for Magento 2, supporting the latest Magento Commerce 2.4.x requirements with performance and developer experience in mind.

## Features

- PHP 8.3/8.2 with all required extensions
- MySQL 8.0
- OpenSearch 2.12
- Redis 7.2
- RabbitMQ 3.13
- Nginx 1.24
- Composer 2.7
- Development-oriented configuration
- Resource management
- Automatic file synchronization
- Health monitoring
- Profile-based service management
- Environment backup and restore functionality

## Requirements

- Docker Engine 24.0+
- Docker Compose v2.20.0+
- Git
- At least 8GB of RAM dedicated to Docker

## Directory Structure

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

## Initial Setup Steps

1. Clone this repository:

```bash
git clone git@github.com:norbertgoltl/magento-2-docker-development-environment.git
cd magento-2-docker-development-environment
```

2. Create required directories:

```bash
mkdir -p src volumes/{mysql_data,redis_data,opensearch_data,rabbitmq_data} var/log/{nginx,php,mysql} var/composer backups
```

3. Set up environment variables:

```bash
cp .env.example .env
# Edit .env file with your preferred settings
```

4. Install Magento in the `src` directory (choose one method):

   a. Fresh installation:

   ```bash
   git clone <magento-repository-url> src
   ```

   b. Existing project:

   ```bash
   cp -r /path/to/your/magento src
   ```

5. Set proper permissions:

```bash
chmod -R 777 src/var src/generated src/pub/static src/pub/media app/etc
```

## Usage

### Starting the Environment

You can start services using different profiles based on your needs:

```bash
# Full stack
docker compose --profile full up -d

# Only web stack (nginx + php)
docker compose --profile web up -d

# Only database
docker compose --profile db up -d

# Only cache (Redis)
docker compose --profile cache up -d

# Only search (OpenSearch)
docker compose --profile search up -d

# Only message queue (RabbitMQ)
docker compose --profile queue up -d
```

### Environment Backup and Restore

#### Creating a Backup

To create a complete environment backup:

```bash
./scripts/env-backup.sh
```

This creates a timestamped backup in the `backups/` directory containing:

- Database dump (including triggers and routines)
- Redis data snapshot
- Media files
- Environment configuration

The latest backup is always available at `backups/latest`.

#### Restoring from Backup

To restore a complete environment:

```bash
# Restore from specific backup
./scripts/env-restore.sh backups/[timestamp]

# Or restore from latest backup
./scripts/env-restore.sh backups/latest
```

### Verifying Services

1. Check container status:

```bash
docker compose ps
```

2. Check MySQL:

```bash
docker compose exec mysql mysql -u magento -p
```

3. Check Redis:

```bash
docker compose exec redis redis-cli -a yourpassword ping
```

4. Check OpenSearch:

```bash
curl http://localhost:9200
```

5. Check RabbitMQ:

```bash
# Open in browser
http://localhost:15672
# Login with credentials from .env file
```

### Development Mode

To enable automatic file synchronization during development:

```bash
docker compose watch
```

### Accessing Services

- Magento Frontend: http://localhost
- Magento Admin: http://localhost/admin
- OpenSearch: http://localhost:9200
- RabbitMQ Management: http://localhost:15672

### Service Management

Check service health:

```bash
docker compose ps
```

View logs:

```bash
# All services
docker compose logs

# Specific service
docker compose logs php
```

Restart services:

```bash
docker compose restart [service-name]
```

## Configuration

### Environment Variables

Core environment variables are defined in `.env` file:

- `COMPOSE_PROJECT_NAME`: Project namespace
- `PHP_MEMORY_LIMIT`: PHP memory limit
- `MYSQL_ROOT_PASSWORD`: MySQL root password
- `MYSQL_USER`: MySQL user
- `MYSQL_PASSWORD`: MySQL password
- `REDIS_PASSWORD`: Redis password
- `RABBITMQ_DEFAULT_USER`: RabbitMQ user
- `RABBITMQ_DEFAULT_PASS`: RabbitMQ password

See `.env.example` for all available options.

## Documentation

- [Environment Documentation](docs/environment.md) - Detailed technical documentation
- [Profiles Documentation](docs/profiles.md) - Docker Compose profiles documentation

## Troubleshooting

1. **Permission Issues**

   - Symptom: File permission errors
   - Solution: Run `docker compose exec php chown -R www-data:www-data .`

2. **Memory Limits**

   - Symptom: PHP out of memory
   - Solution: Adjust memory_limit in .env file

3. **Container Dependencies**

   - Symptom: Services fail to start
   - Solution: Use `docker compose --profile full up -d` to ensure proper startup order

4. **Redis Authentication**
   - Symptom: Redis connection errors
   - Solution: Ensure REDIS_PASSWORD is properly set in .env file

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Contributing

Please read our [Contributing Guidelines](CONTRIBUTING.md) before making any changes.

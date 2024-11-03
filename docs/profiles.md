# Docker Compose Profiles

This document describes the available profiles in the Docker Compose configuration and their use cases.

## Available Profiles

### `full`

Includes all services for a complete Magento 2 stack:

- Nginx
- PHP-FPM
- MySQL
- Redis
- OpenSearch
- RabbitMQ

Usage:

```bash
docker compose --profile full up -d
```

### `web`

Includes only web-related services:

- Nginx
- PHP-FPM

Useful for when you're working with an external database and services.

Usage:

```bash
docker compose --profile web up -d
```

### `db`

Database service only:

- MySQL

Useful for database maintenance or when you need to run only the database.

Usage:

```bash
docker compose --profile db up -d
```

### `cache`

Cache service only:

- Redis

Useful for cache maintenance or when you need only the caching service.

Usage:

```bash
docker compose --profile cache up -d
```

### `search`

Search engine service only:

- OpenSearch

Useful for search engine maintenance or reindexing.

Usage:

```bash
docker compose --profile search up -d
```

### `queue`

Message queue service only:

- RabbitMQ

Useful for message queue maintenance or when working with async processes.

Usage:

```bash
docker compose --profile queue up -d
```

## Combining Profiles

You can combine multiple profiles to start only the services you need:

```bash
# Start web stack with database
docker compose --profile web --profile db up -d

# Start web stack with cache
docker compose --profile web --profile cache up -d

# Start everything except queue
docker compose --profile web --profile db --profile cache --profile search up -d
```

## Profile Dependencies

Some profiles have implicit dependencies:

- `web` profile services depend on each other (php depends on nginx)
- Other services are independent and can run standalone

## Resource Usage

Each profile has different resource requirements:

- `web`: ~3GB RAM (Nginx + PHP-FPM)
- `db`: ~2GB RAM (MySQL)
- `cache`: ~512MB RAM (Redis)
- `search`: ~2GB RAM (OpenSearch)
- `queue`: ~512MB RAM (RabbitMQ)
- `full`: ~8GB RAM (All services)

Consider these requirements when combining profiles.

## Common Use Cases

1. **Local Development**

   ```bash
   docker compose --profile full up -d
   ```

2. **Frontend Development**

   ```bash
   docker compose --profile web up -d
   ```

3. **Database Maintenance**

   ```bash
   docker compose --profile db up -d
   ```

4. **Cache Warmup**

   ```bash
   docker compose --profile cache up -d
   ```

5. **Search Reindexing**

   ```bash
   docker compose --profile search up -d
   ```

6. **Queue Processing**
   ```bash
   docker compose --profile queue up -d
   ```

## Profile-Specific Configuration

Each profile respects its relevant environment variables from `.env`:

- `web`: PHP settings, Nginx settings
- `db`: MySQL credentials and configuration
- `cache`: Redis password and settings
- `search`: OpenSearch configuration
- `queue`: RabbitMQ credentials

## Best Practices

1. Start with minimal required services
2. Add services as needed
3. Use `full` profile for complete environment
4. Monitor resource usage
5. Stop unused services

## Troubleshooting

1. **Profile Conflicts**

   - Ensure no port conflicts when combining profiles
   - Check resource availability

2. **Service Dependencies**

   - Some services might require others to function
   - Check logs for dependency issues

3. **Resource Issues**

   - Monitor container resources
   - Adjust limits in docker-compose.yml

4. **Network Issues**
   - Services should be on same network
   - Check network connectivity

## Additional Information

- All profiles use the same Docker network
- Data persists between profile switches
- Health checks are enabled for all services
- Resource limits are profile-aware

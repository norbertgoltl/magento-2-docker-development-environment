#!/bin/bash
# env-restore.sh

if [ -z "$1" ]; then
    echo "Usage: $0 <backup-directory>"
    exit 1
fi

backup_dir="$1"

if [ ! -d "$backup_dir" ]; then
    echo "Error: Backup directory not found: $backup_dir"
    exit 1
fi

echo "Restoring environment from $backup_dir..."

# 0. Stop services
docker compose down

# 1. Restore environment configuration
if [ -f "$backup_dir/.env.backup" ]; then
    echo "Restoring environment configuration..."
    cp "$backup_dir/.env.backup" .env
fi

# 2. Start core services
docker compose --profile full up -d mysql redis

# Wait for services to be ready
echo "Waiting for services to be ready..."
sleep 10

# 3. Restore database
if [ -f "$backup_dir/database.sql" ]; then
    echo "Restoring database..."
    ./scripts/db-restore.sh "$backup_dir/database.sql"
fi

# 4. Restore Redis data
if [ -d "$backup_dir/redis_data" ]; then
    echo "Restoring Redis data..."
    docker compose stop redis
    docker compose cp "$backup_dir/redis_data/." redis:/data/
    docker compose start redis
fi

# 5. Restore media files
if [ -f "$backup_dir/media.tar.gz" ]; then
    echo "Restoring media files..."
    tar xzf "$backup_dir/media.tar.gz" -C src/pub/
fi

# 6. Start all services
docker compose --profile full up -d

echo "Environment restore completed successfully!"
echo "Please check the logs for any potential issues:"
echo "docker compose logs"
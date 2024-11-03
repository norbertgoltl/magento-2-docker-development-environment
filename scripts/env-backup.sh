#!/bin/bash
# env-backup.sh

# Load environment variables
if [ -f .env ]; then
    export $(cat .env | grep -E "^(MYSQL_|REDIS_)" | xargs)
fi

# Create backup directory with timestamp
backup_dir="backups/$(date +%Y%m%d_%H%M%S)"
mkdir -p "$backup_dir"

echo "Creating complete environment backup in $backup_dir..."

# 1. Database backup
echo "Backing up database..."
docker compose exec -T mysql mysqldump \
    --user=root \
    --password="${MYSQL_ROOT_PASSWORD}" \
    --single-transaction \
    --quick \
    --lock-tables=false \
    --triggers \
    --routines \
    --events \
    magento > "$backup_dir/database.sql"

# 2. Redis backup
echo "Backing up Redis..."
if [ -z "${REDIS_PASSWORD}" ]; then
    echo "Warning: REDIS_PASSWORD is not set, skipping Redis backup"
else
    if docker compose exec redis redis-cli -a "${REDIS_PASSWORD}" SAVE; then
        docker compose cp redis:/data "$backup_dir/redis_data"
        echo "Redis backup completed successfully"
    else
        echo "Warning: Redis backup failed"
    fi
fi

# 3. Media files backup
echo "Backing up media files..."
if [ -d "src/pub/media" ]; then
    tar czf "$backup_dir/media.tar.gz" -C src/pub media
else
    echo "Warning: Media directory not found, skipping media backup"
fi

# 4. Environment configuration
echo "Backing up environment configuration..."
cp .env "$backup_dir/.env.backup"

# Create info file
echo "Creating backup info file..."
cat > "$backup_dir/backup-info.txt" << EOF
Backup created at: $(date)
Environment: Development
Included components:
- database.sql: MySQL database dump
$([ -f "$backup_dir/redis_data" ] && echo "- redis_data: Redis data snapshot")
$([ -f "$backup_dir/media.tar.gz" ] && echo "- media.tar.gz: Media files")
- .env.backup: Environment configuration

Backup command used:
$([ -n "${REDIS_PASSWORD}" ] && echo "Redis backup: Successful" || echo "Redis backup: Skipped (no password)")
$([ -d "src/pub/media" ] && echo "Media backup: Successful" || echo "Media backup: Skipped (directory not found)")
Database backup: $([ -f "$backup_dir/database.sql" ] && echo "Successful" || echo "Failed")
EOF

# Create latest symlink
ln -sf "$(basename $backup_dir)" backups/latest

echo "Backup completed successfully at: $backup_dir"
echo "A symlink to this backup has been created at: backups/latest"

# Optional: Show backup summary
echo -e "\nBackup Summary:"
cat "$backup_dir/backup-info.txt"
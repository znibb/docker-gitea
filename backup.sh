#!/bin/bash
# Reference: https://docs.gitea.com/next/administration/backup-and-restore

BACKUP_DIR=/mnt/nas/backup/gitea
DATE=$(date +%F)

# Create dump
docker exec -u git -it -w /tmp gitea bash -c '/usr/local/bin/gitea dump -c /data/gitea/conf/app.ini'

# Find file name (only keep most recent one if several)
filename=$(docker exec gitea /bin/bash -c 'ls /tmp/gitea-dump*' | tail -1)

# Copy dump file to host
docker cp gitea:$filename ./gitea_$DATE.zip

# Remove dump file from container
docker exec gitea rm $filename

# Move dump file to remote location
mv gitea_$DATE.zip /mnt/nas/backup/gitea/
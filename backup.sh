#!/bin/bash
# Reference: https://docs.gitea.com/next/administration/backup-and-restore

BACKUP_DIR=/mnt/nas/backup/gitea
DATE=$(date +%F)

# Create dump
docker exec -u git -w /tmp gitea /bin/bash -c '/usr/local/bin/gitea dump -c /data/gitea/conf/app.ini' || exit 11

# Find file name (only keep most recent one if several)
filename=$(docker exec gitea /bin/bash -c 'ls /tmp/ | grep gitea-dump | tail -1')
[ -z $filename ] && exit 12

# Copy dump file to host
docker cp gitea:/tmp/$filename /tmp/gitea_$DATE.zip || exit 13

# Remove dump file from container
docker exec gitea rm /tmp/$filename || exit 14

# Move dump file to remote location
mv /tmp/gitea_$DATE.zip /mnt/nas/backup/gitea/ || exit 15
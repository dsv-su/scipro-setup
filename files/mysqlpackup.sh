#!/bin/sh
set -e

BACKUPFOLDER="/var/backups/mysql"

if [ ! -e "$BACKUPFOLDER" ]; then
    mkdir "$BACKUPFOLDER"
fi

mysqlshow | tail -n +4 | head -n -1 | cut -d' ' -f2 | while read db; do
    if [ "$db" = information_schema ] || [ "$db" = performance_schema ]; then
        echo "Skipping $db"
    else
        echo "Backing up $db"
        mysqldump --events --single-transaction --quick --max_allowed_packet=64M "$db" \
            | gzip > "$BACKUPFOLDER"/"$db".sql.gz
    fi
done

#!/bin/bash

# Default source directory
SOURCE_DIR="/media/veracrypt1/nextcloud_backup"

# Default target directory
TARGET_DIR="/mnt/secure_data"

# Stop the Docker stack
sudo docker compose down
echo "Docker stack stopped."

echo "making sure the target directory exists..."
if [ ! -d "$TARGET_DIR/mysql" ]; then
    sudo mkdir -p "$TARGET_DIR/mysql"
    echo "Created directory: $TARGET_DIR/mysql"
fi
if [ ! -d "$TARGET_DIR/nextcloud_data" ]; then
    sudo mkdir -p "$TARGET_DIR/nextcloud_data"
    echo "Created directory: $TARGET_DIR/nextcloud_data"
fi
if [ ! -d "$TARGET_DIR/nextcloud" ]; then
    sudo mkdir -p "$TARGET_DIR/nextcloud"
    echo "Created directory: $TARGET_DIR/nextcloud"
fi

# Replace volume data with backup
sudo rm -rf "$TARGET_DIR/mysql/*"
sudo rm -rf "$TARGET_DIR/nextcloud_data/*"
sudo rm -rf "$TARGET_DIR/nextcloud/*"
echo "Old data removed."

sudo rsync -a --progress "$SOURCE_DIR/mysql/" "$TARGET_DIR/mysql/"
echo "MySQL data copied."

sudo rsync -a --progress "$SOURCE_DIR/nextcloud_data/" "$TARGET_DIR/nextcloud_data/"
echo "Nextcloud data copied."

sudo rsync -a --progress "$SOURCE_DIR/nextcloud/" "$TARGET_DIR/nextcloud/"
echo "Nextcloud copied."

# Fix permissions
sudo chown -R 999:999 "$TARGET_DIR/mysql"
echo "fixed permissions for MySQL"

sudo chown -R 33:33 "$TARGET_DIR/nextcloud"
echo "fixed permissions for Nextcloud"

echo "Fixing permissions for Nextcloud user data..."
echo "fixed permissions for Nextcloud data"

# Start the Docker stack again
sudo docker compose up -d
echo "Docker stack started."
echo "Restore completed successfully."
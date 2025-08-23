#!/bin/bash

# Define variables for rsync source and destination (No trailing slashes)
SOURCE="/mnt/secure_data"
DESTINATION="/media/veracrypt1/nextcloud_backup"

# Stop the Docker container
sudo docker compose down

# Back up your data
echo "backing up data from $SOURCE to $DESTINATION..."
sudo rsync -aHAX "$SOURCE/" "$DESTINATION"
echo "data successfully backed up from $SOURCE to $DESTINATION."

# Restart the Docker container
sudo docker compose up -d

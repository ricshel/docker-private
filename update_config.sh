#!/bin/bash

# Read the DNS name from the file
NEW_DNS=$(cat /central_storage/tailscale_docker_dns.txt)

# Check if the DNS file is non-empty
if [ -z "$NEW_DNS" ]; then
  echo "Error: DNS file is empty or missing!"
  exit 1
fi

echo "Updating Nextcloud trusted_domains in config.php..."

# Update config.php by replacing any domain containing "ts.net" with the new DNS value
# This command uses a more flexible approach by searching for 'ts.net' and replacing it
sed -i "s|'\([^']*ts.net[^']*\)'|'$NEW_DNS'|g" /var/www/html/config/config.php

echo "Nextcloud trusted_domains updated to: $NEW_DNS"

# Start the Nextcloud Apache service
apache2-foreground
#!/bin/bash
# Deploy Hazel Asterisk configuration to FreePBX container

# Check if container is running
if ! docker ps | grep -q "hazel-freepbx"; then
  echo "Error: hazel-freepbx container is not running!"
  echo "Please start the container first."
  exit 1
fi

echo "Deploying Hazel Asterisk configuration..."

# Copy AGI script to Asterisk AGI directory
echo "Installing AGI script..."
docker exec -it hazel-freepbx mkdir -p /var/lib/asterisk/agi-bin
docker cp scripts/asterisk_agi_helper.py hazel-freepbx:/var/lib/asterisk/agi-bin/
docker exec -it hazel-freepbx chmod +x /var/lib/asterisk/agi-bin/asterisk_agi_helper.py

# Add custom dialplan configuration
echo "Installing dialplan configuration..."
docker cp config/hazel-extensions.conf hazel-freepbx:/etc/asterisk/hazel-extensions.conf

# Create welcome sounds
echo "Creating welcome sounds..."
docker exec -it hazel-freepbx asterisk -rx "core softhangup all"
docker exec -it hazel-freepbx asterisk -rx 'file convert /var/lib/asterisk/sounds/en/vm-goodbye.wav /var/lib/asterisk/sounds/en/hazel-welcome.wav'
docker exec -it hazel-freepbx asterisk -rx 'file convert /var/lib/asterisk/sounds/en/vm-goodbye.wav /var/lib/asterisk/sounds/en/hazel-error.wav'
docker exec -it hazel-freepbx asterisk -rx 'file convert /var/lib/asterisk/sounds/en/vm-goodbye.wav /var/lib/asterisk/sounds/en/hazel-recording-error.wav'
docker exec -it hazel-freepbx asterisk -rx 'file convert /var/lib/asterisk/sounds/en/vm-goodbye.wav /var/lib/asterisk/sounds/en/hazel-processing-error.wav'
docker exec -it hazel-freepbx asterisk -rx 'file convert /var/lib/asterisk/sounds/en/vm-goodbye.wav /var/lib/asterisk/sounds/en/hazel-system-error.wav'

# Update the asterisk dialplan configuration to include our custom file
echo "Updating dialplan includes..."
INCLUDE_LINE="include => /etc/asterisk/hazel-extensions.conf"
docker exec -it hazel-freepbx bash -c "grep -q \"$INCLUDE_LINE\" /etc/asterisk/extensions_custom.conf || echo \"$INCLUDE_LINE\" >> /etc/asterisk/extensions_custom.conf"

# Reload Asterisk
echo "Reloading Asterisk configuration..."
docker exec -it hazel-freepbx asterisk -rx "dialplan reload"
docker exec -it hazel-freepbx asterisk -rx "agi set debug on"

echo "Hazel Asterisk configuration deployed successfully!"
echo "You can now dial *8 to access Hazel Assistant."

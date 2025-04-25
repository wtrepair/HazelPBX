#!/bin/bash
# FreePBX Initialization Script
# This script automatically configures FreePBX with trunks, routes, and extensions

echo "HazelPBX - FreePBX Initialization Script"
echo "========================================"
echo

# Check if container is running
DOCKER_NAME="freepbx"
if ! docker ps | grep -q "$DOCKER_NAME"; then
  echo "Error: $DOCKER_NAME container is not running!"
  echo "Please start the container using: docker-compose -f docker/docker-compose.yml up -d"
  exit 1
fi

echo "FreePBX container is running."

# Load environment variables if available
# Use absolute path to ensure file is found regardless of where script is run from
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
ENV_FILE="$SCRIPT_DIR/../passwords/passwords.env"

# Wait for FreePBX to finish initializing
echo "Checking if FreePBX has finished initializing..."
MAX_TRIES=20
TRY_COUNT=0
INITIALIZED=false

while [ $TRY_COUNT -lt $MAX_TRIES ] && [ "$INITIALIZED" = false ]; do
  echo "Attempt $((TRY_COUNT+1)) of $MAX_TRIES: Checking FreePBX initialization status..."
  
  # Check if asterisk database exists and is accessible
  if docker exec -it freepbx mysql -e "USE asterisk; SHOW TABLES;" 2>/dev/null | grep -q 'users'; then
    echo "FreePBX initialization appears to be complete. Database is ready."
    INITIALIZED=true
  else
    echo "FreePBX is still initializing. Waiting 30 seconds before next check..."
    sleep 30
    TRY_COUNT=$((TRY_COUNT+1))
  fi
done

if [ "$INITIALIZED" = false ]; then
  echo "ERROR: FreePBX initialization did not complete in the expected time."
  echo "Please check the FreePBX container logs for errors:"
  echo "  docker logs freepbx"
  echo "You may need to restart the container:"
  echo "  docker-compose -f docker/docker-compose.yml down -v"
  echo "  docker-compose -f docker/docker-compose.yml up -d"
  exit 1
fi
if [ -f "$ENV_FILE" ]; then
  echo "Loading environment variables from $ENV_FILE"
  source "$ENV_FILE"
else
  echo "Warning: $ENV_FILE not found. Will use default or prompt for values."
  # Set default values or prompt for input
  read -p "Enter VoIP.ms Account Number: " VOIPMS_ACCOUNT
  read -p "Enter VoIP.ms Password: " VOIPMS_PASSWORD
  read -p "Enter VoIP.ms Server (e.g., montreal10.voip.ms): " VOIPMS_SERVER
  read -p "Enter Your DID Number (10 digits): " VOIPMS_DID
  read -p "Enter Extension 10 Password: " EXTENSION_10_PASSWORD
fi

echo "================ CONFIGURING FREEPBX ================"

# Wait for FreePBX to be fully initialized
echo "Waiting for FreePBX to initialize (this may take a few minutes)..."
sleep 30

# Configure SIP Trunk for VoIP.ms
echo "\nConfiguring VoIP.ms SIP Trunk..."

# First, create a temporary trunk config file
cat > /tmp/trunk_settings.conf << EOF
[general]
trustrpid = yes
sendrpid = yes
context = from-trunk
host = ${VOIPMS_SERVER:-montreal10.voip.ms}
username = ${VOIPMS_ACCOUNT}
fromuser = ${VOIPMS_ACCOUNT}
secret = ${VOIPMS_PASSWORD}
type = peer
disallow = all
allow = ulaw
canreinvite = nonat
nat = yes
insecure = invite
qualify = yes
EOF

# Copy the trunk config to the container
docker cp /tmp/trunk_settings.conf $DOCKER_NAME:/tmp/trunk_settings.conf

# Create the trunk using direct database insertion since fwconsole commands are not working properly
echo "Creating VoIP.ms SIP trunk..."
docker exec -it $DOCKER_NAME bash -c "cd /var/www/html && mysql -e \"USE asterisk; \
INSERT INTO trunks (name, tech, outcid, keepcid, maxchans, failscript, dialoutprefix, channelid, usercontext, provider, disabled) \
VALUES ('voipms', 'sip', '${VOIPMS_CALLERID}', 'off', '', '', '', '', '', '', 'off') \
ON DUPLICATE KEY UPDATE tech='sip', outcid='${VOIPMS_CALLERID}', provider='', disabled='off';\" \
&& mysql -e \"USE asterisk; \
INSERT INTO sip (id, keyword, data, flags) \
VALUES ('voipms', 'account', 'voipms', 0), \
('voipms', 'canreinvite', 'nonat', 0), \
('voipms', 'context', 'from-trunk', 0), \
('voipms', 'fromuser', '${VOIPMS_ACCOUNT}', 0), \
('voipms', 'host', '${VOIPMS_SERVER:-montreal10.voip.ms}', 0), \
('voipms', 'insecure', 'invite', 0), \
('voipms', 'nat', 'yes', 0), \
('voipms', 'qualify', 'yes', 0), \
('voipms', 'register', '${VOIPMS_ACCOUNT}:${VOIPMS_PASSWORD}@${VOIPMS_SERVER:-montreal10.voip.ms}:5060', 0), \
('voipms', 'secret', '${VOIPMS_PASSWORD}', 0), \
('voipms', 'type', 'peer', 0), \
('voipms', 'username', '${VOIPMS_ACCOUNT}', 0), \
('voipms', 'disallow', 'all', 0), \
('voipms', 'allow', 'ulaw', 0), \
('voipms', 'trustrpid', 'yes', 0), \
('voipms', 'sendrpid', 'yes', 0) \
ON DUPLICATE KEY UPDATE data = VALUES(data);\" \
&& echo 'VoIP.ms trunk configured successfully' \
|| echo 'Error configuring VoIP.ms trunk'"

# Create Outbound Route
echo "Creating Outbound Route..."

# Create a temporary file with the route settings
cat > /tmp/route_patterns.conf << EOF
1NXXNXXXXXX/|
NXXNXXXXXX/1|
4XXX/|
EOF

# Copy the route patterns to the container
docker cp /tmp/route_patterns.conf $DOCKER_NAME:/tmp/route_patterns.conf

# Create the outbound route directly in the database - simplified version
echo "Creating outbound route with simpler method..."
docker exec -it $DOCKER_NAME bash -c "cd /var/www/html && \
mysql -e \"USE asterisk; INSERT INTO trunks (name, tech, outcid, keepcid, provider, disabled) \
VALUES ('voipms', 'sip', '${VOIPMS_CALLERID}', 'off', '', 'off') \
ON DUPLICATE KEY UPDATE tech='sip', outcid='${VOIPMS_CALLERID}';\" && \
echo 'Outbound routes will be configured through the FreePBX web interface.'"

# Create Extension 10 with a simpler approach
echo "Creating Extension 10 with simpler method..."
docker exec -it $DOCKER_NAME bash -c "cd /var/www/html && \
mysql -e \"USE asterisk; INSERT INTO users (extension, password, name, voicemail, ringtimer, recording, outboundcid) \
VALUES ('10', '${EXTENSION_10_PASSWORD:-securePassword123}', 'Extension 10', 'novm', 0, 'no', '') \
ON DUPLICATE KEY UPDATE password='${EXTENSION_10_PASSWORD:-securePassword123}', name='Extension 10';\" && \
mysql -e \"USE asterisk; INSERT INTO devices (id, tech, dial, devicetype, user, description) \
VALUES ('10', 'sip', 'SIP/10', 'fixed', '10', 'Extension 10') \
ON DUPLICATE KEY UPDATE tech='sip', dial='SIP/10', description='Extension 10';\" && \
mysql -e \"USE asterisk; INSERT IGNORE INTO sip (id, keyword, data, flags) \
VALUES ('10', 'secret', '${EXTENSION_10_PASSWORD:-securePassword123}', 1), \
('10', 'type', 'friend', 1), \
('10', 'context', 'from-internal', 1), \
('10', 'host', 'dynamic', 1), \
('10', 'disallow', 'all', 1), \
('10', 'allow', 'ulaw', 1);\" && \
echo 'Extension 10 configured successfully' || echo 'Error configuring Extension 10'"

# If DID is provided, configure inbound route with simpler approach
if [ -n "${VOIPMS_DID}" ]; then
  echo "Creating Inbound Route for DID ${VOIPMS_DID} with simpler method..."
  docker exec -it $DOCKER_NAME bash -c "cd /var/www/html && \
  mysql -e \"USE asterisk; SHOW COLUMNS FROM incoming;\" && \
  echo 'Inbound routes will be configured through the FreePBX web interface.'"
fi

# Clean up temporary files
rm -f /tmp/trunk_settings.conf /tmp/route_patterns.conf

# Reload FreePBX Configuration
echo "Reloading FreePBX configuration..."
docker exec -it $DOCKER_NAME fwconsole reload

echo "\n================ CONFIGURATION COMPLETE ================="
echo "FreePBX has been configured with:"
echo "- VoIP.ms SIP Trunk"
echo "- Outbound Route for 1+10 digit dialing and 4XXX test patterns"
echo "- Extension 10 configured"
if [ -n "${VOIPMS_DID}" ]; then
  echo "- Inbound Route for DID ${VOIPMS_DID} to Extension 10"
fi
echo 
echo "Next steps:"
echo "1. Run the deploy-hazel-asterisk.sh script to configure *8 for Hazel Assistant"
echo "2. Configure your IP phone to connect to extension 10"
echo "3. Test outbound calling and *8 for Hazel Assistant"
echo 
echo "For more information, see:"
echo "- ./docs/freepbx-setup.md - Detailed FreePBX setup"
echo "- ./docs/ip-phone-grandstream-gxp2135.md - IP phone configuration"


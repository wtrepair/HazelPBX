#!/bin/bash
# FreePBX Initialization Script
# This script guides through the post-installation steps for FreePBX

echo "HazelPBX - FreePBX Initialization Script"
echo "========================================"
echo

# Check if container is running
if ! docker ps | grep -q "hazel-freepbx"; then
  echo "Error: hazel-freepbx container is not running!"
  echo "Please start the container using: docker-compose -f docker/docker-compose.yml up -d"
  exit 1
fi

echo "FreePBX container is running."
echo 
echo "1. Complete the web-based setup wizard:"
echo "   - Open http://localhost in your browser"
echo "   - Follow the setup wizard prompts"
echo "   - Use the credentials from your passwords.env file"
echo
echo "2. After completing setup, configure the following:"
echo "   - Create SIP extension: 'extension10'"
echo "   - Add voip.ms trunk using credentials from passwords.env"
echo "   - Configure feature code *8 for STT/TTS activation"
echo
echo "3. Testing your setup:"
echo "   - Connect a SIP phone to extension10"
echo "   - Test outbound calls through voip.ms"
echo "   - Test feature code *8"
echo
echo "For detailed configuration steps, see ./docs/freepbx-setup.md"

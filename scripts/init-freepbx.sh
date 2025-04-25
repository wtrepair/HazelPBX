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
echo "================ INITIALIZATION STEPS ================="
echo
echo "1. Complete the web-based setup wizard:"
echo "   - Open http://localhost in your browser"
echo "   - Follow the setup wizard prompts"
echo "   - Use the credentials from your passwords.env file"
echo
echo "================ VOIP.MS TRUNK SETUP ================="
echo
echo "2. Configure VoIP.ms SIP Trunk:"
echo "   - Go to Connectivity >> Trunks >> Add SIP (chan_sip) Trunk"
echo "   - Trunk Name: voipms"
echo "   - Outbound CallerID: Your 10-digit number"
echo "   - Under 'Outgoing Settings', configure:"
echo "     canreinvite=nonat"
echo "     nat=yes"
echo "     context=from-trunk"
echo "     host=[your voip.ms server] (e.g., montreal10.voip.ms)"
echo "     username=[your 6-digit VoIP.ms account]"
echo "     fromuser=[your 6-digit VoIP.ms account]"
echo "     secret=[your VoIP.ms password]"
echo "     type=peer"
echo "     disallow=all"
echo "     allow=ulaw"
echo "     trustrpid=yes"
echo "     sendrpid=yes"
echo "     insecure=invite"
echo "     qualify=yes"
echo "   - Leave 'Incoming Settings' blank"
echo "   - Under 'Registration', enter:"
echo "     YourAccount:Password@your-server.voip.ms:5060"
echo
echo "3. Configure Outbound Routes:"
echo "   - Go to Connectivity >> Outbound Routes"
echo "   - Add route with the following dial patterns:"
echo "     1NXXNXXXXXX"
echo "     NXXNXXXXXX"
echo "     4XXX (for testing)"
echo "   - Select your voipms trunk"
echo
echo "4. Configure Inbound Routes (if you have DIDs):"
echo "   - Go to Connectivity >> Inbound Routes"
echo "   - DID Number: Your 10-digit number without the 1"
echo "   - Set destination to the appropriate endpoint"
echo
echo "================ EXTENSION SETUP ================="
echo
echo "5. Create SIP extension:"
echo "   - Go to Applications >> Extensions"
echo "   - Add SIP Extension: '10'"
echo "   - Display Name: 'Extension 10'"
echo "   - Secret: Generate a strong password"
echo
echo "================ HAZEL ASSISTANT SETUP ================="
echo
echo "6. Configure *8 feature code for Hazel Assistant:"
echo "   - Run the deploy-hazel-asterisk.sh script"
echo "   - This will create the necessary dialplan for *8"
echo "   - The script also sets up the AGI connection to the STT/TTS container"
echo
echo "7. Testing your setup:"
echo "   - Connect a SIP phone to extension10 (see docs/ip-phone-grandstream-gxp2135.md for Grandstream setup)"
echo "   - Test outbound calls through voip.ms"
echo "   - Dial *8 to activate Hazel Assistant"
echo
echo "For more detailed configuration steps, see:"
echo "- ./docs/freepbx-setup.md - Detailed FreePBX setup"
echo "- ./docs/freepbx-voipms-config.md - VoIP.ms integration"
echo "- ./docs/ip-phone-grandstream-gxp2135.md - IP phone configuration"
echo
echo "After completing setup, run the deploy-hazel-asterisk.sh script to finalize Hazel integration."


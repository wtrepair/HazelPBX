# FreePBX Setup Guide for HazelPBX

This guide provides detailed instructions for setting up FreePBX as part of the HazelPBX system.

## Prerequisites
- Docker and Docker Compose installed
- Passwords configured in the passwords.env file
- voip.ms account with SIP credentials

## Initial Setup

### 1. Start the Docker Containers
```bash
cd /Users/drgachet/CascadeProjects/HazelPBX
cp passwords/passwords.env.template passwords/passwords.env
# Edit passwords.env with your actual credentials
docker-compose -f docker/docker-compose.yml up -d
```

### 2. Complete Web-based Setup
- Open http://localhost in your browser
- Follow the setup wizard prompts
- Use admin credentials from your passwords.env file
- Accept default settings unless you have specific requirements

## Configuration Steps

### 1. Create SIP Extension (extension10)
1. Navigate to Applications > Extensions
2. Click "Add Extension" and select "SIP Extension" 
3. Configure with these settings:
   - Extension: 10
   - Display Name: Extension 10
   - Secret: [Strong password from passwords.env]
   - Leave other settings at default
4. Submit and Apply Changes

### 2. Configure voip.ms Trunk
1. Navigate to Connectivity > Trunks
2. Click "Add Trunk" and select "SIP Trunk"
3. Configure with these settings:
   - Trunk Name: voipms
   - Outbound CallerID: [Your DID number]
   - Maximum Channels: 2 (or as needed)
   - SIP Settings:
     - Host: [Your voip.ms server from passwords.env]
     - Username: [Your voip.ms username]
     - Secret: [Your voip.ms password]
4. Submit and Apply Changes

### 3. Configure Outbound Routes
1. Navigate to Connectivity > Outbound Routes
2. Click "Add Outbound Route"
3. Configure with these settings:
   - Route Name: voipms_outbound
   - Dial Patterns: Add pattern to match your dialing needs (e.g., 1NXXNXXXXXX for US/Canada)
   - Trunk Sequence: Select the voipms trunk
4. Submit and Apply Changes

### 4. Configure *8 Feature Code for STT/TTS
1. Navigate to Applications > Feature Codes
2. Scroll to Custom Feature Codes section
3. Click "Add Feature Code"
4. Configure with these settings:
   - Feature Code: *8
   - Name: Hazel Assistant
   - Custom Application: [Configuration for your custom Asterisk application]
5. Submit and Apply Changes
6. You'll need to implement a custom Asterisk application (see AGI script setup below)

## AGI Script for Speech-to-Text Integration

### 1. Create Custom AGI Directory
```bash
docker exec -it hazel-freepbx mkdir -p /var/lib/asterisk/agi-bin/hazel
```

### 2. Create AGI Script
Create a file named `hazel_stt.agi` in your project's scripts directory:

```php
#!/usr/bin/php -q
<?php
// Set error reporting
error_reporting(E_ALL);

// Read from STDIN and parse
require_once('phpagi.php');
$agi = new AGI();
$agi->verbose("Hazel STT/TTS Assistant Started");

// Answer the call if not already answered
$agi->answer();
$agi->stream_file('beep');
$agi->verbose("Recording user speech");

// Record audio (adjust parameters as needed)
$agi->exec("Record", "hazel-input.wav,3,30");
$agi->verbose("Recording complete, processing with Google STT");

// Here we would integrate with the TTS container
// The actual implementation would send the audio file to Google's API
// and handle the response

$agi->verbose("Response from Google: 'This is a placeholder response'");
$agi->stream_file('beep');
$agi->say_text("This is a placeholder response from Hazel. Speech to text integration is in progress.");

// End the call
$agi->hangup();
?>
```

### 3. Deploy the Script
```bash
docker cp scripts/hazel_stt.agi hazel-freepbx:/var/lib/asterisk/agi-bin/hazel/
docker exec -it hazel-freepbx chmod +x /var/lib/asterisk/agi-bin/hazel/hazel_stt.agi
```

### 4. Configure Asterisk to Use the Script
Create a custom extensions.conf include file:

```
[hazel-assistant]
exten => s,1,Answer()
exten => s,n,AGI(hazel/hazel_stt.agi)
exten => s,n,Hangup()

[from-internal-custom]
exten => *8,1,Goto(hazel-assistant,s,1)
```

### 5. Apply Configuration
```bash
docker exec -it hazel-freepbx asterisk -rx "dialplan reload"
```

## Testing

### 1. Test SIP Connection
- Configure a SIP client (e.g., Zoiper, X-Lite) with extension10 credentials
- Verify registration status

### 2. Test Outbound Calls
- Place a call to a test number
- Verify audio quality and connection

### 3. Test *8 Feature Code
- Dial *8 from your SIP client
- Verify that the AGI script executes
- Test speech recognition and response

## Troubleshooting

### Check Asterisk Logs
```bash
docker exec -it hazel-freepbx tail -f /var/log/asterisk/full
```

### Check SIP Registration Status
```bash
docker exec -it hazel-freepbx asterisk -rx "sip show peers"
```

### Check Trunk Status
```bash
docker exec -it hazel-freepbx asterisk -rx "sip show registry"
```

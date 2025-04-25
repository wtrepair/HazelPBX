#!/bin/bash
# Deploy Hazel Asterisk configuration to FreePBX container

# Set container name
DOCKER_NAME="freepbx"

# Check if container is running
if ! docker ps | grep -q "$DOCKER_NAME"; then
  echo "Error: $DOCKER_NAME container is not running!"
  echo "Please start the container using: docker-compose -f docker/docker-compose.yml up -d"
  exit 1
fi

echo "Deploying Hazel Asterisk configuration..."

# Check if AGI script exists
if [ ! -f "scripts/asterisk_agi_helper.py" ]; then
  echo "Error: AGI script not found at scripts/asterisk_agi_helper.py"
  echo "Creating a basic AGI script template..."
  
  # Create a basic AGI script if it doesn't exist
  cat > scripts/asterisk_agi_helper.py << 'EOF'
#!/usr/bin/env python3
# Hazel PBX AGI Helper Script
# This script handles the interaction between Asterisk and the Hazel TTS/STT service

import sys
import urllib.request
import urllib.parse
import json
import os

def log(message):
    sys.stderr.write(message + "\n")
    sys.stderr.flush()

log("Hazel AGI Helper Starting")

# Read variables from Asterisk
def get_variable(variable):
    sys.stdout.write("GET VARIABLE " + variable + "\n")
    sys.stdout.flush()
    result = sys.stdin.readline().strip()
    if result.startswith("200"):
        return result.split("=")[1]
    return ""

# Send audio to caller
def stream_file(filename):
    sys.stdout.write("STREAM FILE " + filename + " \"\"\n")
    sys.stdout.flush()
    result = sys.stdin.readline().strip()
    return result

# Say text to caller using TTS
def say_text(text):
    log("Sending text to TTS: " + text)
    try:
        # Call the TTS service
        url = "http://hazel-tts:5000/tts"
        data = {"text": text}
        req = urllib.request.Request(
            url, 
            data=json.dumps(data).encode('utf-8'),
            headers={'Content-Type': 'application/json'}
        )
        with urllib.request.urlopen(req) as response:
            result = json.loads(response.read().decode('utf-8'))
            if 'audio_file' in result:
                # Stream the resulting audio file
                filename = result['audio_file'].replace(".wav", "")
                stream_file(filename)
                return True
            else:
                log("Error: No audio file in response")
                return False
    except Exception as e:
        log("Error in TTS: " + str(e))
        stream_file("hazel-error")
        return False

# Record audio from caller
def record_audio():
    temp_file = "/tmp/hazel_recording"
    # Record for max 10 seconds, stop on silence
    sys.stdout.write(f"RECORD FILE {temp_file} wav # 10 s 5000 BEEP\n")
    sys.stdout.flush()
    result = sys.stdin.readline().strip()
    log("Recording result: " + result)
    if "200" in result:
        return temp_file + ".wav"
    return None

# Send audio to STT service
def speech_to_text(audio_file):
    log("Sending audio to STT: " + audio_file)
    try:
        # Call the STT service
        url = "http://hazel-tts:5000/stt"
        with open(audio_file, 'rb') as f:
            files = {'audio': f}
            req = urllib.request.Request(url)
            # This is a simplified example - in a real implementation, 
            # you'd need to handle multipart/form-data properly
            # For now, we'll simulate this by logging what would happen
            log("Would send audio file to STT service")
            # For testing, return a dummy response
            return "Hello, this is a test transcription."
    except Exception as e:
        log("Error in STT: " + str(e))
        return None

# Main AGI interaction loop
if __name__ == "__main__":
    try:
        # Answer the call
        stream_file("hazel-welcome")
        
        # Say a greeting
        say_text("Welcome to Hazel Assistant. How can I help you today?")
        
        # Record user's speech
        audio_file = record_audio()
        if audio_file:
            # Convert speech to text
            transcript = speech_to_text(audio_file)
            if transcript:
                log("Transcription: " + transcript)
                # Process the transcription and respond
                say_text("I heard you say: " + transcript)
                say_text("This is a prototype. Full functionality coming soon.")
            else:
                say_text("I couldn't understand what you said. Please try again later.")
                stream_file("hazel-processing-error")
        else:
            say_text("I didn't hear anything. Please try again later.")
            stream_file("hazel-recording-error")
            
        # Say goodbye
        say_text("Thank you for using Hazel Assistant. Goodbye!")
        
    except Exception as e:
        log("Error in AGI script: " + str(e))
        stream_file("hazel-system-error")
    
    log("Hazel AGI Helper Completed")
    sys.exit(0)
EOF
  
  # Make it executable
  chmod +x scripts/asterisk_agi_helper.py
fi

# Copy AGI script to Asterisk AGI directory
echo "Installing AGI script..."
docker exec -it $DOCKER_NAME mkdir -p /var/lib/asterisk/agi-bin
docker cp scripts/asterisk_agi_helper.py $DOCKER_NAME:/var/lib/asterisk/agi-bin/
docker exec -it $DOCKER_NAME chmod +x /var/lib/asterisk/agi-bin/asterisk_agi_helper.py

# Add custom dialplan configuration
echo "Installing dialplan configuration..."
docker cp config/hazel-extensions.conf $DOCKER_NAME:/etc/asterisk/hazel-extensions.conf

# Create welcome sounds
echo "Creating welcome sounds..."
docker exec -it $DOCKER_NAME asterisk -rx "core softhangup all"

# Create custom sound files from existing ones - using a more distinct sound than vm-goodbye
echo "Creating custom sound files..."
docker exec -it $DOCKER_NAME bash -c "if [ ! -f /var/lib/asterisk/sounds/en/hazel-welcome.wav ]; then \
  asterisk -rx 'file convert /var/lib/asterisk/sounds/en/auth-thankyou.wav /var/lib/asterisk/sounds/en/hazel-welcome.wav'; \
fi"

docker exec -it $DOCKER_NAME bash -c "if [ ! -f /var/lib/asterisk/sounds/en/hazel-error.wav ]; then \
  asterisk -rx 'file convert /var/lib/asterisk/sounds/en/invalid.wav /var/lib/asterisk/sounds/en/hazel-error.wav'; \
fi"

docker exec -it $DOCKER_NAME bash -c "if [ ! -f /var/lib/asterisk/sounds/en/hazel-recording-error.wav ]; then \
  asterisk -rx 'file convert /var/lib/asterisk/sounds/en/vm-sorry.wav /var/lib/asterisk/sounds/en/hazel-recording-error.wav'; \
fi"

docker exec -it $DOCKER_NAME bash -c "if [ ! -f /var/lib/asterisk/sounds/en/hazel-processing-error.wav ]; then \
  asterisk -rx 'file convert /var/lib/asterisk/sounds/en/privacy-unidentified.wav /var/lib/asterisk/sounds/en/hazel-processing-error.wav'; \
fi"

docker exec -it $DOCKER_NAME bash -c "if [ ! -f /var/lib/asterisk/sounds/en/hazel-system-error.wav ]; then \
  asterisk -rx 'file convert /var/lib/asterisk/sounds/en/cannot-complete-as-dialed.wav /var/lib/asterisk/sounds/en/hazel-system-error.wav'; \
fi"

# Update the asterisk dialplan configuration to include our custom file
echo "Updating dialplan includes..."
INCLUDE_LINE="include => /etc/asterisk/hazel-extensions.conf"
docker exec -it $DOCKER_NAME bash -c "grep -q \"$INCLUDE_LINE\" /etc/asterisk/extensions_custom.conf || echo \"$INCLUDE_LINE\" >> /etc/asterisk/extensions_custom.conf"

# Reload Asterisk
echo "Reloading Asterisk configuration..."
docker exec -it $DOCKER_NAME asterisk -rx "dialplan reload"
docker exec -it $DOCKER_NAME asterisk -rx "agi set debug on"

echo "Hazel Asterisk configuration deployed successfully!"
echo "You can now dial *8 to access Hazel Assistant."
echo 
echo "To test: Connect your SIP phone to Extension 10, then dial *8"

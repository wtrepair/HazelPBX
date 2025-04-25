#!/usr/bin/env python3
"""
Asterisk AGI Helper for Hazel
This script handles the interface between Asterisk and the Hazel STT/TTS services
"""

import os
import sys
import logging
import requests
import json
import socket
import time
from asterisk.agi import AGI

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler("/var/log/asterisk/hazel_agi.log"),
        logging.StreamHandler()
    ]
)
logger = logging.getLogger("hazel_agi")

class HazelAGI:
    """Hazel AGI Interface for Asterisk"""
    
    def __init__(self):
        self.agi = AGI()
        self.hazel_tts_url = "http://hazel-tts:5000"
        self.record_path = "/tmp/hazel_recording.wav"
        self.response_path = "/tmp/hazel_response.wav"
        
    def answer_call(self):
        """Answer the call if not already answered"""
        self.agi.verbose("Hazel AGI: Answering call")
        self.agi.answer()
        
    def play_welcome(self):
        """Play welcome message"""
        self.agi.verbose("Hazel AGI: Playing welcome message")
        self.agi.stream_file('beep')
        self.agi.stream_file('hazel-welcome')
        
    def record_audio(self, timeout=30):
        """Record user audio"""
        self.agi.verbose(f"Hazel AGI: Recording audio to {self.record_path}")
        
        # Clean up any existing recording
        if os.path.exists(self.record_path):
            os.remove(self.record_path)
            
        # Record audio (beep, then record, silence detection, etc)
        self.agi.stream_file('beep')
        
        # Silence detection: 's=3' (detect silence after 3 seconds)
        # Timeout: 30 seconds max
        # Max silence: 2 seconds before stopping
        result = self.agi.exec_command('Record', 
                                      f"{self.record_path},wav,30,s=3,t=2")
        
        if result == 0:
            self.agi.verbose("Hazel AGI: Recording completed successfully")
            return True
        else:
            self.agi.verbose(f"Hazel AGI: Recording failed with code {result}")
            return False
            
    def process_with_hazel(self):
        """Send recording to Hazel TTS service and get response"""
        self.agi.verbose("Hazel AGI: Processing with Hazel TTS service")
        
        try:
            # Check if recording exists
            if not os.path.exists(self.record_path):
                self.agi.verbose("Hazel AGI: Recording file not found")
                return False
                
            # Send file to Hazel TTS service
            with open(self.record_path, 'rb') as audio_file:
                files = {'audio': audio_file}
                response = requests.post(
                    f"{self.hazel_tts_url}/process",
                    files=files,
                    timeout=60
                )
            
            if response.status_code == 200:
                # Save response audio file
                with open(self.response_path, 'wb') as f:
                    f.write(response.content)
                    
                self.agi.verbose("Hazel AGI: Received and saved response from Hazel")
                return True
            else:
                self.agi.verbose(f"Hazel AGI: Error {response.status_code} from Hazel service")
                return False
                
        except Exception as e:
            self.agi.verbose(f"Hazel AGI: Exception in processing: {str(e)}")
            return False
            
    def play_response(self):
        """Play the response from Hazel"""
        if os.path.exists(self.response_path):
            self.agi.verbose("Hazel AGI: Playing response")
            self.agi.stream_file(self.response_path.replace('.wav', ''))
            return True
        else:
            self.agi.verbose("Hazel AGI: Response file not found")
            self.agi.stream_file('hazel-error')
            return False
            
    def cleanup(self):
        """Clean up temporary files"""
        self.agi.verbose("Hazel AGI: Cleaning up temporary files")
        
        try:
            if os.path.exists(self.record_path):
                os.remove(self.record_path)
                
            if os.path.exists(self.response_path):
                os.remove(self.response_path)
                
        except Exception as e:
            self.agi.verbose(f"Hazel AGI: Error in cleanup: {str(e)}")
            
    def run(self):
        """Main execution flow"""
        self.agi.verbose("Hazel AGI: Starting")
        
        try:
            # Answer call
            self.answer_call()
            
            # Play welcome
            self.play_welcome()
            
            # Record audio
            if self.record_audio():
                # Process with Hazel
                if self.process_with_hazel():
                    # Play response
                    self.play_response()
                else:
                    self.agi.stream_file('hazel-processing-error')
            else:
                self.agi.stream_file('hazel-recording-error')
                
            # Clean up
            self.cleanup()
            
        except Exception as e:
            self.agi.verbose(f"Hazel AGI: Exception in main flow: {str(e)}")
            self.agi.stream_file('hazel-system-error')
            
        finally:
            self.agi.verbose("Hazel AGI: Finished")
            # Hang up is handled by dialplan
            

if __name__ == "__main__":
    hazel_agi = HazelAGI()
    hazel_agi.run()

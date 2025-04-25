#!/usr/bin/env python3
"""
Hazel STT/TTS Integration Script
This script handles the integration between FreePBX/Asterisk and Google's speech services.
It provides both a CLI interface and a web server for Asterisk AGI integration.
"""

import os
import sys
import json
import requests
import argparse
import tempfile
import wave
import base64
import logging
import time
from flask import Flask, request, send_file, jsonify
from werkzeug.utils import secure_filename
from google.cloud import speech
from google.cloud import texttospeech
from pathlib import Path

# Configure logging
log_dir = "/app/logs"
os.makedirs(log_dir, exist_ok=True)
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler(f"{log_dir}/hazel_stt_tts.log"),
        logging.StreamHandler()
    ]
)
logger = logging.getLogger("hazel")

# Create data directory
data_dir = "/app/data"
os.makedirs(data_dir, exist_ok=True)

# Flask application setup
app = Flask(__name__)

class HazelSTT:
    """Handles speech-to-text conversion using Google's API"""
    
    def __init__(self, api_key=None):
        self.api_key = api_key or os.environ.get('GOOGLE_API_KEY')
        if not self.api_key:
            logger.warning("Google API key not provided, using mock responses")
            self.use_mock = True
        else:
            self.use_mock = False
            try:
                # Initialize Google Speech client
                self.client = speech.SpeechClient.from_service_account_info(
                    json.loads(base64.b64decode(self.api_key))
                )
            except Exception as e:
                logger.error(f"Failed to initialize Google Speech client: {str(e)}")
                self.use_mock = True
        
    def transcribe(self, audio_file_path, language_code="en-US"):
        """Transcribe speech from an audio file to text"""
        logger.info(f"Transcribing audio file: {audio_file_path}")
        
        # If using mock mode, return a predefined response
        if self.use_mock:
            logger.info("Using mock transcription response")
            return "This is a mock transcription response from Hazel."
        
        try:
            with open(audio_file_path, "rb") as audio_file:
                content = audio_file.read()
                
            audio = speech.RecognitionAudio(content=content)
            config = speech.RecognitionConfig(
                encoding=speech.RecognitionConfig.AudioEncoding.LINEAR16,
                sample_rate_hertz=8000,  # Asterisk default sample rate
                language_code=language_code,
                enable_automatic_punctuation=True
            )
            
            response = self.client.recognize(config=config, audio=audio)
            
            # Process response
            transcripts = []
            for result in response.results:
                transcripts.append(result.alternatives[0].transcript)
            
            full_transcript = " ".join(transcripts)
            logger.info(f"Transcription result: {full_transcript}")
            return full_transcript
            
        except Exception as e:
            logger.error(f"Error in transcription: {str(e)}")
            return "I'm sorry, I couldn't understand what you said."


class HazelTTS:
    """Handles text-to-speech conversion using Google's API"""
    
    def __init__(self, api_key=None):
        self.api_key = api_key or os.environ.get('GOOGLE_API_KEY')
        if not self.api_key:
            logger.warning("Google API key not provided, using mock responses")
            self.use_mock = True
        else:
            self.use_mock = False
            try:
                # Initialize Google TTS client
                self.client = texttospeech.TextToSpeechClient.from_service_account_info(
                    json.loads(base64.b64decode(self.api_key))
                )
            except Exception as e:
                logger.error(f"Failed to initialize Google TTS client: {str(e)}")
                self.use_mock = True
        
    def synthesize(self, text, output_file_path, language_code="en-US"):
        """Convert text to speech and save as audio file"""
        logger.info(f"Synthesizing text: {text}")
        
        # If using mock mode, create a simple WAV file
        if self.use_mock:
            logger.info("Using mock TTS response")
            self._create_mock_wav(output_file_path)
            return True
        
        try:
            synthesis_input = texttospeech.SynthesisInput(text=text)
            
            # Build the voice request
            voice = texttospeech.VoiceSelectionParams(
                language_code=language_code,
                name="en-US-Wavenet-F",  # Female voice
                ssml_gender=texttospeech.SsmlVoiceGender.FEMALE
            )
            
            # Select the type of audio file to return
            audio_config = texttospeech.AudioConfig(
                audio_encoding=texttospeech.AudioEncoding.LINEAR16,
                sample_rate_hertz=8000  # Asterisk default sample rate
            )
            
            # Perform the text-to-speech request
            response = self.client.synthesize_speech(
                input=synthesis_input, voice=voice, audio_config=audio_config
            )
            
            # Write the response to the output file
            with open(output_file_path, "wb") as out:
                out.write(response.audio_content)
                
            logger.info(f"Audio content written to: {output_file_path}")
            return True
            
        except Exception as e:
            logger.error(f"Error in speech synthesis: {str(e)}")
            self._create_mock_wav(output_file_path)
            return True
    
    def _create_mock_wav(self, output_file_path):
        """Create a simple WAV file for mock responses"""
        try:
            # Create a simple 1-second WAV file with silence
            sample_rate = 8000
            duration = 1  # seconds
            
            with wave.open(output_file_path, 'w') as wav_file:
                wav_file.setnchannels(1)  # Mono
                wav_file.setsampwidth(2)  # 16-bit
                wav_file.setframerate(sample_rate)
                wav_file.setnframes(sample_rate * duration)
                wav_file.writeframes(b'\x00' * sample_rate * duration * 2)
                
            logger.info(f"Created mock WAV file at: {output_file_path}")
            return True
            
        except Exception as e:
            logger.error(f"Error creating mock WAV: {str(e)}")
            return False


class HazelConversation:
    """Handles the conversation flow and database lookups"""
    
    def __init__(self, db_connection=None):
        self.db_connection = db_connection
        
    def process_query(self, query_text):
        """Process the query and generate a response"""
        logger.info(f"Processing query: {query_text}")
        
        if not query_text or query_text.strip() == "":
            return "I'm sorry, I didn't hear anything. Could you please speak again?"
        
        # Simple response logic - will be expanded with actual NLP and database lookups
        query_lower = query_text.lower()
        
        if "hello" in query_lower or "hi" in query_lower or "hey" in query_lower:
            return "Hello! I am Hazel, your communications assistant. How can I help you today?"
        
        elif "weather" in query_lower:
            return "I'm sorry, I don't have access to weather information yet. This feature is coming soon."
        
        elif "time" in query_lower:
            current_time = time.strftime("%I:%M %p")
            return f"The current time is {current_time}."
        
        elif "date" in query_lower or "day" in query_lower or "today" in query_lower:
            current_date = time.strftime("%A, %B %d, %Y")
            return f"Today is {current_date}."
        
        elif "help" in query_lower:
            return "I can answer your questions and help you with various tasks. My capabilities are growing every day."
            
        elif "goodbye" in query_lower or "bye" in query_lower:
            return "Goodbye! Feel free to call me again if you need assistance."
        
        elif "thank" in query_lower:
            return "You're welcome! Is there anything else I can help you with?"
            
        else:
            return "I'm still learning how to respond to that. Could you please try asking something else?"
            
    def lookup_database(self, query):
        """Perform database lookups based on the query"""
        # This will be implemented when database connectivity is established
        pass


# Web server routes
@app.route('/health', methods=['GET'])
def health_check():
    """Health check endpoint"""
    return jsonify({"status": "ok", "service": "hazel-tts"})


@app.route('/process', methods=['POST'])
def process_audio():
    """Process audio file and return synthesized speech"""
    logger.info("Received audio processing request")
    
    try:
        # Check if the post request has the audio file
        if 'audio' not in request.files:
            logger.error("No audio file in request")
            return jsonify({"error": "No audio file provided"}), 400
            
        audio_file = request.files['audio']
        
        if audio_file.filename == '':
            logger.error("Empty audio filename")
            return jsonify({"error": "Empty audio filename"}), 400
            
        # Create temp files for processing
        audio_fd, audio_path = tempfile.mkstemp(suffix='.wav')
        response_fd, response_path = tempfile.mkstemp(suffix='.wav')
        
        try:
            # Save uploaded file
            audio_file.save(audio_path)
            logger.info(f"Saved uploaded audio to: {audio_path}")
            
            # Step 1: Transcribe speech to text
            stt = HazelSTT()
            transcript = stt.transcribe(audio_path)
            
            if not transcript:
                transcript = "I'm sorry, I couldn't understand what you said."
                
            # Step 2: Process the query
            conversation = HazelConversation()
            response_text = conversation.process_query(transcript)
            
            # Step 3: Convert response to speech
            tts = HazelTTS()
            success = tts.synthesize(response_text, response_path)
            
            if not success:
                logger.error("Failed to synthesize speech")
                return jsonify({"error": "Failed to synthesize speech"}), 500
                
            logger.info("Conversation processing completed successfully")
            
            # Return the audio file
            return send_file(
                response_path,
                mimetype="audio/wav",
                as_attachment=True,
                download_name="hazel_response.wav"
            )
            
        finally:
            # Clean up temp files
            os.close(audio_fd)
            os.close(response_fd)
            try:
                os.unlink(audio_path)
            except:
                pass
                
    except Exception as e:
        logger.error(f"Error in processing request: {str(e)}")
        return jsonify({"error": str(e)}), 500


def cli_main():
    """Command-line interface for Hazel"""
    parser = argparse.ArgumentParser(description="Hazel STT/TTS Processing")
    parser.add_argument("--audio", help="Path to input audio file for STT")
    parser.add_argument("--output", help="Path to output audio file for TTS")
    parser.add_argument("--text", help="Text to synthesize (for TTS only)")
    parser.add_argument("--mode", choices=["stt", "tts", "conversation"], 
                       default="conversation", help="Processing mode")
    parser.add_argument("--server", action="store_true", help="Run as a web server")
    parser.add_argument("--port", type=int, default=5000, help="Port for web server mode")
    
    args = parser.parse_args()
    
    # Run as web server if requested
    if args.server:
        logger.info(f"Starting Hazel TTS server on port {args.port}")
        app.run(host='0.0.0.0', port=args.port, debug=False)
        return 0
    
    # Otherwise, run in CLI mode
    try:
        if args.mode == "stt":
            # Speech-to-text only mode
            if not args.audio:
                logger.error("Audio input file required for STT mode")
                return 1
                
            stt = HazelSTT()
            transcript = stt.transcribe(args.audio)
            print(f"Transcript: {transcript}")
            
        elif args.mode == "tts":
            # Text-to-speech only mode
            if not args.text or not args.output:
                logger.error("Text input and output file required for TTS mode")
                return 1
                
            tts = HazelTTS()
            tts.synthesize(args.text, args.output)
            print(f"Speech saved to: {args.output}")
            
        elif args.mode == "conversation":
            # Full conversation mode
            if not args.audio or not args.output:
                logger.error("Audio input and output file required for conversation mode")
                return 1
                
            # Step 1: Transcribe speech to text
            stt = HazelSTT()
            transcript = stt.transcribe(args.audio)
            print(f"Transcript: {transcript}")
            
            if not transcript:
                logger.error("Failed to transcribe audio")
                return 1
                
            # Step 2: Process the query
            conversation = HazelConversation()
            response = conversation.process_query(transcript)
            print(f"Response: {response}")
            
            # Step 3: Convert response to speech
            tts = HazelTTS()
            success = tts.synthesize(response, args.output)
            
            if not success:
                logger.error("Failed to synthesize speech")
                return 1
                
            logger.info("Conversation processing completed successfully")
            print(f"Response audio saved to: {args.output}")
            
        return 0
        
    except Exception as e:
        logger.error(f"Error in main process: {str(e)}")
        return 1


if __name__ == "__main__":
    sys.exit(cli_main())

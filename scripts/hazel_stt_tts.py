#!/usr/bin/env python3
"""
Hazel STT/TTS Integration Script
This script handles the integration between FreePBX/Asterisk and Google's speech services.
It should be called by the AGI script when *8 is triggered.
"""

import os
import sys
import json
import requests
import argparse
from google.cloud import speech
from google.cloud import texttospeech
import base64
import logging

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler("/app/logs/hazel_stt_tts.log"),
        logging.StreamHandler()
    ]
)
logger = logging.getLogger("hazel")

class HazelSTT:
    """Handles speech-to-text conversion using Google's API"""
    
    def __init__(self, api_key=None):
        self.api_key = api_key or os.environ.get('GOOGLE_API_KEY')
        if not self.api_key:
            raise ValueError("Google API key not provided")
        
        # Initialize Google Speech client
        self.client = speech.SpeechClient.from_service_account_info(
            json.loads(base64.b64decode(self.api_key))
        )
        
    def transcribe(self, audio_file_path, language_code="en-US"):
        """Transcribe speech from an audio file to text"""
        logger.info(f"Transcribing audio file: {audio_file_path}")
        
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
            return None


class HazelTTS:
    """Handles text-to-speech conversion using Google's API"""
    
    def __init__(self, api_key=None):
        self.api_key = api_key or os.environ.get('GOOGLE_API_KEY')
        if not self.api_key:
            raise ValueError("Google API key not provided")
        
        # Initialize Google TTS client
        self.client = texttospeech.TextToSpeechClient.from_service_account_info(
            json.loads(base64.b64decode(self.api_key))
        )
        
    def synthesize(self, text, output_file_path, language_code="en-US"):
        """Convert text to speech and save as audio file"""
        logger.info(f"Synthesizing text: {text}")
        
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
            return False


class HazelConversation:
    """Handles the conversation flow and database lookups"""
    
    def __init__(self, db_connection=None):
        self.db_connection = db_connection
        
    def process_query(self, query_text):
        """Process the query and generate a response"""
        logger.info(f"Processing query: {query_text}")
        
        # Simple response logic - will be expanded with actual NLP and database lookups
        if "hello" in query_text.lower() or "hi" in query_text.lower():
            return "Hello! I am Hazel, your communications assistant. How can I help you today?"
        
        elif "weather" in query_text.lower():
            return "I'm sorry, I don't have access to weather information yet. This feature is coming soon."
        
        elif "help" in query_text.lower():
            return "I can answer your questions and help you with various tasks. My capabilities are growing every day."
            
        elif "goodbye" in query_text.lower() or "bye" in query_text.lower():
            return "Goodbye! Feel free to call me again if you need assistance."
            
        else:
            return "I'm still learning how to respond to that. Could you please try asking something else?"
            
    def lookup_database(self, query):
        """Perform database lookups based on the query"""
        # This will be implemented when database connectivity is established
        pass


def main():
    parser = argparse.ArgumentParser(description="Hazel STT/TTS Processing")
    parser.add_argument("--audio", help="Path to input audio file for STT")
    parser.add_argument("--output", help="Path to output audio file for TTS")
    parser.add_argument("--text", help="Text to synthesize (for TTS only)")
    parser.add_argument("--mode", choices=["stt", "tts", "conversation"], 
                        default="conversation", help="Processing mode")
    
    args = parser.parse_args()
    
    try:
        if args.mode == "stt":
            # Speech-to-text only mode
            if not args.audio:
                logger.error("Audio input file required for STT mode")
                return 1
                
            stt = HazelSTT()
            transcript = stt.transcribe(args.audio)
            print(transcript)
            
        elif args.mode == "tts":
            # Text-to-speech only mode
            if not args.text or not args.output:
                logger.error("Text input and output file required for TTS mode")
                return 1
                
            tts = HazelTTS()
            tts.synthesize(args.text, args.output)
            
        elif args.mode == "conversation":
            # Full conversation mode
            if not args.audio or not args.output:
                logger.error("Audio input and output file required for conversation mode")
                return 1
                
            # Step 1: Transcribe speech to text
            stt = HazelSTT()
            transcript = stt.transcribe(args.audio)
            
            if not transcript:
                logger.error("Failed to transcribe audio")
                return 1
                
            # Step 2: Process the query
            conversation = HazelConversation()
            response = conversation.process_query(transcript)
            
            # Step 3: Convert response to speech
            tts = HazelTTS()
            success = tts.synthesize(response, args.output)
            
            if not success:
                logger.error("Failed to synthesize speech")
                return 1
                
            logger.info("Conversation processing completed successfully")
            
        return 0
        
    except Exception as e:
        logger.error(f"Error in main process: {str(e)}")
        return 1


if __name__ == "__main__":
    sys.exit(main())

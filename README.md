# HazelPBX

## Project Overview
HazelPBX is a Docker-based implementation of FreePBX that integrates speech-to-text and text-to-speech capabilities. Hazel acts as a unified communications goddess, capable of influencing various communication streams.

## Goals
- Create a containerized FreePBX system using Docker
- Implement speech-to-text and text-to-speech integrations with Google
- Configure a SIP extension (extension10) for local network phone connection
- Set up *8 feature code to activate STT and TTS conversation loops
- Use voip.ms as an exit node for external communications
- Implement conversational capabilities to answer questions and retrieve database information
- Maintain secure password management through a dedicated password file

## Project Structure
- `/docker` - Docker composition files and container configurations
- `/config` - Configuration files for FreePBX and related services
- `/scripts` - Helper scripts for initialization and management
- `/passwords` - Secure password storage (gitignored)
- `/docs` - Documentation

## Technology Stack
- Docker and Docker Compose
- FreePBX (Asterisk-based PBX)
- Google Speech-to-Text and Text-to-Speech APIs
- SIP protocol for VoIP communications
- voip.ms as a SIP trunk provider

## Getting Started
1. Clone this repository
2. Create and populate the passwords file
3. Run the Docker Compose setup
4. Complete the FreePBX initialization process
5. Configure SIP extension and feature codes

## Important Notes
- The FreePBX initialization step must be completed before the system is operational
- Feature code *8 will trigger the speech processing loop
- All sensitive credentials are stored in the password file for easy management

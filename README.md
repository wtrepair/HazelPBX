# HazelPBX

![HazelPBX](https://img.shields.io/badge/version-1.0.0-blue)
![FreePBX](https://img.shields.io/badge/FreePBX-latest-green)
![License](https://img.shields.io/badge/license-MIT-orange)

## Project Overview

HazelPBX is a Docker-based implementation of FreePBX that integrates speech-to-text and text-to-speech capabilities. Hazel acts as a unified communications goddess, capable of influencing various communication streams. It creates a powerful VoIP system with AI voice assistant functionality activated by dialing *8.

## 🌟 Features

- **Containerized VoIP Platform**: Complete FreePBX system in Docker containers
- **AI Voice Assistant**: Speech-to-text and text-to-speech powered by Google Cloud
- **VoIP.ms Integration**: Seamless connection to VoIP.ms for external calling
- **Simple Activation**: Dial *8 from any extension to access Hazel
- **IP Phone Support**: Easily connect SIP phones to the system
- **Secure Configuration**: Separate password management for all credentials

## 🗂️ Project Structure

- `/docker` - Docker composition files and container configurations
- `/config` - Configuration files for FreePBX and related services
- `/scripts` - Helper scripts for initialization and management
- `/passwords` - Secure password storage (gitignored)
- `/docs` - Comprehensive documentation
  - `freepbx-setup.md` - Detailed FreePBX configuration guide
  - `freepbx-voipms-config.md` - VoIP.ms trunk integration instructions
  - `ip-phone-grandstream-gxp2135.md` - Grandstream phone configuration

## 🧰 Technology Stack

- **Docker and Docker Compose**: For containerization and orchestration
- **FreePBX**: Asterisk-based PBX system for call management
- **Google Speech-to-Text and Text-to-Speech APIs**: For voice assistant functionality
- **SIP/RTP**: Protocols for VoIP communications
- **voip.ms**: SIP trunk provider for external connectivity
- **Python Flask**: For the Hazel assistant backend service

## 📋 Prerequisites

- Docker and Docker Compose installed
- VoIP.ms account with SIP credentials
- SIP phone or softphone for testing
- Google Cloud account with STT/TTS API access (optional for full functionality)

## 🚀 Installation

### 1. Clone the repository

```bash
git clone https://github.com/wtrepair/HazelPBX.git
cd HazelPBX
```

### 2. Set up credentials

```bash
# Copy the blank password template
cp passwords/passwords.blank passwords/passwords.env

# Edit with your actual credentials
nano passwords/passwords.env
```

Make sure to fill in:
- VoIP.ms account information
- FreePBX admin credentials
- Extension 10 password
- Google API credentials (if using speech features)

### 3. Start the Docker containers

```bash
cd docker
docker-compose up -d
```

### 4. Initialize FreePBX

```bash
# View the initialization instructions
./scripts/init-freepbx.sh
```

Access the FreePBX web interface at http://localhost:8080

### 5. Configure VoIP.ms trunk

Follow the detailed instructions in `docs/freepbx-voipms-config.md` to set up:
- SIP trunk to VoIP.ms
- Outbound routes
- Inbound routes (if you have DIDs)

### 6. Set up extension 10

```bash
# Create extension 10 in FreePBX admin interface
# Configure your IP phone using docs/ip-phone-grandstream-gxp2135.md
```

### 7. Deploy Hazel Assistant

```bash
# Deploy the Hazel Assistant integration
./scripts/deploy-hazel-asterisk.sh
```

## 🔍 Usage

1. Make and receive calls through your FreePBX system
2. Dial *8 from any extension to activate Hazel Assistant
3. Speak naturally to Hazel and she will respond using AI-powered speech

## 📚 Documentation

Refer to the `/docs` directory for detailed configuration guides:

- **FreePBX Setup**: Complete FreePBX configuration instructions
- **VoIP.ms Integration**: How to connect FreePBX to VoIP.ms
- **Dialing Rules**: Understanding and customizing dialing patterns
- **IP Phone Setup**: Configuring Grandstream phones with the system

## ⚠️ Important Notes

- The FreePBX initialization step must be completed before the system is operational
- Feature code *8 will trigger the Hazel speech processing loop
- All sensitive credentials are stored in the password file for easy management
- Web interface is accessible on port 8080 to avoid conflicts with local web servers
- VoIP.ms requires proper SIP credentials and server configuration

## 🔄 Updates

Check the repository regularly for updates and improvements to Hazel's capabilities.

## 📝 License

This project is available under the MIT License. See the LICENSE file for details.

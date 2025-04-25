# Grandstream GXP2135 Configuration Guide

> Check out [VoIP.ms YouTube channel](https://www.youtube.com/user/voipmsdotcom) to watch simple tutorials that will help you set up most of their features.

![Grandstream GXP2135](https://voip.ms/images/devices/grandstream-gxp2135.png)

The Grandstream GXP2135 is a high-profile desktop phone built for the busy user. It features a sleek high-end design, high call capacity, and rich functionality, making it the ideal choice for call-intensive workers within the HazelPBX environment.

## Table of Contents
- [General Settings](#general-settings)
- [Basic SIP Settings](#basic-sip-settings)
- [Common Errors](#common-errors)
  - [Outgoing Calls Issue](#outgoing-calls-issue)
- [Guide Links](#guide-links)

## SIP Account Setup

Once you have connected your device to your local network, you'll need to obtain the local IP address assigned to it:

1. From your IP phone navigate through the menus to obtain its IP address:
   ```
   Menu >> Status >> Network Status >> IPv4 Address
   ```

2. Open the IP address in your web browser.

3. When prompted for login credentials, use:
   - Username: admin
   - Password: admin

## General Settings

After logging in to the web interface:

1. Navigate to: **Account >> Account # >> General Settings**

2. Configure the following settings with your VoIP.ms account information:

   | Setting | Description |
   |---------|-------------|
   | **Account Name** | The name for this account that will be displayed on the LCD screen of your phone |
   | **SIP Server** | The server that you will use for the registration (one of VoIP.ms servers, choose the one closest to your location) |
   | **SIP User ID** | The account or sub-account number that you will be using for this line |
   | **Authenticate Password** | The password for the account or sub-account |
   | **Name** | The name that will be used as Caller-ID Name |

3. Click "Save and Apply"

**IMPORTANT NOTE FOR NAME FIELD:**
- Enter your outbound Caller ID Name in capital letters for clearer visibility on receiving devices
- Do NOT use any special characters as they will not display properly
- Maximum 15 characters (some Canadian providers won't show more)
- Spaces are allowed in a caller ID name

## Basic SIP Settings

Next, configure the SIP registration settings:

1. Navigate to: **Account # >> SIP Settings >> Basic Settings**

2. Configure the following:
   - SIP Registration: **Yes**
   - Register Expiration: **5** (minutes)
   - Enable OPTIONS Keep Alive: **Yes**

3. Click "Save and Apply"

## Common Errors

### Outgoing Calls Issue

If you're able to receive incoming calls but outgoing calls fail with "No response" error:

1. Go to **Accounts > Account X > SIP > Custom SIP Header** and disable:
   - Use X-Grandstream-PBX Header
   - Use P-Access-Network-Info Header
   - Use P-Emergency-Info Header

2. Go to **Accounts > Account X > SIP > Audio Settings**, and:
   - Choose codec G.722 as preferred Vocoder
   - Set the rest with PCMU

## Guide Links

For additional information, refer to the official Grandstream documentation:
- [User Manual](https://www.grandstream.com/products/ip-voice-telephony/enterprise-ip-phones/product/gxp2135/download)
- [Admin Manual](https://www.grandstream.com/products/ip-voice-telephony/enterprise-ip-phones/product/gxp2135/download)

---

*Note: When integrating with HazelPBX, ensure you use extension10 as configured in the HazelPBX system, and that you can access the *8 feature code for the voice assistant functionality.*

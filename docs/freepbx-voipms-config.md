# FreePBX and VoIP.ms Integration Guide

This document provides detailed information on configuring FreePBX with VoIP.ms for use with the HazelPBX system.

## Table of Contents
- [Important Security Information](#important-security-information)
- [Creating a Trunk](#creating-a-trunk)
  - [SIP Trunk Configuration](#sip-trunk)
  - [IAX2 Trunk Configuration](#iax2-trunk)
- [Outbound Routes](#outbound-routes)
- [Inbound Routes](#inbound-routes)
- [PJSIP Trunk Configuration](#configuration-using-a-pjsip-trunk)
- [Whitelisting VoIP.ms IPs](#whitelisting-voipms-ips-in-freepbx)

## Important Security Information

A critical vulnerability has been discovered that can affect FreePBX versions between 13.0.12 and 13.0.26. An unauthenticated remote attacker can run shell commands as the Asterisk user of any FreePBX machine with 'Recordings'. This has been fixed in Recordings 13.0.27.

For FreePBX versions prior to 12, there is a Zero-Day Remote Code Execution and Privilege Escalation exploit that allows users to bypass authentication and gain 'Full Administrator' access when the 'FreePBX ARI Framework module/Asterisk Recording Interface (ARI)' is present.

**Always use the latest version of FreePBX and keep all modules updated.**

## Creating a Trunk

To connect your FreePBX server with VoIP.ms, you need to create a trunk. In your FreePBX GUI, follow this path: 
`Connectivity >> Trunks >> Add SIP (chan_sip) Trunk`.

### SIP Trunk

Use the following configuration for your SIP trunk:

#### General Settings
- **Trunk name**: A descriptive name, such as "voipms". Remember that you can manage multiple DID numbers with the same trunk using inbound routes.
- **Outbound CallerID**: The 10-digit valid caller ID number for outbound calls. This can be overridden from your extension's settings.

#### Dialed Number Manipulation Rules
You can set outbound rules to manipulate the dialed number before sending it out this trunk. If no rule applies, the number is not changed. (Optional)

#### Outgoing Settings
```
canreinvite=nonat
nat=yes
context=from-trunk
host=atlanta.voip.ms
username=100000
fromuser=100000
secret=*****
type=peer
disallow=all
allow=ulaw
trustrpid=yes
sendrpid=yes
insecure=invite
qualify=yes
```

**Important Notes:**
- Replace "atlanta.voip.ms" with the server closest to your location
- Replace "100000" with your 6-digit Main SIP Account User ID or Sub Account username
- Replace "*****" with the password associated with the Main or Sub-account
- Avoid using the '#' character in the password as it will cause authentication issues
- Uncomment `allow=g729` if you purchased g.729 from Digium

#### Incoming Settings
This section must be blank. Delete any default settings.

**IMPORTANT**: On your VoIP.ms portal, go to Main Menu > Account Settings > Inbound Settings tab, make sure to select SIP (or IAX) and change 'Inbound Settings to IP PBX Server, Asterisk or Softswitch'.

#### Registration
If using "registration" as the authentication method (leave blank for IP Authentication):
```
100000:YourPassword@atlanta.voip.ms:5060
```

Replace with your actual credentials and server.

#### TLS Configuration
To use TLS with FreePBX:

1. Enable "Encrypted SIP Traffic" for your Main account or sub-account
2. Configure your peer details with:
```
host=atlanta1.voip.ms
username=your account/sub account
fromuser=your account/sub account
secret=your password
transport=tls
encryption=yes
qualify=yes
qualifyfreq=50
nat=yes
type=peer
directmedia=no
context=from-trunk
insecure=invite
sendrpid=yes
trustrpid=yes
disallow=all
allow=g729&ulaw&gsm
```

3. Use the following Register String:
```
tls://Username:Password@atlanta1.voip.ms:5061~300
```

4. In FreePBX, go to Settings >> Asterisk SIP settings >> Chan SIP settings >> TLS/SSL/SRTP Settings and set:
   - Enable TLS: Yes
   - Don't verify server: Yes

### IAX2 Trunk

Use the following configuration for your IAX2 trunk:

#### General Settings
- **Trunk name**: Must be "voipms" to avoid registration and call issues
- **Outbound CallerID**: The 10-digit valid caller ID number for outbound calls

#### Outgoing Settings
```
type=friend
username=100000
secret=*****
context=from-trunk
host=atlanta.voip.ms
disallow=all
allow=ulaw
insecure=port,invite
requirecalltoken=no
qualify=yes
```

**Important Notes:**
- Replace "atlanta.voip.ms" with the server closest to your location
- Replace "100000" with your 6-digit Main SIP Account User ID or Sub Account username
- Replace "*****" with the password associated with the Main or Sub-account

#### Incoming Settings
This section must be blank. Delete any default settings.

#### Registration
If using "registration" as the authentication method (leave blank for IP Authentication):
```
100000:YourPassword@atlanta.voip.ms:4569
```

## Outbound Routes

Once you have your trunk configured, you need an outbound route to make calls. Go to "Connectivity" menu and then select "Outbound routes".

### Route Settings
- **Route Name**: Name that describes what type of calls this route matches (e.g., 'local', 'longdistance')
- **Route CID**: Optional - If set, this will override all CIDs except in special cases

### Dial Patterns
A Dial Pattern is a unique set of digits that will select this route. Rules:
- **X**: matches any digit from 0-9
- **Z**: matches any digit from 2-9
- **[1237-9]**: matches any digit in the brackets (example: 1,2,3,7,8,9)
- **.**: wildcard, matches one or more dialed digits

Recommended Dial patterns:
- 1NXXNXXXXXX
- NXXNXXXXXX
- 4XXX (for echo test and DTMF test)

### Trunk Sequence for Matched Routes
Select your voip.ms trunk to use for these outbound call patterns.

## Inbound Routes

If you have DID numbers with VoIP.ms, you need inbound routes to manage them. Go to "Connectivity" menu > "Inbound routes".

### Add Incoming Route
- **Description**: A meaningful description of this incoming route
- **DID number**: Your VoIP.ms DID number with only 10 digits (without dots, commas, spaces or the 1 in front)

### Set Destination
Configure where incoming calls to this DID should go (extension, IVR, recording, voice mail, etc.)

**Remember** to click the red "Apply Config" button after making any changes.

## Configuration Using a PJSIP Trunk

Please refer to the VoIP.ms wiki article for PJSIP trunk configuration.

## Whitelisting VoIP.ms IPs in FreePBX

To whitelist VoIP.ms servers in FreePBX:
1. Go to System Admin > Intrusion Protection > Whitelist
2. Add the VoIP.ms points of presence IPs

For more information on the IPs related to VoIP.ms servers, visit the VoIP.ms wiki.

---

*Note: This information is adapted from VoIP.ms wiki documentation. For the most current information, please refer to the official VoIP.ms documentation.*

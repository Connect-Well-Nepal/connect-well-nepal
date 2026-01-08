# Agora Video Call - Production Setup Guide

## Overview

This guide explains how to set up Agora video calls for production use with proper token authentication.

## Current Status

- **App ID**: `0f3b01a62b1e4644b1ae017327c3be69`
- **Token Service**: `lib/services/agora_token_service.dart`
- **Video Call Service**: `lib/services/video_call_service_mobile.dart`

## Production Requirements

### 1. Enable Token Authentication in Agora Console

1. Go to [Agora Console](https://console.agora.io/)
2. Select your project: **connectwellnepal**
3. Navigate to: **Project Management** → **Edit** → **Security**
4. **Enable Token Authentication** (required for production)
5. Copy your **App Certificate** (you'll need this for backend)

### 2. Set Up Backend Token Server

**IMPORTANT**: Never expose your App Certificate in client code. Always generate tokens on your backend server.

#### Option A: Node.js/Express Backend

```bash
npm install agora-access-token express
```

```javascript
const express = require('express');
const { RtcTokenBuilder, RtcRole } = require('agora-access-token');

const app = express();
app.use(express.json());

const APP_ID = '0f3b01a62b1e4644b1ae017327c3be69';
const APP_CERTIFICATE = 'YOUR_APP_CERTIFICATE_FROM_CONSOLE';

app.post('/agora/token', (req, res) => {
  const { channelName, uid, role, expireTime } = req.body;
  
  const currentTimestamp = Math.floor(Date.now() / 1000);
  const privilegeExpiredTs = currentTimestamp + (expireTime || 86400); // 24 hours
  
  const rtcRole = role === 2 ? RtcRole.SUBSCRIBER : RtcRole.PUBLISHER;
  
  const token = RtcTokenBuilder.buildTokenWithUid(
    APP_ID,
    APP_CERTIFICATE,
    channelName,
    uid || 0,
    rtcRole,
    privilegeExpiredTs
  );
  
  res.json({ token });
});

app.listen(3000, () => {
  console.log('Token server running on port 3000');
});
```

#### Option B: Python/Flask Backend

```bash
pip install agora-token-builder flask
```

```python
from flask import Flask, request, jsonify
from agora_token_builder import RtcTokenBuilder
import time

app = Flask(__name__)

APP_ID = '0f3b01a62b1e4644b1ae017327c3be69'
APP_CERTIFICATE = 'YOUR_APP_CERTIFICATE_FROM_CONSOLE'

@app.route('/agora/token', methods=['POST'])
def get_token():
    data = request.json
    channel_name = data['channelName']
    uid = data.get('uid', 0)
    expire_time = data.get('expireTime', 86400)  # 24 hours
    
    current_timestamp = int(time.time())
    privilege_expired_ts = current_timestamp + expire_time
    
    token = RtcTokenBuilder.buildTokenWithUid(
        APP_ID,
        APP_CERTIFICATE,
        channel_name,
        uid,
        RtcTokenBuilder.Role.Role_Publisher,
        privilege_expired_ts
    )
    
    return jsonify({'token': token})

if __name__ == '__main__':
    app.run(port=3000)
```

#### Option C: Firebase Cloud Functions

```javascript
const functions = require('firebase-functions');
const { RtcTokenBuilder, RtcRole } = require('agora-access-token');

exports.generateAgoraToken = functions.https.onRequest(async (req, res) => {
  // Enable CORS
  res.set('Access-Control-Allow-Origin', '*');
  
  if (req.method !== 'POST') {
    return res.status(405).send('Method Not Allowed');
  }
  
  const { channelName, uid, role, expireTime } = req.body;
  const APP_ID = '0f3b01a62b1e4644b1ae017327c3be69';
  const APP_CERTIFICATE = functions.config().agora.certificate; // Store in Firebase config
  
  const currentTimestamp = Math.floor(Date.now() / 1000);
  const privilegeExpiredTs = currentTimestamp + (expireTime || 86400);
  
  const rtcRole = role === 2 ? RtcRole.SUBSCRIBER : RtcRole.PUBLISHER;
  
  const token = RtcTokenBuilder.buildTokenWithUid(
    APP_ID,
    APP_CERTIFICATE,
    channelName,
    uid || 0,
    rtcRole,
    privilegeExpiredTs
  );
  
  res.json({ token });
});
```

### 3. Update Flutter App Configuration

Edit `lib/services/agora_token_service.dart`:

```dart
// Set your backend token server URL
static const String? tokenServerUrl = "https://your-api.com/agora/token";
```

### 4. Security Best Practices

1. **Never commit App Certificate to Git**
   - Store in environment variables
   - Use secure config management (Firebase Config, AWS Secrets Manager, etc.)

2. **Add Authentication to Token Endpoint**
   - Require user authentication before generating tokens
   - Validate user permissions for specific channels

3. **Implement Token Refresh**
   - Tokens expire after 24 hours (configurable)
   - Implement automatic token refresh before expiration
   - Handle token expiration gracefully

4. **Rate Limiting**
   - Limit token generation requests per user
   - Prevent abuse of token generation endpoint

### 5. Testing in Production

1. **Test Token Generation**
   ```bash
   curl -X POST https://your-api.com/agora/token \
     -H "Content-Type: application/json" \
     -d '{"channelName":"test_channel","uid":1234}'
   ```

2. **Verify Token Works**
   - Use generated token in video call
   - Check Agora Console for connection logs
   - Monitor for token-related errors

### 6. Monitoring & Debugging

- **Agora Console**: Monitor call quality, connection status
- **Backend Logs**: Track token generation requests
- **Error Handling**: Log token generation failures
- **Analytics**: Track video call usage and errors

## Development vs Production

### Development (Current)
- Token-less mode (empty tokens)
- Or temporary tokens from Agora Console
- Quick testing without backend setup

### Production (Required)
- Token authentication enabled
- Backend token server
- Secure App Certificate storage
- User authentication for token generation

## Migration Checklist

- [ ] Enable token authentication in Agora Console
- [ ] Set up backend token server
- [ ] Update `tokenServerUrl` in `agora_token_service.dart`
- [ ] Test token generation endpoint
- [ ] Test video calls with generated tokens
- [ ] Implement token refresh mechanism
- [ ] Add error handling for token failures
- [ ] Set up monitoring and logging
- [ ] Remove any hardcoded App Certificates from code
- [ ] Test in staging environment before production

## Troubleshooting

### Error: Invalid Token (-8)
- Check if token authentication is enabled in console
- Verify token is generated correctly
- Check token expiration time
- Ensure App Certificate matches console

### Error: Token Expired
- Implement token refresh before expiration
- Reduce token expiration time for testing
- Check server time synchronization

### Error: Failed to Fetch Token
- Verify backend server is accessible
- Check network connectivity
- Verify endpoint URL is correct
- Check backend server logs

## Additional Resources

- [Agora Token Documentation](https://docs.agora.io/en/Video/token_server)
- [Agora Token Builder (Node.js)](https://www.npmjs.com/package/agora-access-token)
- [Agora Token Builder (Python)](https://pypi.org/project/agora-token-builder/)
- [Agora Console](https://console.agora.io/)


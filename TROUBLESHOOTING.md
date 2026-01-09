# 🔧 Troubleshooting Guide

## Common Errors and Solutions

### 1. GoogleApiManager DEVELOPER_ERROR

**Error Message:**
```
W/GoogleApiManager: Not showing notification since connectionResult is not user-facing: 
ConnectionResult{statusCode=DEVELOPER_ERROR, resolution=null, message=null}
```

**Cause:**
This error typically occurs when:
- Google API services (like Places API) are not enabled in Google Cloud Console
- API keys have restrictions that don't match your app configuration
- The error is handled gracefully in the background and doesn't affect core functionality

**Impact:** ⚠️ **Low Priority** - This is a background error that's being handled. It may affect Google Places API if not configured, but doesn't crash the app.

**Solution:**
1. **If using Google Places API:**
   - Go to [Google Cloud Console](https://console.cloud.google.com/)
   - Enable "Places API" for your project
   - Ensure API key restrictions allow your app

2. **If not using Places API:**
   - The error can be safely ignored as the app falls back to OpenStreetMap (OSM) Places service
   - The app is designed to work without Google Places API

**Note:** Your app already uses `OSMPlacesService` as a fallback, so this error won't prevent location-based features from working.

---

### 2. CameraMetadataJV Warnings

**Error Message:**
```
W/CameraMetadataJV: Expect face scores and rectangles to be non-null
```

**Cause:**
These warnings appear when the camera preview tries to access face detection metadata, but the device or camera doesn't provide face detection features.

**Impact:** ✅ **No Impact** - These are harmless warnings that don't affect functionality.

**Solution:**
- These warnings can be safely ignored
- They're common on devices without face detection capabilities
- The camera and video call features work normally despite these warnings

---

### 3. Lost Connection to Device

**Error Message:**
```
Lost connection to device.
```

**Cause:**
This happens when:
- The app crashes unexpectedly
- The device/emulator disconnects
- The app is manually closed
- System memory issues

**Solution:**
1. **Check for crashes:**
   ```bash
   flutter logs
   ```
   
2. **Check app stability:**
   - Run the app again: `flutter run`
   - Check if specific screens cause crashes
   - Review recent code changes

3. **Device connection:**
   ```bash
   # Check connected devices
   flutter devices
   
   # Restart adb if needed
   adb kill-server && adb start-server
   ```

4. **Clear build cache:**
   ```bash
   flutter clean
   flutter pub get
   flutter run
   ```

---

## Firebase Configuration Issues

### Missing google-services.json

**Symptoms:**
- `DEVELOPER_ERROR` in logs
- Google Sign-In not working
- Firebase initialization failures

**Solution:**
1. Download `google-services.json` from Firebase Console
2. Place it in `android/app/google-services.json`
3. Ensure the package name matches: `com.connectwellnepal.connect_well_nepal`

### SHA-1 Certificate Fingerprint

**Your Current SHA-1:** `98:91:27:11:13:95:95:CE:58:AF:5F:AD:69:6C:9D:80:A6:C1:AC:0B`

**Status:** ✅ Already registered in `google-services.json`

**To verify:**
```bash
keytool -list -v -keystore ~/.android/debug.keystore \
  -alias androiddebugkey -storepass android -keypass android
```

**To add to Firebase Console:**
1. Go to Firebase Console → Project Settings
2. Add SHA-1 fingerprint under "Your apps"
3. Download updated `google-services.json`

---

## Video Call Issues

### Agora RTC Connection Problems

**Symptoms:**
- Video calls not connecting
- "Channel join failed" errors

**Solution:**
1. **Check Agora App ID and Token:**
   - Verify Agora credentials in `AGORA_PRODUCTION_SETUP.md`
   - Ensure token service is configured

2. **Check Permissions:**
   - Camera permission: ✅ Already in AndroidManifest.xml
   - Microphone permission: ✅ Already in AndroidManifest.xml

3. **Network Issues:**
   - Ensure device has internet connection
   - Check firewall settings
   - Verify Agora service availability

---

## Build Issues

### Clean Build Process

If experiencing build issues:

```bash
# Clean Flutter build
flutter clean

# Get dependencies
flutter pub get

# For Android specifically
cd android
./gradlew clean
cd ..

# Rebuild
flutter run
```

### Gradle Issues

If Gradle build fails:

```bash
cd android
./gradlew clean
./gradlew build --refresh-dependencies
cd ..
flutter run
```

---

## Performance Issues

### App Running Slowly

1. **Check for memory leaks:**
   - Profile with Flutter DevTools
   - Check for disposed controllers still in use

2. **Reduce app size:**
   ```bash
   flutter build apk --split-per-abi
   ```

3. **Optimize images:**
   - Use compressed image formats
   - Implement image caching

---

## Debugging Tips

### Enable Verbose Logging

```bash
flutter run --verbose
```

### Check Specific Errors

```bash
# Android logs
adb logcat | grep -i error

# Flutter logs only
flutter logs
```

### Device-Specific Testing

```bash
# List available devices
flutter devices

# Run on specific device
flutter run -d <device-id>
```

---

## Getting Help

### Check Logs First

Always check logs when encountering issues:
```bash
flutter logs
```

### Common Debugging Commands

```bash
# Check Flutter doctor
flutter doctor -v

# Analyze code
flutter analyze

# Run tests
flutter test

# Check for outdated packages
flutter pub outdated
```

---

## Status of Current Issues

### ✅ Resolved:
- SHA-1 fingerprint properly configured
- google-services.json present
- Permissions correctly set in AndroidManifest.xml

### ⚠️ Known Non-Critical Issues:
- **GoogleApiManager DEVELOPER_ERROR**: Background error, handled gracefully
- **CameraMetadataJV warnings**: Harmless camera warnings

### 🔍 To Investigate:
- If app crashes frequently, check specific screens/features
- Monitor logs for pattern in crash reports

---

## Quick Fixes

### Reset Everything

```bash
# Clean everything
flutter clean
cd android && ./gradlew clean && cd ..
rm -rf build/

# Rebuild
flutter pub get
flutter run
```

### Reinstall App

```bash
# Uninstall from device
adb uninstall com.connectwellnepal.connect_well_nepal

# Reinstall
flutter run
```

---

**Last Updated:** December 30, 2024  
**App Version:** 1.0.0+1

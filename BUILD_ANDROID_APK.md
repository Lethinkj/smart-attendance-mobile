# 📱 Android APK Build Guide

## Method 1: Using Android Studio (Recommended)

### Step 1: Install Android Studio
1. Download from: https://developer.android.com/studio
2. Run installer and follow setup wizard
3. Let it install Android SDK components
4. Accept all license agreements

### Step 2: Verify Setup
```bash
flutter doctor
```
Should show ✅ for Android toolchain

### Step 3: Build APK
```bash
cd "d:\SIH2025\smart_attendance\mobile"
flutter build apk
```

## Method 2: Command Line Tools Only (Advanced)

### Step 1: Download Android SDK Command Line Tools
1. Go to: https://developer.android.com/studio#command-tools
2. Download "Command line tools only" for Windows
3. Extract to: `C:\Android\cmdline-tools\latest\`

### Step 2: Set Environment Variables
```powershell
$env:ANDROID_HOME = "C:\Android"
$env:PATH += ";C:\Android\cmdline-tools\latest\bin;C:\Android\platform-tools"
```

### Step 3: Install SDK Components
```bash
sdkmanager --install "platform-tools" "platforms;android-33" "build-tools;33.0.0"
flutter doctor --android-licenses
```

### Step 4: Build APK
```bash
flutter build apk
```

## Build Variations

### Debug APK (Faster build, larger size)
```bash
flutter build apk --debug
```

### Release APK (Optimized for distribution)
```bash
flutter build apk --release
```

### Split APKs by Architecture (Smaller files)
```bash
flutter build apk --split-per-abi
```

## APK Output Location
After successful build, APK will be located at:
```
build/app/outputs/flutter-apk/app-release.apk
```

## Troubleshooting

### Common Issues:
1. **"No Android SDK found"** → Install Android Studio or SDK Command Line Tools
2. **"License not accepted"** → Run `flutter doctor --android-licenses`
3. **"Gradle build failed"** → Check internet connection, clear cache with `flutter clean`

### Performance Tips:
- Use `flutter clean` before building if you encounter issues
- Ensure minimum 4GB RAM available during build
- Use `--verbose` flag to see detailed build logs

## App Signing (For Production)

### Generate Keystore
```bash
keytool -genkey -v -keystore android/app/smart-attendance-key.jks -keyalg RSA -keysize 2048 -validity 10000 -alias smart-attendance
```

### Configure Signing in android/app/build.gradle
```groovy
android {
    signingConfigs {
        release {
            keyAlias 'smart-attendance'
            keyPassword 'your-key-password'
            storeFile file('smart-attendance-key.jks')
            storePassword 'your-store-password'
        }
    }
    buildTypes {
        release {
            signingConfig signingConfigs.release
        }
    }
}
```

## Testing APK
1. Enable "Unknown Sources" on Android device
2. Transfer APK to device
3. Install and test all features
4. Check database connectivity
5. Test RFID functionality
6. Verify attendance marking works

## Final Notes
- Release APK size: ~15-25MB
- Minimum Android version: API 21 (Android 5.0)
- Required permissions: Internet, Storage, Camera (for RFID)
- Target architecture: ARM64, ARM32, x86_64

Happy Building! 🚀
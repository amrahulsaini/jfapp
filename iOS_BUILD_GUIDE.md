# iOS Build Instructions

## Prerequisites
You MUST have a Mac with Xcode to build iOS apps. Windows cannot build iOS apps.

## Option 1: Build on Mac

### Steps:
1. Install Xcode from Mac App Store
2. Install CocoaPods:
   ```bash
   sudo gem install cocoapods
   ```

3. Open Terminal and navigate to project:
   ```bash
   cd frontend_temp
   ```

4. Get Flutter dependencies:
   ```bash
   flutter pub get
   cd ios
   pod install
   cd ..
   ```

5. Build IPA:
   ```bash
   flutter build ios --release
   ```

6. Open in Xcode to sign and export:
   ```bash
   open ios/Runner.xcworkspace
   ```

7. In Xcode:
   - Select "Runner" target
   - Go to "Signing & Capabilities"
   - Select your Team
   - Archive: Product → Archive
   - Distribute App → Ad Hoc (for testing) or App Store (for release)

## Option 2: Use Codemagic (Cloud Build - FREE)

### Steps:
1. Sign up at https://codemagic.io (free for Flutter projects)
2. Connect your GitHub repository
3. Codemagic will detect the `codemagic.yaml` file
4. Add your Apple Developer credentials in Codemagic settings:
   - Team ID
   - App Store Connect API Key
5. Trigger build - it will build on Mac in the cloud
6. Download IPA from artifacts

## Option 3: Use GitHub Actions (FREE)

Create `.github/workflows/ios.yml` with macOS runner to automate builds.

## App Store Requirements

### Before uploading to App Store:
1. Apple Developer Account ($99/year)
2. App bundle ID: `com.jecrcfoundation.jf_app`
3. App icons in all required sizes
4. Screenshots (6.5", 5.5", 12.9" iPad)
5. Privacy policy URL
6. App description and keywords

### Current Version:
- Version: 0.1.0-beta
- Build: 1

## TestFlight Distribution (Recommended for Beta)

1. Build IPA using Xcode
2. Upload to App Store Connect
3. Submit for TestFlight review
4. Share TestFlight link with testers
5. Users install via TestFlight app

## Important Notes

- **You CANNOT build iOS on Windows** - it's technically impossible
- Use Codemagic for easiest cloud builds (no Mac needed)
- TestFlight is best for beta testing (100,000 testers, free)
- Enterprise distribution requires $299/year Apple Enterprise account

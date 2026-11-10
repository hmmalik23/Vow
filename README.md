# VOW Android APK build

This is an Android Studio / Gradle project wrapping the VOW v2 prototype in a native Android WebView shell.

## Build the APK in GitHub Actions (no Android SDK installation on your PC)
1. Create a GitHub repository, e.g. `vow-android`.
2. Upload the contents of this folder (including the hidden `.github` directory) to the repository's `main` branch.
3. Open the repository's **Actions** tab.
4. Select **Build VOW APK** and click **Run workflow** (or let the push trigger it).
5. Open the completed workflow run. Under **Artifacts**, download `VOW-Android-debug-APK`.
6. Extract the artifact and install `app-debug.apk` on your Android phone. You may need to allow installation from that browser/file manager.

## Current scope
The APK contains the VOW v2 front-end prototype. Data is stored locally in the app's WebView storage. Sign-in buttons are previews only. There is no live cloud authentication, remote database, multi-device sync, push notifications or legally verified e-signature yet.

## Before public distribution
This workflow creates a debug APK for testing, not a Play Store release. A release build needs a private signing key, secure key handling, package/version policy, app icon assets, privacy policy, testing and Play Console compliance. Never commit signing keys or secrets to GitHub.

The current build targets Android API 35 and minimum API 23. Google Play target API requirements can change; re-check before publishing.

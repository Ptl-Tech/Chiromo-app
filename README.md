# chiromo

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## Running on a physical Android device

After cloning, a few one-time environment fixes are usually needed before `flutter run` works on Windows:

1. **Flutter SDK on PATH.** Make sure the Flutter SDK's `bin` directory is on your user `PATH` (e.g. `C:\flut\flutter\bin`). Verify with `flutter --version`.

2. **Enable Windows Developer Mode.** Flutter needs symlink support to build with plugins. Run:
   ```
   start ms-settings:developers
   ```
   and toggle Developer Mode on.

3. **Use a JDK Gradle actually supports, not Android Studio's bundled JBR.** Newer Android Studio releases bundle a very recent JDK (e.g. JDK 25) that this project's Gradle/Kotlin toolchain can't parse yet — builds fail with a cryptic `FAILURE: Build failed with an exception. * What went wrong: <jdk version number>`. Fix:
   - Install a JDK 17 (e.g. [Eclipse Temurin 17](https://adoptium.net/temurin/releases/?version=17)).
   - Pin Flutter to it — **`JAVA_HOME` alone is not enough**, since Flutter prefers Android Studio's bundled JDK over `JAVA_HOME`:
     ```
     flutter config --jdk-dir="C:\path\to\jdk-17"
     ```

4. **`compileSdk` must match what's actually installed.** [android/app/build.gradle.kts](android/app/build.gradle.kts) sets `compileSdk = 36`. If you bump this, make sure the matching `platforms;android-XX` package is installed via the SDK manager and that your AGP version (see [android/settings.gradle.kts](android/settings.gradle.kts)) actually supports it — very new API levels are sometimes packaged in a way older AGP versions can't resolve (`Failed to find target with hash string 'android-XX'`).

5. **Connect your phone via USB with USB debugging enabled**, then confirm it's detected:
   ```
   flutter devices
   ```

6. Run it:
   ```
   flutter pub get
   flutter run -d <device-id>
   ```

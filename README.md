# TaskFlow

TaskFlow is a Flutter task management app. This repository contains the initial Flutter platform scaffold and the application foundation.

## Run

```sh
flutter pub get
flutter run
```

## Project setup

The app uses Provider for state management. Core packages for Firebase Authentication, Cloud Firestore, Firebase Messaging, Google Sign-In, REST requests, persisted preferences, localization, and Google Mobile Ads are included in `pubspec.yaml`.

Firebase project `taskflow-eb787` is configured for Android (`com.taskflow.taskflow`), iOS (`com.taskflow.taskflow`), and web. `lib/firebase_options.dart` provides the generated client options, and `android/app/google-services.json` is the Android service configuration. `main.dart` initializes Firebase before starting the app. These client configuration values identify the Firebase apps; they are not server credentials. Keep service account keys and FCM server credentials out of the client project.

Enable Email/Password and Google providers in Firebase Authentication before using sign-in. The default Firestore database already exists in region `eur3`; review and configure its security rules before storing user data. Configure Google Sign-In's platform OAuth details (including Android SHA fingerprints) in Firebase/Google Cloud. Mobile Ads should use Google's official test unit IDs during development only.

The initial shell defines named routes for Home, Tasks, Calendar, and Profile, plus light/dark themes. Feature code can grow into `lib/presentation`, `lib/models`, `lib/providers`, `lib/services`, `lib/repositories`, `lib/routing`, and `lib/l10n` as the requirements are implemented.

The productivity advice API endpoint has not been selected; document its endpoint, response format, and usage limits here when chosen. Push notifications triggered by task actions require a trusted backend or Firebase Cloud Function. Never place FCM server credentials in the client app.

## Platform note

On Windows, Flutter plugins may require Developer Mode or an elevated terminal to create symlinks while resolving/building plugins.

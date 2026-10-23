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

## Implemented

- Email/password registration and sign-in, Google sign-in, password reset, and sign-out.
- A profile document at `users/{uid}` is created on first sign-in and refreshed on later sign-ins.
- Task create, list, edit, complete/reopen, and delete under `users/{uid}/tasks/{taskId}`.
- User-scoped Firestore access is expected by the app; the deployed Firestore rules must allow the signed-in owner to read and write their profile and task subcollection.
- Light/dark theme preference saved locally.

Feature code is organized under `lib/presentation`, `lib/models`, `lib/providers`, `lib/services`, and `lib/repositories`.

The productivity advice API endpoint has not been selected; document its endpoint, response format, and usage limits here when chosen. Push notifications triggered by task actions require a trusted backend or Firebase Cloud Function. Never place FCM server credentials in the client app.

## Platform note

On Windows, Flutter plugins may require Developer Mode or an elevated terminal to create symlinks while resolving/building plugins.

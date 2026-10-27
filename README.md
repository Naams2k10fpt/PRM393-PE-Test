# BookShelf

PRM393 Practical Exam — QE190117 — Phạm Huỳnh Sum

A private Android reading library built with Flutter, Firebase Authentication and Cloud Firestore.

## Run

Built with Flutter 3.47.2 and Dart 3.13.2. Start an Android emulator or connect a USB-debugging device.

~~~powershell
flutter pub get
flutter devices
flutter run -d <android-device-id>
~~~

Firebase client configuration is included for project prm393-pe-71dac and Android package com.prm393.bookshelf. No admin/service-account credentials are included.

To switch Firebase projects, register that package, download its Android client google-services.json, then run:

~~~powershell
.\tool\configure_firebase.ps1 -ConfigPath C:\path\to\google-services.json
~~~

Enable Email/Password, create the default Firestore database and publish firestore.rules. The app initializes Firebase explicitly from lib/firebase_options.dart; the Google Services Gradle plugin is not required.

## Features

- Public Home and protected List/Detail; session restoration and Logout.
- Real Firebase registration/login with the exam's exact validation messages.
- Add, edit, cancel, confirmed delete, optional rating/notes and persistent favorites.
- Realtime updates, alphabetical sorting, combined filters/search and Clear.
- Counts and status breakdown derived from the visible results.
- Server-enforced ownership, validation and canonical IDs for duplicate prevention.
- Shared forms/components, responsive layouts and a custom launcher icon.

## Data and uniqueness

The root collection is books. Fields are id, userId, title, author, genre, status, favorite, notes, createdAt, and optional integer rating. Blank rating is omitted. Add uses a server timestamp; edits preserve it and the latest favorite value.

The document ID joins three lowercase UTF-8 SHA-256 hashes with underscores: uid, trimmed/lowercase title, and trimmed/lowercase author. Rules verify that ID. Add uses a transaction and refuses an existing destination. Renaming title/author moves the document atomically and refuses an occupied destination.

Firestore Rules lower() handles ASCII; the rules additionally normalize Vietnamese and Latin-1 uppercase letters. Tests cover Vietnamese, punctuation and slashes. Own absent canonical paths may be read for transaction destination checks; other users' documents remain protected.

## Manual verification

See [MANUAL_TEST.md](MANUAL_TEST.md) for run instructions, expected results and report screenshots. The grader password is supplied privately, never in this repository.

## Optional automated checks

~~~powershell
flutter analyze
flutter test
npm.cmd --prefix tools ci
.\tools\node_modules\.bin\firebase.cmd emulators:exec --project demo-bookshelf --only firestore "npm.cmd --prefix tools test"
~~~

The rules suite requires Java 21+ and uses a local demo project, leaving the live project untouched.

## Firebase tooling

~~~powershell
npm.cmd --prefix tools ci
.\tools\node_modules\.bin\firebase.cmd login
node tools/setup-firebase.mjs prm393-pe-71dac
.\tools\node_modules\.bin\firebase.cmd deploy --only firestore:rules --project prm393-pe-71dac
~~~

Setup uses the Firebase CLI's existing user login; credentials are not exported into the app.

## Build

~~~powershell
flutter build apk --release
~~~

Output: build/app/outputs/flutter-apk/app-release.apk. Internet permission is included in the main manifest. Release uses the Flutter template's development signing key for direct installation; app-store publishing would require separate signing setup.

Source: https://github.com/Naams2k10fpt/PRM393-PE-Test

APK: https://github.com/Naams2k10fpt/PRM393-PE-Test/releases/download/v1.0.0/app-release.apk

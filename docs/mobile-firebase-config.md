# Mobile Firebase Config Management

This repo keeps generated Firebase client configuration out of Git and materializes it only on developer machines or in CI from environment secrets.

Important policy note:

- Firebase mobile client config is treated as public client-side build input, not as a backend secret.
- Even so, this repo intentionally keeps the generated files out of Git so standard secret scanning and security-enforcement workflows remain deterministic and low-noise.
- Real protection still comes from Firebase Rules, App Check, Android/iOS app identity, backend authorization, and never committing privileged credentials.

Files kept out of source control:

- `apps/mobile_app/android/app/google-services.json`
- `apps/mobile_app/ios/Runner/GoogleService-Info.plist`
- `apps/mobile_app/lib/firebase_options.dart`
- `apps/mobile_app/firebase.json`

## Required Environment Variables

Store these values as base64-encoded file contents:

- `ANDROID_GOOGLE_SERVICES_JSON_B64`
- `IOS_GOOGLE_SERVICE_INFO_PLIST_B64`
- `FIREBASE_OPTIONS_DART_B64`
- `FIREBASE_JSON_B64`

## Local Setup

PowerShell:

```powershell
.\scripts\firebase\write_mobile_firebase_config.ps1
```

macOS / Linux:

```bash
./scripts/firebase/write_mobile_firebase_config.sh
```

Run the script after exporting the required environment variables and before running Flutter commands that require Firebase config.

## GitHub Environments

Recommended environment mapping:

- `develop` branch -> `develop` GitHub environment secrets
- `main` branch -> `main` GitHub environment secrets

CI can materialize the files before Flutter build steps by exporting the same environment variables and calling the shell script above.

## Security Notes

- The generated Firebase client files are intentionally kept out of Git.
- The built mobile or web client will still contain client configuration once compiled.
- Real protection should come from key restrictions, Firebase Rules, App Check, and backend authorization.

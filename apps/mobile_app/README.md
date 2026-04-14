# Mobile App

This folder contains the primary Flutter mobile application for All Solar AMC.

Current state:

- Standard Flutter scaffold created locally
- Intended home for FlutterFlow-exported code and hand-written app code
- Feature work should start from short-lived branches and merge into `develop`
- Firebase client config is materialized locally/CI from environment secrets and is not kept in Git, even though it is public client-side build input

Next recommended setup steps:

- verify the local Flutter toolchain with `flutter doctor`
- open this folder in Android Studio or VS Code as the app root
- define the first mobile vertical slice before layering in FlutterFlow output
- materialize Firebase config using the scripts documented in [`docs/mobile-firebase-config.md`](/C:/code/all-solar-amc-ui/docs/mobile-firebase-config.md)

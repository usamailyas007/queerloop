# QueerLoop+

Flutter package containing two apps: the user app and the admin console.

## Run

```bash
flutter pub get

# user app
flutter run --dart-define-from-file=env/staging.json

# admin console
flutter run -t lib/main_admin.dart --dart-define-from-file=env/staging.json
```

VS Code users: the four launch configs in `.vscode/launch.json` do the same
thing without the flags.

Builds **must** pass `--dart-define-from-file`; without it `BASE_URL` is empty
and the app asserts on startup.

## Release

```bash
flutter build appbundle --release --dart-define-from-file=env/prod.json
flutter build ipa       --release --dart-define-from-file=env/prod.json
```

## Checks

```bash
flutter analyze
flutter test
```

See [ARCHITECTURE.md](ARCHITECTURE.md) for the folder layout and the rules that
keep it that way.

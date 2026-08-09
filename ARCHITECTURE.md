# Architecture

One Flutter package, two apps: the user app (`main.dart`) and the admin console
(`main_admin.dart`). Keep it boring — a 1-2 person team has to maintain it.

## Layout

```
lib/
  main.dart                  user app entry
  main_admin.dart            admin entry

  app/                       user app shell — MaterialApp, providers, auth gate
  admin/                     admin console, self-contained

  core/                      no feature knowledge, ever
    config/app_config.dart   the only file that knows a base URL exists
    api/api_client.dart      the only file that touches Dio
    api/api_exception.dart   the only error type features ever see
    theme/                   colors, spacing, text styles, image paths, ThemeData
    utils/

  features/                  90% of the code lives here
    auth/                    auth_provider · auth_service · user · screens/
    home/                    home_screen

  shared/widgets/            does not exist yet — create it when a widget
                             has 2+ real callers

assets/images/               registered in pubspec; paths go in AppImages
env/                         staging.json, prod.json
.vscode/launch.json          4 run configs, so the env flags are optional
```

## The four rules

1. **Dependencies point one way.** `features/ → core/` and `features/ → shared/`.
   Never the reverse. Never feature → feature (except a feature importing
   `auth` for the current user, which is the one allowed exception).

2. **Three file types per feature, that's the whole vocabulary.**

   | File | Job | May import |
   |---|---|---|
   | `x_service.dart` | HTTP calls, returns models | `ApiClient`, models |
   | `x_provider.dart` | `ChangeNotifier`, holds state | its service, models |
   | `x_screen.dart` / widgets | UI | its provider, theme |

   Chain is always: `Screen → Provider → Service → ApiClient`. Screens never
   call a service. Services never hold state.

   There is no separate "repository" layer. The service does the call *and*
   returns the parsed model. One class per feature.

3. **Features start flat.** Files sit loose in `features/<name>/`. Create a
   subfolder only when that category reaches 3 files — which is why `auth/` has
   `screens/` and `home/` doesn't.

4. **Endpoint paths live in the service that uses them.** No central
   `api_endpoints.dart` — it would make every feature depend on every other
   feature's routes.

## Comments

One comment per file: a single purpose line on line 1. Nothing else. Anything
that needs more explanation than that belongs in this document.

## Environments

`AppConfig` reads compile-time values, so a staging URL cannot ship in a
production binary. Nothing outside `ApiClient` reads `AppConfig.baseUrl`.

```
flutter run                            --dart-define-from-file=env/staging.json
flutter run -t lib/main_admin.dart     --dart-define-from-file=env/staging.json
flutter build apk --release            --dart-define-from-file=env/prod.json
```

Non-prod builds show an env ribbon in the top-right corner.

`USE_MOCK_API` is `true` in staging: services return fake data instead of
calling the network, so the UI can be built before the backend exists. Delete
the flag and its `if` branches once the API is live.

Android flavors / iOS schemes are deliberately **not** set up. Add them only
when staging and prod need to be installed side by side on one device.

## Adding a feature

1. `lib/features/<name>/` — `<name>_service.dart`, `<name>_provider.dart`,
   model file, `<name>_screen.dart`.
2. Register the provider in [lib/app/app.dart](lib/app/app.dart), passing
   `context.read<ApiClient>()` to the service.
3. Add the route in [lib/app/router.dart](lib/app/router.dart).

## Assets

Images go in `assets/images/` and get a constant in
[lib/core/theme/app_images.dart](lib/core/theme/app_images.dart):

```dart
static const String logo = '$dir/logo.png';
```

The folder is registered in `pubspec.yaml`, not individual files, so adding an
image needs no `pubspec` change — only the constant. Never write a raw asset
path in a widget; a typo there fails at runtime, a typo in `AppImages` fails at
compile time.

## Strings

There is deliberately **no `AppStrings`** class. User-facing text goes into ARB
files (`flutter_localizations` + `gen_l10n`); a string constants class is a
halfway house that gets rewritten the day a second language appears.

Currently only `AdminShell` is converted, as a working reference:

```
lib/l10n/app_en.arb            source of truth, holds the @description entries
lib/l10n/app_es.arb            translations, keys only
l10n.yaml                      generator config
lib/l10n/app_localizations*.dart   generated, gitignored
```

Add a key to `app_en.arb`, run `flutter gen-l10n` (or just `flutter pub get`),
then use `AppLocalizations.of(context).myKey`. A missing key in a translation
file falls back to English rather than crashing.

Convert the remaining screens when a second locale is actually planned — until
then inline strings are fine and cost nothing to migrate later.

## Known gaps

- **No token persistence.** `ApiClient.authToken` lives in memory; the session
  is lost on restart. Add `flutter_secure_storage`, then have
  `AuthProvider.restoreSession()` read the saved token and call
  `AuthService.restore(token)` instead of dropping straight to `signedOut`.
- **`AppRouter` is an auth gate, not a router.** Swap in `go_router` when deep
  links are needed (sharing a post, opening a profile from a notification).
- **Admin auth is local-only** — no backend calls yet, deliberately kept
  separate from the user app's `AuthProvider` because the two will diverge.
- **Mock mode is on in staging.** `AuthService` has `AppConfig.useMockApi`
  branches returning fake data. Delete them and the flag once the API is live.

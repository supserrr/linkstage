# Localization (i18n)

The app uses Flutter's built-in localization with ARB files. Supported locales: English (`en`), French (`fr`), Kinyarwanda (`rw`), Kiswahili (`sw`).

## Setup

- **Dependencies**: `flutter_localizations` (sdk) in `pubspec.yaml`.
- **Configuration**: `l10n.yaml` in project root:
  - `arb-dir: lib/l10n`
  - `template-arb-file: app_en.arb`
  - `output-localization-file: app_localizations.dart`
- **Generation**: `flutter gen-l10n` (or `flutter pub get` with `generate: true` in pubspec). Output: `lib/l10n/app_localizations.dart` and `app_localizations_<locale>.dart`.
- **App wiring**: `MaterialApp.router` has:
  - `localizationsDelegates: AppLocalizations.localizationsDelegates`
  - `supportedLocales: AppLocalizations.supportedLocales`
  - `locale: Locale(settings.language)` from `SettingsCubit`

## ARB files

| File | Locale |
|------|--------|
| `lib/l10n/app_en.arb` | English (template) |
| `lib/l10n/app_fr.arb` | French |
| `lib/l10n/app_rw.arb` | Kinyarwanda |
| `lib/l10n/app_sw.arb` | Kiswahili |

Each key maps to a string. Example:

```json
{
  "@@locale": "en",
  "home": "Home",
  "search": "Search"
}
```

## Usage in code

```dart
import 'package:linkstage/l10n/app_localizations.dart';

// In a widget with BuildContext:
final l10n = AppLocalizations.of(context)!;
Text(l10n.home);
```

## Adding new strings

1. Add the key and value to `app_en.arb`.
2. Add translations to `app_fr.arb`, `app_rw.arb`, `app_sw.arb`.
3. Run `flutter gen-l10n` or `flutter pub get`.
4. Use `l10n.yourKey` in the presentation layer.

## Language setting

`SettingsCubit.setLanguage(code)` persists to SharedPreferences and emits a new state. `MaterialApp` rebuilds with `Locale(settings.language)`, so the app switches locale immediately. The language picker is in Settings > Account settings.

# App Icon Setup

The app uses [flutter_launcher_icons](https://pub.dev/packages/flutter_launcher_icons) to generate launcher icons for Android and iOS. Light and dark mode icons are supported on iOS 18+.

## Asset Requirements

Place your icon files in `assets/icon/`:

| File | Size | Purpose |
|------|------|---------|
| `icon.png` | 1024x1024 | Default/light mode (Android + iOS) |
| `icon_dark.png` | 1024x1024 | iOS 18+ dark mode (use transparent background per Apple) |
| `icon_tinted.png` | 1024x1024 | iOS 18+ tinted mode — auto-desaturated to grayscale for wallpaper-matching |

## Platform Support

### iOS 18+

- **Light mode**: Uses `icon.png` (default).
- **Dark mode**: Uses `icon_dark.png` via `image_path_ios_dark_transparent`. Apple recommends a transparent icon for dark mode.
- **Tinted mode**: Uses `icon_tinted.png`, auto-desaturated to grayscale for themed home screens.

### Android

Android does not support different launcher icons for light/dark mode at the OS level. The same `icon.png` is used. Use a design that works well in both themes (e.g. logo with neutral background).

**Adaptive icons (API 26+):** `pubspec.yaml` sets `adaptive_icon_background` to `#E1EEF3` (the border color of `icon.png`) and `adaptive_icon_foreground` to the same asset. That way the launcher does not show a default white circle behind a legacy mipmap. Regenerate after changing the icon so `mipmap-anydpi-v26/` and `drawable-*dpi/ic_launcher_foreground.png` stay in sync.

## Regenerating Icons

```bash
flutter pub get
dart run flutter_launcher_icons
```

## Configuration

The config lives in `pubspec.yaml` under `flutter_launcher_icons`. See the package [documentation](https://pub.dev/packages/flutter_launcher_icons) for adaptive icon options (Android) and additional iOS settings.

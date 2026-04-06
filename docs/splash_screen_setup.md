# Splash Screen Setup

The app uses a custom Lottie splash screen that respects dark and light mode. The splash is rendered inside the main app (go_router) and uses `Theme.of(context).brightness` to choose the appropriate Lottie asset.

## Flow

1. **Native splash** — The OS shows a native splash (configured in `android/app/src/main/res/`) until the Flutter engine is ready.
2. **Flutter splash** — When the app loads, go_router shows the splash route (`/`), which displays `SplashPage` with a Lottie animation. The asset is chosen based on the current theme (light or dark).
3. **Router** — `SplashNotifier` controls when the redirect runs (auth ready + 800ms minimum). Once complete, the user is sent to onboarding, login, or home.

## Lottie Assets

- **Light mode**: `assets/lottie/Link-Stage-Animation-Light-Mode.json`
- **Dark mode**: `assets/lottie/Link-Stage-Animation-Dark-Mode.json`

The splash page selects the asset based on `Theme.of(context).brightness`, which reflects the app's theme mode (system, light, or dark).

## Changing the Splash

To modify the splash behavior or assets:

1. Edit `lib/presentation/pages/splash_page.dart` for layout, background colors, or asset paths.
2. Replace the JSON files in `assets/lottie/` to change the animation.
3. To change the native splash (shown before Flutter loads), edit `android/app/src/main/res/values/colors.xml` and `res/drawable/splash_screen.xml`.

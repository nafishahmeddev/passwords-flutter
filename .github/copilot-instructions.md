# Copilot Instructions for Passwords Flutter App

## Project Overview
- **Passwords** is a secure password manager built with Flutter, using a clean architecture: `presentation` (UI), `business` (logic/providers), and `data` (models/repositories/services).
- The app features biometric authentication, auto-lock, password generation, and a card-based UI for account management.

## Architecture & File Organization
- **UI Layer**: Screens in `lib/presentation/screens/` (e.g., `account_list_screen_card.dart`, `home_screen.dart`). Widgets in `lib/presentation/widgets/`.
- **Business Logic**: Providers and services in `lib/business/`.
- **Data Layer**: Models, repositories, and services in `lib/data/`.
- **Navigation**: Bottom navigation bar with three tabs (Accounts, Generate, Settings). FAB for adding accounts on Accounts tab.

## Developer Workflows
- **Build**: Use `flutter build <platform>` (e.g., `flutter build apk`, `flutter build ios`).
- **Run**: Use `flutter run` for local development.
- **Test**: Run `flutter test` for unit tests. Test files are in `test/` (if present).
- **Dependencies**: Managed in `pubspec.yaml`. Use `flutter pub get` to fetch packages.
- **Debugging**: Use Flutter DevTools or IDE debugging tools. Biometric and secure storage features may require device/emulator.

## Project-Specific Patterns
- **Card-Based UI**: Account lists use cards with dynamic coloring, swipe-to-delete, search, and favorites filtering.
- **State Management**: Uses `provider` package for state management.
- **Secure Storage**: Uses `flutter_secure_storage` and `local_auth` for sensitive data and authentication.
- **Data Access**: Uses `sqflite` for local database, with repositories in `lib/data/`.
- **Password Generation**: Logic in `lib/presentation/screens/password_generator_screen.dart` and related widgets.

## Integration Points
- **External Packages**: See `pubspec.yaml` for all dependencies (e.g., biometric, secure storage, database, file picker, etc.).
- **Platform Support**: Android, iOS, macOS, Linux, Windows, Web (see platform folders).

## Conventions
- **Naming**: Follows Dart/Flutter naming conventions. Screens and widgets are named by function (e.g., `account_list_screen_card.dart`).
- **Organization**: Clean separation of UI, business logic, and data. Avoids duplicate logic and consolidates related files.
- **Security**: Sensitive operations (auth, storage) are handled in business/data layers, not directly in UI.

## Examples
- To add a new account type, create a model in `lib/data/models/`, update repository/service, and add UI in `lib/presentation/screens/`.
- To add a new feature, follow the clean architecture: UI → Provider → Repository/Service → Model.

---

If any section is unclear or missing, please provide feedback to improve these instructions.
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'data/services/db_helper.dart';
import 'data/repositories/account_repository.dart';
import 'business/providers/account_provider.dart';
import 'presentation/screens/account_list_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final db = await DBHelper.init();
  final repository = AccountRepository(db);

  runApp(MainApp(repository: repository));
}

class MainApp extends StatelessWidget {
  final AccountRepository repository;

  const MainApp({super.key, required this.repository});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AccountProvider(repository: repository)..loadAccounts(),
      child: DynamicColorBuilder(
        builder: (ColorScheme? lightDynamic, ColorScheme? darkDynamic) {
          // Create custom color schemes with better contrast and harmony
          final lightColorScheme =
              (lightDynamic ??
                      ColorScheme.fromSeed(
                        seedColor: Colors.green,
                        brightness: Brightness.light,
                      ))
                  .copyWith(
                    // Enhance surface colors for better hierarchy and visibility
                    surface: Color(0xFFFEFEFE),
                    surfaceContainerLowest: Color(
                      0xFFE8F0F8,
                    ), // Lighter blue-tinted background for cards
                    surfaceContainerLow: Color(0xFFF1F3F4),
                    surfaceContainer: Color(0xFFECEEF0),
                    surfaceContainerHigh: Color(0xFFE8EAED),
                    surfaceContainerHighest: Color(0xFFE0E2E6),
                    // Better outline colors
                    outline: Color(0xFF5F6368),
                    outlineVariant: Color(0xFF9AA0A6),
                  );

          final darkColorScheme =
              (darkDynamic ??
                      ColorScheme.fromSeed(
                        seedColor: Colors.green,
                        brightness: Brightness.dark,
                      ))
                  .copyWith(
                    // Enhance surface colors for dark theme
                    surface: Color(0xFF0F1419),
                    surfaceContainerLowest: Color(0xFF1C1F23),
                    surfaceContainerLow: Color(0xFF25282D),
                    surfaceContainer: Color(0xFF2D3035),
                    surfaceContainerHigh: Color(0xFF35383D),
                    surfaceContainerHighest: Color(0xFF3E4147),
                    // Better outline colors for dark
                    outline: Color(0xFF9AA0A6),
                    outlineVariant: Color(0xFF5F6368),
                  );

          return MaterialApp(
            title: 'Passwords',
            theme: ThemeData(
              useMaterial3: true,
              colorScheme: lightColorScheme,
              brightness: Brightness.light,
              // Enhanced typography
              textTheme: TextTheme(
                headlineLarge: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.5,
                ),
                headlineMedium: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.25,
                ),
                headlineSmall: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0,
                ),
                titleLarge: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0,
                ),
                titleMedium: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.15,
                ),
                titleSmall: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.1,
                ),
                bodyLarge: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                  letterSpacing: 0.5,
                ),
                bodyMedium: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  letterSpacing: 0.25,
                ),
                bodySmall: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                  letterSpacing: 0.4,
                ),
              ),
              // Enhanced component themes
              cardTheme: CardThemeData(
                elevation: 0,
                color: lightColorScheme.surfaceContainer,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(16)),
                ),
              ),
              appBarTheme: AppBarTheme(
                elevation: 0,
                backgroundColor: lightColorScheme.surface,
                foregroundColor: lightColorScheme.onSurface,
                surfaceTintColor: Colors.transparent,
                titleTextStyle: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: lightColorScheme.onSurface,
                ),
              ),
              filledButtonTheme: FilledButtonThemeData(
                style: FilledButton.styleFrom(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            darkTheme: ThemeData(
              useMaterial3: true,
              colorScheme: darkColorScheme,
              brightness: Brightness.dark,
              // Same typography for dark theme
              textTheme: TextTheme(
                headlineLarge: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.5,
                ),
                headlineMedium: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.25,
                ),
                headlineSmall: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0,
                ),
                titleLarge: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0,
                ),
                titleMedium: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.15,
                ),
                titleSmall: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.1,
                ),
                bodyLarge: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                  letterSpacing: 0.5,
                ),
                bodyMedium: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  letterSpacing: 0.25,
                ),
                bodySmall: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                  letterSpacing: 0.4,
                ),
              ),
              // Enhanced component themes for dark
              cardTheme: CardThemeData(
                elevation: 0,
                color: darkColorScheme.surfaceContainerLowest,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(16)),
                ),
              ),
              appBarTheme: AppBarTheme(
                elevation: 0,
                backgroundColor: darkColorScheme.surface,
                foregroundColor: darkColorScheme.onSurface,
                surfaceTintColor: Colors.transparent,
                titleTextStyle: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: darkColorScheme.onSurface,
                ),
              ),
              filledButtonTheme: FilledButtonThemeData(
                style: FilledButton.styleFrom(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            home: AccountListScreen(),
          );
        },
      ),
    );
  }
}

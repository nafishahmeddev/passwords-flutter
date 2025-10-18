import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'data/services/db_helper.dart';
import 'data/repositories/account_repository.dart';
import 'business/providers/account_provider.dart';
import 'business/providers/settings_provider.dart';
import 'business/services/favicon_service.dart';
import 'presentation/screens/home_screen.dart';
import 'presentation/screens/lock_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final db = await DBHelper.init();
  final repository = AccountRepository(db);

  final settingsProvider = SettingsProvider();

  // Initialize favicon cache and clear expired entries on startup
  FaviconService.clearExpiredCache().catchError((e) {
    debugPrint('Error clearing expired favicon cache on startup: $e');
  });

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => settingsProvider),
        ChangeNotifierProvider(
          create: (_) =>
              AccountProvider(repository: repository)..loadAccounts(),
        ),
      ],
      child: MainApp(repository: repository),
    ),
  );
}

class MainApp extends StatelessWidget {
  final AccountRepository repository;

  const MainApp({super.key, required this.repository});

  @override
  Widget build(BuildContext context) {
    final settingsProvider = Provider.of<SettingsProvider>(context);

    return DynamicColorBuilder(
      builder: (ColorScheme? lightDynamic, ColorScheme? darkDynamic) {
        // Use dynamic colors only if enabled in settings
        final useDynamicColor = settingsProvider.useDynamicColor;

        // Create custom color schemes with better contrast and harmony
        final lightColorScheme = ColorScheme.fromSeed(
          seedColor: useDynamicColor && lightDynamic != null
              ? lightDynamic.primary
              : Colors.green,
          brightness: Brightness.light,
        );

        final darkColorScheme = ColorScheme.fromSeed(
          seedColor: useDynamicColor && lightDynamic != null
              ? lightDynamic.primary
              : Colors.green,
          brightness: Brightness.dark,
        );

        TextTheme textTheme = GoogleFonts.sourceSans3TextTheme(
          TextTheme(
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
        );
        // Capture pointer events globally to reset auto-lock activity timer
        return Listener(
          onPointerDown: (_) => settingsProvider.recordUserActivity(),
          child: MaterialApp(
            title: 'Passwords',
            themeMode: settingsProvider.themeMode,
            theme: ThemeData(
              useMaterial3: true,
              colorScheme: lightColorScheme,
              brightness: Brightness.light,
              // Enhanced typography
              textTheme: textTheme,
              // Enhanced component themes
              cardTheme: CardThemeData(
                elevation: 0,
                color: lightColorScheme.surfaceContainerLowest,
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
                  fontFamily: textTheme.headlineMedium?.fontFamily,
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
              textTheme: textTheme,
              // Enhanced component themes for dark
              cardTheme: CardThemeData(
                elevation: 0,
                color: darkColorScheme.surfaceContainer,
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
                  fontFamily: textTheme.headlineMedium?.fontFamily,
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
            home: Consumer<SettingsProvider>(
              builder: (context, settingsProvider, child) {
                // Based on auth status, show either lock screen or home screen
                switch (settingsProvider.authStatus) {
                  case AuthStatus.authenticated:
                    return HomeScreen();
                  case AuthStatus.unauthenticated:
                    return LockScreen();
                  case AuthStatus.initial:
                    // While checking auth status, show a splash screen
                    return Scaffold(
                      body: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                color: lightColorScheme.primaryContainer,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Icon(
                                Icons.lock_outline_rounded,
                                size: 40,
                                color: lightColorScheme.onPrimaryContainer,
                              ),
                            ),
                            SizedBox(height: 24),
                            Text('Passwords', style: textTheme.headlineLarge),
                            SizedBox(height: 16),
                            CircularProgressIndicator(),
                          ],
                        ),
                      ),
                    );
                  case AuthStatus.error:
                    // Show error message
                    return Scaffold(
                      body: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.error_outline,
                              size: 64,
                              color: lightColorScheme.error,
                            ),
                            SizedBox(height: 16),
                            Text(
                              'Authentication Error',
                              style: textTheme.titleLarge,
                            ),
                            SizedBox(height: 8),
                            Text(
                              settingsProvider.errorMessage ?? 'Unknown error',
                              textAlign: TextAlign.center,
                              style: textTheme.bodyMedium?.copyWith(
                                color: lightColorScheme.onSurfaceVariant,
                              ),
                            ),
                            SizedBox(height: 24),
                            ElevatedButton(
                              onPressed: () {
                                settingsProvider.checkAuthStatus();
                              },
                              child: Text('Retry'),
                            ),
                          ],
                        ),
                      ),
                    );
                }
              },
            ),
          ),
        );
      },
    );
  }
}

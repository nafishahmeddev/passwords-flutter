import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'data/services/db_helper.dart';
import 'data/repositories/account_repository.dart';
import 'business/providers/account_provider.dart';
import 'business/providers/auth_provider.dart';
import 'presentation/screens/account_list_screen.dart';
import 'presentation/screens/lock_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final db = await DBHelper.init();
  final repository = AccountRepository(db);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
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
    return DynamicColorBuilder(
      builder: (ColorScheme? lightDynamic, ColorScheme? darkDynamic) {
        print("lightDynamic: $lightDynamic, darkDynamic: $darkDynamic");
        // Create custom color schemes with better contrast and harmony
        final lightColorScheme = ColorScheme.fromSeed(
          seedColor: lightDynamic?.primary ?? Colors.green,
          brightness: Brightness.light,
        );
        final darkColorScheme = ColorScheme.fromSeed(
          seedColor: darkDynamic?.primary ?? Colors.green,
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
        return MaterialApp(
          title: 'Passwords',
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
          home: Consumer<AuthProvider>(
            builder: (context, authProvider, child) {
              // Based on auth status, show either lock screen or home screen
              switch (authProvider.status) {
                case AuthStatus.authenticated:
                  return AccountListScreen();
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
                            authProvider.errorMessage ?? 'Unknown error',
                            textAlign: TextAlign.center,
                            style: textTheme.bodyMedium?.copyWith(
                              color: lightColorScheme.onSurfaceVariant,
                            ),
                          ),
                          SizedBox(height: 24),
                          ElevatedButton(
                            onPressed: () {
                              authProvider.checkAuthStatus();
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
        );
      },
    );
  }
}

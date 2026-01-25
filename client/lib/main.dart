import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:libraryapp/auth/pages/login_page.dart';
import 'package:libraryapp/auth/providers/asgardeo_direct_provider.dart';
import 'package:libraryapp/core/providers/theme_provider.dart';
import 'package:libraryapp/core/theme/app_pallete.dart';
import 'package:libraryapp/core/widgets/BottomNavigator/bottom_bar.dart';

void main() {
  runApp(ProviderScope(child: const MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = ref.watch(isDarkProvider);
    final authState = ref.watch(asgardeoDirectAuthProvider);

    return MaterialApp(
      themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
      title: 'XYZ Library',
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Pallete.primaryColor,
        scaffoldBackgroundColor: Pallete.scaffoldBackground,
      ),

      // 🌙 Dark theme (Material 3)
      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorSchemeSeed: Pallete.primaryColor,
      ),
      // Show login page if not logged in, otherwise show home
      home: authState.isLoggedIn ? const BottomNav() : const Login(),
    );
  }
}

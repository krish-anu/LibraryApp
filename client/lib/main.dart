import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
    return MaterialApp(
      themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
      title: 'Flutter Demo',
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
      home: BottomNav(),
    );
  }
}

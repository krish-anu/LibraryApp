import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:libraryapp/core/services/notification_service.dart';
import 'package:libraryapp/auth/pages/login_page.dart';
import 'package:libraryapp/auth/providers/asgardeo_direct_provider.dart';
import 'package:libraryapp/core/providers/theme_provider.dart';
import 'package:libraryapp/core/theme/app_pallete.dart';
import 'package:libraryapp/core/utils/book_share_link.dart';
import 'package:libraryapp/core/widgets/BottomNavigator/nav_keys.dart';
import 'package:libraryapp/core/widgets/BottomNavigator/bottom_bar.dart';
import 'package:libraryapp/core/widgets/book_view.dart';
import 'package:libraryapp/models/book.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService.instance.ensureInitialized();
  runApp(ProviderScope(child: const MyApp()));
}

class MyApp extends ConsumerStatefulWidget {
  const MyApp({super.key});

  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> {
  late final AppLinks _appLinks;
  StreamSubscription<Uri>? _linkSubscription;
  String? _lastHandledLink;

  @override
  void initState() {
    super.initState();
    _appLinks = AppLinks();
    unawaited(_listenForIncomingLinks());
  }

  Future<void> _listenForIncomingLinks() async {
    try {
      final initialUri = await _appLinks.getInitialLink();
      _handleIncomingUri(initialUri);
    } catch (_) {}

    _linkSubscription = _appLinks.uriLinkStream.listen(
      _handleIncomingUri,
      onError: (_) {},
    );
  }

  void _handleIncomingUri(Uri? uri) {
    if (uri == null) return;

    final link = uri.toString();
    if (_lastHandledLink == link) return;

    final book = BookShareLink.parse(uri);
    if (book == null) return;

    _lastHandledLink = link;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _openSharedBook(book);
    });
  }

  void _openSharedBook(Book book) {
    final navigator = rootNavigatorKey.currentState;
    if (navigator == null) {
      Future.delayed(const Duration(milliseconds: 300), () {
        if (!mounted) return;
        _openSharedBook(book);
      });
      return;
    }

    navigator.push(
      MaterialPageRoute(builder: (context) => BookView(book: book)),
    );
  }

  @override
  void dispose() {
    _linkSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ref.watch(isDarkProvider);
    final authState = ref.watch(asgardeoDirectAuthProvider);

    return MaterialApp(
      navigatorKey: rootNavigatorKey,
      themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
      title: 'XYZ Library',
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        colorSchemeSeed: Pallete.primaryColor,
        scaffoldBackgroundColor: Pallete.scaffoldBackground,
        appBarTheme: const AppBarTheme(
          backgroundColor: Pallete.appBarBackground,
          foregroundColor: Pallete.textPrimary,
          elevation: 0,
        ),
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

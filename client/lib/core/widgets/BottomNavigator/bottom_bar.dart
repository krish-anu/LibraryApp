import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:libraryapp/core/widgets/BottomNavigator/bottom_nav_provider.dart';
import 'package:libraryapp/home/pages/borrowed.dart';
import 'package:libraryapp/home/pages/home.dart';
import 'package:libraryapp/home/pages/profile.dart';
import 'package:libraryapp/home/pages/search.dart';
import 'package:libraryapp/home/pages/wishlist.dart';

class BottomNav extends ConsumerWidget {
  const BottomNav({super.key});

  static final _tabNavigatorKeys = List.generate(
    5,
    (_) => GlobalKey<NavigatorState>(),
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final index = ref.watch(bottomNavIndexProvider);
    return PopScope(
      child: Scaffold(
        body: IndexedStack(
          index: index,
          children: [
            _TabNavigator(
              navigatorKey: _tabNavigatorKeys[0],
              child: const Home(),
            ),
            _TabNavigator(
              navigatorKey: _tabNavigatorKeys[1],
              child: const Search(),
            ),
            _TabNavigator(
              navigatorKey: _tabNavigatorKeys[2],
              child: const Borrowed(),
            ),
            _TabNavigator(
              navigatorKey: _tabNavigatorKeys[3],
              child: const Wishlist(),
            ),
            _TabNavigator(
              navigatorKey: _tabNavigatorKeys[4],
              child: const Profile(),
            ),
          ],
        ),
        bottomNavigationBar: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          currentIndex: index,
          onTap: (idx) {
            ref.read(bottomNavIndexProvider.notifier).state = idx;
          },
          items: const <BottomNavigationBarItem>[
            BottomNavigationBarItem(
              icon: Icon(Icons.home, color: Colors.black),
              label: "Home",
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.search, color: Colors.black),
              label: "Search",
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.menu_book, color: Colors.black),
              label: "Borrowed",
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.favorite_border, color: Colors.black),
              label: "WishList",
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person, color: Colors.black),
              label: "Profile",
            ),
          ],
        ),
      ),
    );
  }
}

class _TabNavigator extends StatelessWidget {
  final GlobalKey<NavigatorState> navigatorKey;
  final Widget child;

  const _TabNavigator({required this.navigatorKey, required this.child});

  @override
  Widget build(BuildContext context) {
    return Navigator(
      key: navigatorKey,
      onGenerateRoute: (_) => MaterialPageRoute(builder: (_) => child),
    );
  }
}

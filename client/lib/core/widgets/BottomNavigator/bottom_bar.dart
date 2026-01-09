import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:libraryapp/core/theme/app_pallete.dart';
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
          backgroundColor: Pallete.cardBackground,
          selectedItemColor: Pallete.primaryLight,
          unselectedItemColor: Pallete.textSecondary,
          showUnselectedLabels: true,
          currentIndex: index,
          onTap: (idx) {
            ref.read(bottomNavIndexProvider.notifier).state = idx;
          },
          items: <BottomNavigationBarItem>[
            const BottomNavigationBarItem(
              icon: Icon(Icons.home),
              label: "Home",
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.search),
              label: "Search",
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.menu_book),
              label: "Borrowed",
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.favorite_border),
              label: "WishList",
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.person),
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
      pages: [MaterialPage(child: child)],
      // ignore: deprecated_member_use
      onPopPage: (route, result) {
        if (!route.didPop(result)) return false;
        return true;
      },
    );
  }
}

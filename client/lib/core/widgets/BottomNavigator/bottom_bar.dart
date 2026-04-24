import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:libraryapp/auth/providers/asgardeo_direct_provider.dart';
import 'package:libraryapp/core/providers/current_user_notifier.dart';
import 'package:libraryapp/core/providers/favorites_notifier.dart';
import 'package:libraryapp/core/providers/loans_notifier.dart';
import 'package:libraryapp/core/theme/app_pallete.dart';
import 'package:libraryapp/core/widgets/BottomNavigator/bottom_nav_provider.dart';
import 'package:libraryapp/features/notifications/viewmodels/notifications_controller.dart';
import 'package:libraryapp/features/home/views/home_view.dart';
import 'package:libraryapp/features/search/views/search_view.dart';
import 'package:libraryapp/features/borrowed/views/borrowed_view.dart';
import 'package:libraryapp/features/wishlist/views/wishlist_view.dart';
import 'package:libraryapp/features/profile/views/profile_view.dart';

class BottomNav extends ConsumerStatefulWidget {
  const BottomNav({super.key});

  static final _tabNavigatorKeys = List.generate(
    5,
    (_) => GlobalKey<NavigatorState>(),
  );

  @override
  ConsumerState<BottomNav> createState() => _BottomNavState();
}

class _BottomNavState extends ConsumerState<BottomNav> {
  final Set<int> _visitedTabs = {0};

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(asgardeoDirectAuthProvider);
    final currentUser = ref.watch(currentUserProvider);
    final memberId = (authState.user?.sub ?? currentUser?.id ?? '').trim();
    Future.microtask(() {
      ref.read(loansProvider.notifier).setMemberId(memberId);
      ref.read(favoritesProvider.notifier).setMemberId(memberId);
      ref.read(notificationsControllerProvider.notifier).setMemberId(memberId);
    });

    final index = ref.watch(bottomNavIndexProvider);
    _visitedTabs.add(index);
    return PopScope(
      child: Scaffold(
        body: IndexedStack(
          index: index,
          children: [
            _LazyTabNavigator(
              isLoaded: _visitedTabs.contains(0),
              navigatorKey: BottomNav._tabNavigatorKeys[0],
              child: const HomeView(),
            ),
            _LazyTabNavigator(
              isLoaded: _visitedTabs.contains(1),
              navigatorKey: BottomNav._tabNavigatorKeys[1],
              child: const SearchView(),
            ),
            _LazyTabNavigator(
              isLoaded: _visitedTabs.contains(2),
              navigatorKey: BottomNav._tabNavigatorKeys[2],
              child: const BorrowedView(),
            ),
            _LazyTabNavigator(
              isLoaded: _visitedTabs.contains(3),
              navigatorKey: BottomNav._tabNavigatorKeys[3],
              child: const WishlistView(),
            ),
            _LazyTabNavigator(
              isLoaded: _visitedTabs.contains(4),
              navigatorKey: BottomNav._tabNavigatorKeys[4],
              child: const ProfileView(),
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
            setState(() {
              _visitedTabs.add(idx);
            });
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

class _LazyTabNavigator extends StatelessWidget {
  final bool isLoaded;
  final GlobalKey<NavigatorState> navigatorKey;
  final Widget child;

  const _LazyTabNavigator({
    required this.isLoaded,
    required this.navigatorKey,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    if (!isLoaded) {
      return const SizedBox.shrink();
    }

    return _TabNavigator(navigatorKey: navigatorKey, child: child);
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

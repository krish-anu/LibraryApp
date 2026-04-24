import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:libraryapp/core/theme/app_pallete.dart';
import 'package:libraryapp/core/widgets/book_section.dart';
import 'package:libraryapp/features/home/viewmodels/home_viewmodel.dart';
import 'package:libraryapp/features/home/widgets/home_header.dart';
import 'package:libraryapp/features/home/widgets/home_search_bar.dart';
import 'package:libraryapp/features/home/widgets/categories_section.dart';
import 'package:libraryapp/features/notifications/viewmodels/notifications_controller.dart';
import 'package:libraryapp/features/notifications/views/notifications_view.dart';
import 'package:libraryapp/features/search/views/search_view.dart';

/// Home page displaying book sections and categories.
class HomeView extends ConsumerWidget {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final homeState = ref.watch(homeViewModelProvider);

    return Scaffold(
      backgroundColor: Pallete.scaffoldBackground,
      body: SafeArea(
        child: homeState.isLoading
            ? _buildLoading()
            : homeState.error != null
            ? _buildError(homeState.error!, ref)
            : _buildContent(context, ref, homeState),
      ),
    );
  }

  Widget _buildContent(BuildContext context, WidgetRef ref, HomeState state) {
    final notificationsState = ref.watch(notificationsControllerProvider);
    return RefreshIndicator(
      onRefresh: () => ref.read(homeViewModelProvider.notifier).refresh(),
      color: Pallete.primaryLight,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              HomeHeader(
                unreadCount: notificationsState.unreadCount,
                onNotificationTap: () => _navigateToNotifications(context),
              ),
              const SizedBox(height: 20),
              HomeSearchBar(onTap: () => _navigateToSearch(context)),
              const SizedBox(height: 24),
              BookSection(booksDetail: state.books, heading: 'Trending Books'),
              const SizedBox(height: 24),
              CategoriesSection(
                categories: state.categories,
                onCategoryTap: (name) =>
                    _navigateToSearch(context, category: name),
              ),
              const SizedBox(height: 24),
              BookSection(
                booksDetail: state.recommendedBooks,
                heading: 'Recommended for You',
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoading() {
    return const Center(
      child: CircularProgressIndicator(color: Pallete.primaryLight),
    );
  }

  Widget _buildError(String message, WidgetRef ref) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, color: Pallete.textSecondary, size: 64),
          const SizedBox(height: 16),
          Text(
            message,
            style: const TextStyle(color: Pallete.textPrimary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => ref.read(homeViewModelProvider.notifier).refresh(),
            style: ElevatedButton.styleFrom(
              backgroundColor: Pallete.primaryLight,
            ),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  void _navigateToSearch(BuildContext context, {String? category}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SearchView(currentCategory: category),
      ),
    );
  }

  void _navigateToNotifications(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const NotificationsView()),
    );
  }
}

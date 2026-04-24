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
            : homeState.booksError != null
            ? _buildError(homeState.booksError!, ref)
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
              BookSection(
                booksDetail: state.trendingBooks,
                heading: 'Trending Books',
              ),
              const SizedBox(height: 24),
              _buildCategoriesContent(context, ref, state),
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

  Widget _buildCategoriesContent(
    BuildContext context,
    WidgetRef ref,
    HomeState state,
  ) {
    if (state.isCategoriesLoading) {
      return _buildCategoriesStatus(
        child: const SizedBox(
          height: 72,
          child: Center(
            child: CircularProgressIndicator(color: Pallete.primaryLight),
          ),
        ),
      );
    }

    if (state.categoriesError != null) {
      return _buildCategoriesStatus(
        child: Column(
          children: [
            Text(
              'Categories are taking longer than expected.',
              style: TextStyle(color: Pallete.textSecondary, fontSize: 14),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () =>
                  ref.read(homeViewModelProvider.notifier).refreshCategories(),
              child: const Text('Retry Categories'),
            ),
          ],
        ),
      );
    }

    if (state.categories.isEmpty) {
      return _buildCategoriesStatus(
        child: Text(
          'No categories available right now.',
          style: TextStyle(color: Pallete.textSecondary, fontSize: 14),
        ),
      );
    }

    return CategoriesSection(
      categories: state.categories,
      onCategoryTap: (name) => _navigateToSearch(context, category: name),
    );
  }

  Widget _buildCategoriesStatus({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Pallete.cardBackground,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Explore Categories',
            style: TextStyle(
              color: Pallete.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Center(child: child),
        ],
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

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:libraryapp/core/theme/app_pallete.dart';
import 'package:libraryapp/core/widgets/book_section.dart';
import 'package:libraryapp/data/repository/book_repository.dart';
import 'package:libraryapp/data/repository/category_repository.dart';
import 'package:libraryapp/home/pages/search.dart';
import 'package:libraryapp/home/widgets/home/home_header.dart';
import 'package:libraryapp/home/widgets/home/home_search_bar.dart';
import 'package:libraryapp/home/widgets/home/categories_section.dart';
import 'package:libraryapp/models/book.dart';
import 'package:libraryapp/models/category.dart';

/// Home page displaying book sections and categories.
class Home extends ConsumerWidget {
  const Home({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final booksAsync = ref.watch(fetchAllBooksProvider);
    final categoriesAsync = ref.watch(fetchCategoriesProvider);

    return Scaffold(
      backgroundColor: Pallete.scaffoldBackground,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),
                const HomeHeader(),
                const SizedBox(height: 20),
                HomeSearchBar(
                  onTap: () => _navigateToSearch(context),
                ),
                const SizedBox(height: 24),
                _buildContent(booksAsync, categoriesAsync, context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(
    AsyncValue<List<Book>> booksAsync,
    AsyncValue<List<Category>> categoriesAsync,
    BuildContext context,
  ) {
    return booksAsync.when(
      data: (books) => categoriesAsync.when(
        data: (categories) => _buildMainContent(books, categories, context),
        loading: () => _buildLoading(),
        error: (err, _) => _buildError(err.toString()),
      ),
      loading: () => _buildLoading(),
      error: (err, _) => _buildError(err.toString()),
    );
  }

  Widget _buildMainContent(
    List<Book> books,
    List<Category> categories,
    BuildContext context,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        BookSection(booksDetail: books, heading: 'Trending Books'),
        const SizedBox(height: 24),
        CategoriesSection(
          categories: categories,
          onCategoryTap: (name) => _navigateToSearch(context, category: name),
        ),
        const SizedBox(height: 24),
        BookSection(
          booksDetail: books.reversed.toList(),
          heading: 'Recommended for You',
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildLoading() {
    return const Center(
      child: CircularProgressIndicator(color: Pallete.primaryLight),
    );
  }

  Widget _buildError(String message) {
    return Center(
      child: Text(message, style: const TextStyle(color: Colors.white)),
    );
  }

  void _navigateToSearch(BuildContext context, {String? category}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Search(currentCategory: category),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:libraryapp/core/theme/app_pallete.dart';
import 'package:libraryapp/core/widgets/book_section.dart';
import 'package:libraryapp/data/repository/book_repository.dart';
import 'package:libraryapp/data/repository/category_repository.dart';
import 'package:libraryapp/home/pages/search.dart';
import 'package:libraryapp/models/category.dart';
import 'package:libraryapp/core/utils/image_helper.dart';

class Home extends ConsumerStatefulWidget {
  const Home({super.key});

  @override
  ConsumerState<Home> createState() => _HomeState();
}

class _HomeState extends ConsumerState<Home> {
  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
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
                _buildHeader(),
                const SizedBox(height: 20),
                _buildSearchBar(context),
                const SizedBox(height: 24),

                booksAsync.when(
                  data: (books) {
                    return categoriesAsync.when(
                      data: (categories) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            BookSection(
                              booksDetail: books,
                              heading: 'Trending Books',
                            ),
                            const SizedBox(height: 24),

                            _buildCategoriesSection(categories),

                            const SizedBox(height: 24),
                            BookSection(
                              booksDetail: books.reversed.toList(),
                              heading: 'Recommended for You',
                            ),
                            const SizedBox(height: 20),
                          ],
                        );
                      },
                      loading: () => const Center(
                        child: CircularProgressIndicator(
                          color: Pallete.primaryLight,
                        ),
                      ),
                      error: (err, stack) => Center(
                        child: Text(
                          err.toString(),
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                    );
                  },
                  error: (err, stack) => Center(
                    child: Text(
                      err.toString(),
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                  loading: () => const Center(
                    child: CircularProgressIndicator(
                      color: Pallete.primaryLight,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${_getGreeting()}, Reader',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Ready to dive into a new world?',
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 14,
              ),
            ),
          ],
        ),
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Pallete.cardBackground,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            Icons.notifications_outlined,
            color: Colors.white,
            size: 24,
          ),
        ),
      ],
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const Search()),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Pallete.searchBarBackground,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(Icons.search, color: Pallete.searchBarHint, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Search title, author, ISBN...',
                style: TextStyle(color: Pallete.searchBarHint, fontSize: 15),
              ),
            ),
            Icon(Icons.tune, color: Pallete.searchBarHint, size: 22),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoriesSection(List<Category> categories) {
    final categoryData = {
      'Sci-Fi': {
        'icon': Icons.rocket_launch_outlined,
        'color': const Color(0xFF2D5A45),
      },
      'History': {
        'icon': Icons.account_balance_outlined,
        'color': const Color(0xFF2D5A45),
      },
      'Fiction': {
        'icon': Icons.auto_stories_outlined,
        'color': const Color(0xFF2D5A45),
      },
      'Mystery': {
        'icon': Icons.psychology_outlined,
        'color': const Color(0xFF2D5A45),
      },
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 0),
          child: Text(
            'Explore Categories',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 16),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 2.8,
          children: categories.map((category) {
            final data =
                categoryData[category.name] ??
                {'icon': Icons.book_outlined, 'color': const Color(0xFF2D5A45)};
            return GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => Search(currentCategory: category.name),
                  ),
                );
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: Pallete.categoryChipBackground,
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Row(
                  children: [
                    SizedBox(
                      width: 36,
                      height: 36,
                      child: category.image != null && category.image!.isNotEmpty
                          ? ClipOval(
                              child: Image(
                                image: imageProviderFromPath(category.image),
                                fit: BoxFit.cover,
                                width: 36,
                                height: 36,
                              ),
                            )
                          : Container(
                              decoration: BoxDecoration(
                                color: data['color'] as Color,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                data['icon'] as IconData,
                                color: Colors.white,
                                size: 18,
                              ),
                            ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        category.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

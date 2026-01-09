import 'package:flutter/material.dart';
import 'package:libraryapp/core/theme/app_pallete.dart';
import 'package:libraryapp/home/widgets/search/genre_card.dart';

/// A grid displaying top genres with book counts.
class GenreGrid extends StatelessWidget {
  final List<Map<String, dynamic>> genres;
  final ValueChanged<String> onGenreSelected;

  const GenreGrid({
    super.key,
    required this.genres,
    required this.onGenreSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [_buildHeader(), const SizedBox(height: 16), _buildGrid()],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          "Top Genres",
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        TextButton(
          onPressed: () {},
          child: const Text(
            "View All",
            style: TextStyle(color: Pallete.primaryLight),
          ),
        ),
      ],
    );
  }

  Widget _buildGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: genres.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: 1.1,
      ),
      itemBuilder: (context, index) {
        final genre = genres[index];
        return GenreCard(
          name: genre['name'],
          count: genre['count'],
          imageUrl: genre['image'],
          onTap: () => onGenreSelected(genre['name']),
        );
      },
    );
  }
}

import 'package:flutter/material.dart';
import 'package:libraryapp/core/theme/app_pallete.dart';

class ReviewCard extends StatelessWidget {
  final String name;
  final int rating;
  final String review;
  final String timeAgo;

  const ReviewCard({
    super.key,
    required this.name,
    required this.rating,
    required this.review,
    required this.timeAgo,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 200,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Pallete.scaffoldBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Pallete.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ReviewHeader(name: name, rating: rating),
          const SizedBox(height: 8),
          Expanded(
            child: Text(
              review,
              style: TextStyle(
                color: Pallete.textSecondary,
                fontSize: 11,
                height: 1.4,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            timeAgo,
            style: TextStyle(
              color: Pallete.textSecondary.withValues(alpha: 0.6),
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}

class _ReviewHeader extends StatelessWidget {
  final String name;
  final int rating;

  const _ReviewHeader({required this.name, required this.rating});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        CircleAvatar(
          radius: 14,
          backgroundColor: Pallete.primaryLight,
          child: Text(
            name[0],
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            name,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        _StarRating(rating: rating),
      ],
    );
  }
}

class _StarRating extends StatelessWidget {
  final int rating;

  const _StarRating({required this.rating});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(
        5,
        (i) => Icon(
          Icons.star,
          size: 12,
          color: i < rating ? Colors.amber : Pallete.textSecondary,
        ),
      ),
    );
  }
}

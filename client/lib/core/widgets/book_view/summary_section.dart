import 'package:flutter/material.dart';
import 'package:libraryapp/core/theme/app_pallete.dart';
// import 'package:libraryapp/core/widgets/book_view/review_card.dart';

class SummarySection extends StatelessWidget {
  final String description;
  final bool isAvailable;
  final VoidCallback onBorrowPressed;

  const SummarySection({
    super.key,
    required this.description,
    required this.isAvailable,
    required this.onBorrowPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Pallete.cardBackground,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Summary',
            style: TextStyle(
              color: Pallete.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            description,
            style: TextStyle(
              color: Pallete.textSecondary,
              fontSize: 14,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 24),
          _BorrowButton(isAvailable: isAvailable, onPressed: onBorrowPressed),
          const SizedBox(height: 24),
          // const _ReviewsSection(),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

class _BorrowButton extends StatelessWidget {
  final bool isAvailable;
  final VoidCallback onPressed;

  const _BorrowButton({required this.isAvailable, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: const Icon(Icons.lock_open, color: Colors.black),
        label: Text(
          isAvailable ? 'Borrow Now' : 'Reserve',
          style: const TextStyle(
            color: Colors.black,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Pallete.primaryLight,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}

// class _ReviewsSection extends StatelessWidget {
//   const _ReviewsSection();

//   @override
//   Widget build(BuildContext context) {
//     return Column(
//       children: [
//         Row(
//           mainAxisAlignment: MainAxisAlignment.spaceBetween,
//           children: [
//             const Text(
//               'Reviews',
//               style: TextStyle(
//                 color: Colors.white,
//                 fontSize: 18,
//                 fontWeight: FontWeight.bold,
//               ),
//             ),
//             TextButton(
//               onPressed: () {},
//               child: const Text(
//                 'View All',
//                 style: TextStyle(color: Pallete.primaryLight),
//               ),
//             ),
//           ],
//         ),
//         const SizedBox(height: 12),
//         SizedBox(
//           height: 140,
//           child: ListView(
//             scrollDirection: Axis.horizontal,
//             children: const [
//               ReviewCard(
//                 name: 'Sarah M.',
//                 rating: 5,
//                 review:
//                     'An absolute masterpiece. Fitzgerald\'s prose is poetic and the symbolism is rich. A must-read for anyone who loves...',
//                 timeAgo: '2 days ago',
//               ),
//               SizedBox(width: 12),
//               ReviewCard(
//                 name: 'John D.',
//                 rating: 4,
//                 review:
//                     'Great story! The ending is touching. Highly recommend.',
//                 timeAgo: '1 week ago',
//               ),
//             ],
//           ),
//         ),
//       ],
//     );
//   }
// }

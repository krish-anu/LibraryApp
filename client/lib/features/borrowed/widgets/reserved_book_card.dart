import 'package:flutter/material.dart';
import 'package:libraryapp/core/theme/app_pallete.dart';
import 'package:libraryapp/core/utils/image_helper.dart';
import 'package:libraryapp/models/book.dart';

/// A card displaying reserved book information.
class ReservedBookCard extends StatelessWidget {
  final Book book;
  final String reservationDate;
  final String status;
  final VoidCallback onTap;
  final VoidCallback? onCancel;

  const ReservedBookCard({
    super.key,
    required this.book,
    required this.reservationDate,
    required this.status,
    required this.onTap,
    this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Pallete.cardBackground,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Pallete.border),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Book cover
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image(
                  image: imageProviderFromPath(book.image),
                  width: 70,
                  height: 100,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    width: 70,
                    height: 100,
                    color: Pallete.cardAccent,
                    child: const Icon(Icons.book, color: Colors.white54),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Book info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      book.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      book.author,
                      style: TextStyle(
                        color: Pallete.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Status chip
                    _buildStatusChip(),
                    const SizedBox(height: 8),
                    // Reservation date
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_today,
                          size: 14,
                          color: Pallete.textSecondary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Reserved on: $reservationDate',
                          style: TextStyle(
                            color: Pallete.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Cancel button
              if (onCancel != null)
                IconButton(
                  onPressed: onCancel,
                  icon: Icon(
                    Icons.close,
                    color: Pallete.textSecondary,
                    size: 20,
                  ),
                  tooltip: 'Cancel reservation',
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip() {
    Color chipColor;
    String statusText;
    IconData icon;

    switch (status.toLowerCase()) {
      case 'approved':
      case 'ready':
        chipColor = Pallete.primaryLight;
        statusText = 'Ready for Pickup';
        icon = Icons.check_circle;
        break;
      case 'pending':
        chipColor = Colors.orange;
        statusText = 'Pending';
        icon = Icons.schedule;
        break;
      case 'cancelled':
        chipColor = Pallete.error;
        statusText = 'Cancelled';
        icon = Icons.cancel;
        break;
      default:
        chipColor = Pallete.textSecondary;
        statusText = status;
        icon = Icons.info;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: chipColor.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: chipColor),
          const SizedBox(width: 4),
          Text(
            statusText,
            style: TextStyle(
              color: chipColor,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

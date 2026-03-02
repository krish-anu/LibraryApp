import 'package:flutter/material.dart';
import 'package:libraryapp/core/theme/app_pallete.dart';
import 'package:libraryapp/core/utils/image_helper.dart';
import 'package:libraryapp/models/book.dart';

/// A beautiful card displaying borrowed book information.
class BorrowedBookCard extends StatelessWidget {
  final Book book;
  final DateTime dueDate;
  final VoidCallback onTap;

  const BorrowedBookCard({
    super.key,
    required this.book,
    required this.dueDate,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final remainingDays = dueDate.difference(DateTime.now()).inDays;
    final isOverdue = remainingDays < 0;
    final isDueSoon = remainingDays >= 0 && remainingDays <= 3;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Pallete.cardBackground,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isOverdue
                ? Pallete.error.withValues(alpha: 0.5)
                : isDueSoon
                ? Pallete.warning.withValues(alpha: 0.5)
                : Pallete.border,
            width: isOverdue || isDueSoon ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            _buildMainContent(remainingDays, isOverdue, isDueSoon),
            _buildProgressBar(remainingDays, isOverdue),
          ],
        ),
      ),
    );
  }

  Widget _buildMainContent(int remainingDays, bool isOverdue, bool isDueSoon) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildBookCover(),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildStatusBadge(remainingDays, isOverdue, isDueSoon),
                const SizedBox(height: 8),
                _buildBookTitle(),
                const SizedBox(height: 4),
                _buildAuthor(),
                const SizedBox(height: 12),
                _buildDueInfo(remainingDays, isOverdue),
                if (isOverdue) ...[
                  const SizedBox(height: 8),
                  _buildFineInfo(remainingDays),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBookCover() {
    return Container(
      width: 80,
      height: 120,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image(
          image: imageProviderFromPath(book.image),
          fit: BoxFit.cover,
        ),
      ),
    );
  }

  Widget _buildStatusBadge(int remainingDays, bool isOverdue, bool isDueSoon) {
    final Color bgColor;
    final Color textColor;
    final String text;
    final IconData icon;

    if (isOverdue) {
      bgColor = Pallete.error.withValues(alpha: 0.2);
      textColor = Pallete.error;
      text = 'OVERDUE';
      icon = Icons.warning_amber_rounded;
    } else if (isDueSoon) {
      bgColor = Pallete.warning.withValues(alpha: 0.2);
      textColor = Pallete.warning;
      text = 'DUE SOON';
      icon = Icons.schedule;
    } else {
      bgColor = Pallete.success.withValues(alpha: 0.2);
      textColor = Pallete.success;
      text = 'ON LOAN';
      icon = Icons.check_circle_outline;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: textColor),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              color: textColor,
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBookTitle() {
    return Text(
      book.title,
      style: const TextStyle(
        color: Pallete.textPrimary,
        fontSize: 16,
        fontWeight: FontWeight.bold,
      ),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildAuthor() {
    return Text(
      'by ${book.author}',
      style: TextStyle(color: Pallete.textSecondary, fontSize: 13),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildDueInfo(int remainingDays, bool isOverdue) {
    final formattedDate =
        '${_monthName(dueDate.month)} ${dueDate.day}, ${dueDate.year}';

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: Pallete.scaffoldBackground,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            Icons.calendar_today,
            size: 14,
            color: isOverdue ? Pallete.error : Pallete.primaryLight,
          ),
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isOverdue ? 'Was due' : 'Return by',
              style: TextStyle(color: Pallete.textSecondary, fontSize: 10),
            ),
            Text(
              formattedDate,
              style: TextStyle(
                color: isOverdue ? Pallete.error : Pallete.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFineInfo(int remainingDays) {
    final fine = remainingDays.abs() * 0.25;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Pallete.error.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Pallete.error.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.attach_money, size: 14, color: Pallete.error),
          const SizedBox(width: 4),
          Text(
            'Late fee: LKR ${fine.toStringAsFixed(2)}',
            style: const TextStyle(
              color: Pallete.error,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar(int remainingDays, bool isOverdue) {
    // Calculate progress (14 day loan period)
    const totalDays = 14;
    final daysUsed = totalDays - remainingDays;
    final progress = isOverdue ? 1.0 : (daysUsed / totalDays).clamp(0.0, 1.0);

    final Color progressColor;
    if (isOverdue) {
      progressColor = Pallete.error;
    } else if (remainingDays <= 3) {
      progressColor = Pallete.warning;
    } else {
      progressColor = Pallete.primaryLight;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                isOverdue
                    ? '${remainingDays.abs()} days overdue'
                    : '$remainingDays days remaining',
                style: TextStyle(
                  color: progressColor,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                '${(progress * 100).toInt()}%',
                style: TextStyle(color: Pallete.textSecondary, fontSize: 11),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: Pallete.scaffoldBackground,
              valueColor: AlwaysStoppedAnimation<Color>(progressColor),
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }

  String _monthName(int month) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return months[month - 1];
  }
}

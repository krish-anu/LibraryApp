import 'package:flutter/material.dart';
import 'package:libraryapp/models/book.dart';

class BorrowedCard extends StatelessWidget {
  final Book book;
  final VoidCallback onTap;
  final DateTime dueDate;

  const BorrowedCard({
    super.key,
    required this.book,
    required this.onTap,
    required this.dueDate,
  });

  @override
  Widget build(BuildContext context) {
    final remainingDays = dueDate.difference(DateTime.now()).inDays;
    final isOverdue = remainingDays < 0;
    final fine = isOverdue ? remainingDays.abs() * 50 : 0;
    final formattedDate = "${dueDate.day}/${dueDate.month}/${dueDate.year}";

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(10),
        leading: Container(
          width: 50,
          height: 80,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            image: DecorationImage(
              image: AssetImage(book.image.replaceFirst('client/', '')),
              fit: BoxFit.cover,
            ),
          ),
        ),
        title: Text(
          book.title,
          style: const TextStyle(fontWeight: FontWeight.bold),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(book.author, maxLines: 1, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  size: 14,
                  color: isOverdue ? Colors.red : Colors.green,
                ),
                const SizedBox(width: 4),
                Text(
                  "Return by: $formattedDate",
                  style: TextStyle(
                    color: isOverdue ? Colors.red : Colors.green,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  isOverdue
                      ? "Overdue by ${remainingDays.abs()} days"
                      : "$remainingDays days remaining",
                  style: TextStyle(
                    color: isOverdue ? Colors.red : Colors.orange,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (isOverdue) ...[
                  const SizedBox(height: 4),
                  Text(
                    "Fine: Rs.$fine",
                    style: const TextStyle(
                      color: Colors.red,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
        onTap: onTap,
      ),
    );
  }
}

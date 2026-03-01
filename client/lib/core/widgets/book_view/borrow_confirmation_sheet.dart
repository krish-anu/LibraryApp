import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:libraryapp/core/theme/app_pallete.dart';
import 'package:libraryapp/core/utils/image_helper.dart';
import 'package:libraryapp/data/repository/book_repository.dart';
import 'package:libraryapp/data/repository/loan_repository.dart';
import 'package:libraryapp/data/repository/reserve_repository.dart';
import 'package:libraryapp/models/book.dart';
import 'package:libraryapp/models/reserve.dart';

class BorrowConfirmationSheet extends ConsumerStatefulWidget {
  final Book book;

  const BorrowConfirmationSheet({super.key, required this.book});

  @override
  ConsumerState<BorrowConfirmationSheet> createState() =>
      _BorrowConfirmationSheetState();
}

class _BorrowConfirmationSheetState
    extends ConsumerState<BorrowConfirmationSheet> {
  bool _isLoading = false;
  static const _borrowConflictMessage =
      'You already borrowed this book. Return it before borrowing again.';
  static const _reserveWhileBorrowedMessage =
      'You already borrowed this book. Return it before reserving.';
  static const _alreadyReservedMessage = 'You already reserved this book.';

  @override
  Widget build(BuildContext context) {
    final isAvailable = widget.book.copiesOwned > 0;
    final returnDate = DateTime.now().add(const Duration(days: 14));
    final dateStr =
        '${_monthName(returnDate.month)} ${returnDate.day}, ${returnDate.year}';

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF1A3D2E), Color(0xFF0D2818)],
        ),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ReadyToBorrowBadge(isAvailable: isAvailable),
          const SizedBox(height: 20),
          _SheetTitle(isAvailable: isAvailable),
          const SizedBox(height: 24),
          _BookInfoCard(book: widget.book),
          const SizedBox(height: 20),
          _LoanDetailsRow(dateStr: dateStr, isAvailable: isAvailable),
          const SizedBox(height: 20),
          _WarningNote(isAvailable: isAvailable),
          const SizedBox(height: 24),
          _ConfirmButton(
            isAvailable: isAvailable,
            isLoading: _isLoading,
            onPressed: () => _onConfirm(context, isAvailable),
          ),
          const SizedBox(height: 12),
          _CancelButton(onPressed: () => Navigator.pop(context)),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Future<void> _onConfirm(BuildContext context, bool isAvailable) async {
    setState(() => _isLoading = true);

    if (isAvailable) {
      // Borrow the book
      final loanRepo = ref.read(loanRepositoryProvider);
      final result = await loanRepo.borrowBook(widget.book.id, 'm1');

      if (mounted) {
        setState(() => _isLoading = false);
        result.fold(
          (failure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(_friendlyErrorMessage(failure.message)),
                backgroundColor: Pallete.error,
              ),
            );
          },
          (loan) {
            // Refresh providers
            ref.invalidate(fetchAllLoansProvider);
            ref.invalidate(fetchAllBooksProvider);
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Book borrowed successfully!'),
                backgroundColor: Pallete.primaryLight,
              ),
            );
          },
        );
      }
    } else {
      // Reserve the book
      final reserveRepo = ref.read(reserveRepositoryProvider);
      final reservation = Reserve(
        id: '',
        bookId: widget.book.id,
        memberId: 'm1',
        reservationDate: DateTime.now().toIso8601String().split('T')[0],
        status: 'pending',
      );
      final result = await reserveRepo.addReserve(reservation);

      if (mounted) {
        setState(() => _isLoading = false);
        result.fold(
          (failure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(_friendlyErrorMessage(failure.message)),
                backgroundColor: Pallete.error,
              ),
            );
          },
          (reserve) {
            // Refresh providers
            ref.invalidate(fetchReservationsByMemberProvider('m1'));
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Book reserved successfully!'),
                backgroundColor: Pallete.primaryLight,
              ),
            );
          },
        );
      }
    }
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

  String _friendlyErrorMessage(String raw) {
    final message = raw.trim();
    final lower = message.toLowerCase();

    if (lower.contains('already borrowed this book')) {
      if (lower.contains('before reserving')) return _reserveWhileBorrowedMessage;
      return _borrowConflictMessage;
    }
    if (lower.contains('already reserved this book')) {
      return _alreadyReservedMessage;
    }
    if (lower.contains('unable to borrow this book')) return _borrowConflictMessage;
    if (lower.contains('unable to reserve this book')) {
      return 'Unable to reserve this book right now. Please try again later.';
    }
    return message;
  }
}

class _ReadyToBorrowBadge extends StatelessWidget {
  final bool isAvailable;

  const _ReadyToBorrowBadge({required this.isAvailable});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: (isAvailable ? Pallete.primaryLight : Colors.orange).withValues(
          alpha: 0.2,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isAvailable ? Pallete.primaryLight : Colors.orange,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isAvailable ? Icons.check_circle : Icons.schedule,
            color: isAvailable ? Pallete.primaryLight : Colors.orange,
            size: 16,
          ),
          const SizedBox(width: 6),
          Text(
            isAvailable ? 'READY TO BORROW' : 'RESERVE THIS BOOK',
            style: TextStyle(
              color: isAvailable ? Pallete.primaryLight : Colors.orange,
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }
}

class _SheetTitle extends StatelessWidget {
  final bool isAvailable;

  const _SheetTitle({required this.isAvailable});

  @override
  Widget build(BuildContext context) {
    return Text(
      isAvailable ? 'Confirm Borrow' : 'Confirm Reservation',
      style: const TextStyle(
        color: Pallete.textPrimary,
        fontSize: 24,
        fontWeight: FontWeight.bold,
      ),
    );
  }
}

class _BookInfoCard extends StatelessWidget {
  final Book book;

  const _BookInfoCard({required this.book});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Pallete.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Pallete.border),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image(
              image: imageProviderFromPath(book.image),
              height: 80,
              width: 55,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  book.title,
                  style: const TextStyle(
                    color: Pallete.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  book.author,
                  style: TextStyle(color: Pallete.textSecondary, fontSize: 13),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _SmallChip(label: book.category),
                    const SizedBox(width: 6),
                    const _SmallChip(label: 'Classic'),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SmallChip extends StatelessWidget {
  final String label;

  const _SmallChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Pallete.scaffoldBackground,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label.toUpperCase(),
        style: const TextStyle(
          color: Pallete.textPrimary,
          fontSize: 9,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _LoanDetailsRow extends StatelessWidget {
  final String dateStr;
  final bool isAvailable;

  const _LoanDetailsRow({required this.dateStr, required this.isAvailable});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _InfoCard(
            icon: Icons.calendar_today,
            title: isAvailable ? 'RETURN BY' : 'RESERVED ON',
            value: dateStr,
            subtitle: isAvailable ? '14 days loan period' : 'Queue position: 1',
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _InfoCard(
            icon: isAvailable ? Icons.attach_money : Icons.notifications,
            title: isAvailable ? 'LATE FEE' : 'NOTIFICATION',
            value: isAvailable ? '\$0.25/day' : 'Email',
            subtitle: isAvailable ? 'After due date' : 'When book is available',
          ),
        ),
      ],
    );
  }
}

class _InfoCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final String subtitle;

  const _InfoCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Pallete.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Pallete.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                title,
                style: TextStyle(
                  color: Pallete.textSecondary,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Pallete.primaryLight.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(icon, color: Pallete.primaryLight, size: 14),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              color: Pallete.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(color: Pallete.textSecondary, fontSize: 11),
          ),
        ],
      ),
    );
  }
}

class _WarningNote extends StatelessWidget {
  final bool isAvailable;

  const _WarningNote({required this.isAvailable});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Pallete.warning.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Pallete.warning.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: Pallete.warning, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              isAvailable
                  ? 'Note: Items not picked up within 48 hours of reservation approval will be released to the next person in queue.'
                  : 'Note: You will be notified when this book becomes available. Your reservation will be held for 48 hours.',
              style: TextStyle(
                color: Pallete.warning,
                fontSize: 11,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ConfirmButton extends StatelessWidget {
  final bool isAvailable;
  final bool isLoading;
  final VoidCallback onPressed;

  const _ConfirmButton({
    required this.isAvailable,
    required this.isLoading,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: isAvailable ? Pallete.primaryLight : Colors.orange,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: isLoading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.black,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    isAvailable ? 'Confirm Borrow' : 'Confirm Reservation',
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(
                    Icons.arrow_forward,
                    color: Colors.black,
                    size: 20,
                  ),
                ],
              ),
      ),
    );
  }
}

class _CancelButton extends StatelessWidget {
  final VoidCallback onPressed;

  const _CancelButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onPressed,
      child: const Text(
        'Cancel',
        style: TextStyle(color: Pallete.textSecondary, fontSize: 14),
      ),
    );
  }
}

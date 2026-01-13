// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

class ProfileStats {
  final int totalBorrows;
  final int booksRead;
  final double totalFines;
  final int activeLoans;
  final int activeReservations;

  ProfileStats({
    this.totalBorrows = 0,
    this.booksRead = 0,
    this.totalFines = 0.0,
    this.activeLoans = 0,
    this.activeReservations = 0,
  });

  ProfileStats copyWith({
    int? totalBorrows,
    int? booksRead,
    double? totalFines,
    int? activeLoans,
    int? activeReservations,
  }) {
    return ProfileStats(
      totalBorrows: totalBorrows ?? this.totalBorrows,
      booksRead: booksRead ?? this.booksRead,
      totalFines: totalFines ?? this.totalFines,
      activeLoans: activeLoans ?? this.activeLoans,
      activeReservations: activeReservations ?? this.activeReservations,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'total_borrows': totalBorrows,
      'books_read': booksRead,
      'total_fines': totalFines,
      'active_loans': activeLoans,
      'active_reservations': activeReservations,
    };
  }

  factory ProfileStats.fromMap(Map<String, dynamic> map) {
    return ProfileStats(
      totalBorrows: (map['total_borrows'] as num?)?.toInt() ?? 0,
      booksRead: (map['books_read'] as num?)?.toInt() ?? 0,
      totalFines: (map['total_fines'] as num?)?.toDouble() ?? 0.0,
      activeLoans: (map['active_loans'] as num?)?.toInt() ?? 0,
      activeReservations: (map['active_reservations'] as num?)?.toInt() ?? 0,
    );
  }

  String toJson() => json.encode(toMap());

  factory ProfileStats.fromJson(String source) =>
      ProfileStats.fromMap(json.decode(source) as Map<String, dynamic>);

  String get formattedFines => '\$${totalFines.toStringAsFixed(2)}';

  @override
  String toString() {
    return 'ProfileStats(totalBorrows: $totalBorrows, booksRead: $booksRead, totalFines: $totalFines, activeLoans: $activeLoans, activeReservations: $activeReservations)';
  }

  @override
  bool operator ==(covariant ProfileStats other) {
    if (identical(this, other)) return true;
    return other.totalBorrows == totalBorrows &&
        other.booksRead == booksRead &&
        other.totalFines == totalFines &&
        other.activeLoans == activeLoans &&
        other.activeReservations == activeReservations;
  }

  @override
  int get hashCode {
    return totalBorrows.hashCode ^
        booksRead.hashCode ^
        totalFines.hashCode ^
        activeLoans.hashCode ^
        activeReservations.hashCode;
  }
}

// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

class Reserve {
  final String id;
  final String bookId;
  final String reservationDate;
  final String status;
  Reserve({
    required this.id,
    required this.bookId,
    required this.reservationDate,
    required this.status,
  });

  Reserve copyWith({
    String? id,
    String? bookId,
    String? reservationDate,
    String? status,
  }) {
    return Reserve(
      id: id ?? this.id,
      bookId: bookId ?? this.bookId,
      reservationDate: reservationDate ?? this.reservationDate,
      status: status ?? this.status,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'bookId': bookId,
      'reservationDate': reservationDate,
      'status': status,
    };
  }

  factory Reserve.fromMap(Map<String, dynamic> map) {
    return Reserve(
      id: map['id'] as String,
      bookId: map['bookId'] as String,
      reservationDate: map['reservationDate'] as String,
      status: map['status'] as String,
    );
  }

  String toJson() => json.encode(toMap());

  factory Reserve.fromJson(String source) =>
      Reserve.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() {
    return 'Reserve(id: $id, bookId: $bookId, reservationDate: $reservationDate, status: $status)';
  }

  @override
  bool operator ==(covariant Reserve other) {
    if (identical(this, other)) return true;

    return other.id == id &&
        other.bookId == bookId &&
        other.reservationDate == reservationDate &&
        other.status == status;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        bookId.hashCode ^
        reservationDate.hashCode ^
        status.hashCode;
  }
}

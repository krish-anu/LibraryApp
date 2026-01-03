// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

class Loan {
  final String id;
  final String bookId;
  final String memberId;
  final DateTime loanDate;
  final DateTime returnedDate;
  Loan({
    required this.id,
    required this.bookId,
    required this.memberId,
    required this.loanDate,
    required this.returnedDate,
  });

  Loan copyWith({
    String? id,
    String? bookId,
    String? memberId,
    DateTime? loanDate,
    DateTime? returnedDate,
  }) {
    return Loan(
      id: id ?? this.id,
      bookId: bookId ?? this.bookId,
      memberId: memberId ?? this.memberId,
      loanDate: loanDate ?? this.loanDate,
      returnedDate: returnedDate ?? this.returnedDate,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'bookId': bookId,
      'memberId': memberId,
      'loanDate': loanDate.millisecondsSinceEpoch,
      'returnedDate': returnedDate.millisecondsSinceEpoch,
    };
  }

  factory Loan.fromMap(Map<String, dynamic> map) {
    return Loan(
      id: map['id'] as String,
      bookId: map['bookId'] as String,
      memberId: map['memberId'] as String,
      loanDate: DateTime.fromMillisecondsSinceEpoch(map['loanDate'] as int),
      returnedDate: DateTime.fromMillisecondsSinceEpoch(
        map['returnedDate'] as int,
      ),
    );
  }

  String toJson() => json.encode(toMap());

  factory Loan.fromJson(String source) =>
      Loan.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() {
    return 'Loan(id: $id, bookId: $bookId, memberId: $memberId, loanDate: $loanDate, returnedDate: $returnedDate)';
  }

  @override
  bool operator ==(covariant Loan other) {
    if (identical(this, other)) return true;

    return other.id == id &&
        other.bookId == bookId &&
        other.memberId == memberId &&
        other.loanDate == loanDate &&
        other.returnedDate == returnedDate;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        bookId.hashCode ^
        memberId.hashCode ^
        loanDate.hashCode ^
        returnedDate.hashCode;
  }
}

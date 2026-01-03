// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

class Fine {
  final String id;
  final String paymentAmount;
  Fine({required this.id, required this.paymentAmount});

  Fine copyWith({String? id, String? paymentAmount}) {
    return Fine(
      id: id ?? this.id,
      paymentAmount: paymentAmount ?? this.paymentAmount,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{'id': id, 'paymentAmount': paymentAmount};
  }

  factory Fine.fromMap(Map<String, dynamic> map) {
    return Fine(
      id: map['id'] as String,
      paymentAmount: map['paymentAmount'] as String,
    );
  }

  String toJson() => json.encode(toMap());

  factory Fine.fromJson(String source) =>
      Fine.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() => 'Fine(id: $id, paymentAmount: $paymentAmount)';

  @override
  bool operator ==(covariant Fine other) {
    if (identical(this, other)) return true;

    return other.id == id && other.paymentAmount == paymentAmount;
  }

  @override
  int get hashCode => id.hashCode ^ paymentAmount.hashCode;
}

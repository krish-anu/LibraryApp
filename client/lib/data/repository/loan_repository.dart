import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:fpdart/fpdart.dart';
import 'package:libraryapp/core/constants/server_constant.dart';
import 'package:libraryapp/core/failure/failure.dart';
import 'package:libraryapp/models/loan.dart';

part 'loan_repository.g.dart';

@riverpod
LoanRepository loanRepository(Ref ref) {
  return LoanRepository();
}

@riverpod
Future<List<Loan>> fetchAllLoans(Ref ref) async {
  final repository = ref.watch(loanRepositoryProvider);
  final res = await repository.getAllLoans();
  return res.fold((l) => throw l.message, (r) => r);
}

class LoanRepository {
  Future<Either<Failure, List<Loan>>> getAllLoans() async {
    try {
      final res = await http.get(
        Uri.parse('${ServerConstant.serverURL}/loans'),
      );

      if (res.statusCode == 200) {
        final List<dynamic> data = jsonDecode(res.body);
        final loans = data.map((e) {
          return Loan(
            id: e['id']?.toString() ?? '',
            bookId: e['book_id']?.toString() ?? '',
            memberId: e['member_id']?.toString() ?? '',
            loanDate: DateTime.parse(e['loan_date']),
            returnedDate: DateTime.parse(e['returned_date']),
          );
        }).toList();
        return right(loans);
      } else {
        return left(Failure(res.body));
      }
    } catch (e) {
      return left(Failure(e.toString()));
    }
  }
}

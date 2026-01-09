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

@riverpod
Future<List<Loan>> fetchActiveLoans(Ref ref, {String? memberId}) async {
  final repository = ref.watch(loanRepositoryProvider);
  final res = await repository.getActiveLoans(memberId: memberId);
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
        final loans = data.map((e) => _parseLoan(e)).toList();
        return right(loans);
      } else {
        return left(Failure(res.body));
      }
    } catch (e) {
      return left(Failure(e.toString()));
    }
  }

  Future<Either<Failure, List<Loan>>> getActiveLoans({String? memberId}) async {
    try {
      var url = '${ServerConstant.serverURL}/loans/active';
      if (memberId != null) {
        url += '?member_id=$memberId';
      }
      final res = await http.get(Uri.parse(url));

      if (res.statusCode == 200) {
        final List<dynamic> data = jsonDecode(res.body);
        final loans = data.map((e) => _parseLoan(e)).toList();
        return right(loans);
      } else {
        return left(Failure(res.body));
      }
    } catch (e) {
      return left(Failure(e.toString()));
    }
  }

  Future<Either<Failure, Loan>> borrowBook(
    String bookId,
    String memberId,
  ) async {
    try {
      final res = await http.post(
        Uri.parse(
          '${ServerConstant.serverURL}/loans/borrow?book_id=$bookId&member_id=$memberId',
        ),
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        return right(_parseLoan(data));
      } else {
        return left(Failure(res.body));
      }
    } catch (e) {
      return left(Failure(e.toString()));
    }
  }

  Future<Either<Failure, String>> returnBook(String loanId) async {
    try {
      final res = await http.post(
        Uri.parse('${ServerConstant.serverURL}/loans/return/$loanId'),
      );

      if (res.statusCode == 200) {
        return right('Book returned successfully');
      } else {
        return left(Failure(res.body));
      }
    } catch (e) {
      return left(Failure(e.toString()));
    }
  }

  Future<Either<Failure, Loan>> renewLoan(String loanId) async {
    try {
      final res = await http.post(
        Uri.parse('${ServerConstant.serverURL}/loans/renew/$loanId'),
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        return right(_parseLoan(data));
      } else {
        return left(Failure(res.body));
      }
    } catch (e) {
      return left(Failure(e.toString()));
    }
  }

  Loan _parseLoan(Map<String, dynamic> e) {
    return Loan(
      id: e['id']?.toString() ?? '',
      bookId: e['book_id']?.toString() ?? '',
      memberId: e['member_id']?.toString() ?? '',
      loanDate: DateTime.parse(e['loan_date']),
      returnedDate: DateTime.parse(e['returned_date']),
    );
  }
}

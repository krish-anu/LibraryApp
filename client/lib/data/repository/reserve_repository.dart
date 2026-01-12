import 'dart:convert';

import 'package:fpdart/fpdart.dart';
import 'package:libraryapp/core/constants/server_constant.dart';
import 'package:libraryapp/core/failure/failure.dart';
import 'package:libraryapp/models/reserve.dart';
import 'package:http/http.dart' as http;
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'reserve_repository.g.dart';

@riverpod
ReserveRepository reserveRepository(Ref ref) {
  return ReserveRepository();
}

@riverpod
Future<List<Reserve>> fetchReservationsByMember(
  Ref ref,
  String memberId,
) async {
  final repository = ref.watch(reserveRepositoryProvider);
  final res = await repository.getReservedByMember(memberId);
  return res.fold((l) => [], (r) => r);
}

class ReserveRepository {
  Future<Either<AppFailure, List<Reserve>>> getAllReservedBooks() async {
    try {
      final res = await http.get(
        Uri.parse('${ServerConstant.serverURL}/reservations'),
      );
      if (res.statusCode == 200) {
        final List<dynamic> data = jsonDecode(res.body) as List<dynamic>;
        final books = data
            .map((e) => Reserve.fromMap(e as Map<String, dynamic>))
            .toList();
        return Right(books);
      }
      return Left(
        AppFailure('Failed to fetch reserved books: ${res.statusCode}'),
      );
    } catch (e) {
      return Left(AppFailure(e.toString()));
    }
  }

  Future<Either<AppFailure, Reserve>> addReserve(Reserve reserve) async {
    try {
      final res = await http.post(
        Uri.parse('${ServerConstant.serverURL}/reservations'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(reserve.toMap()),
      );

      if (res.statusCode == 201 || res.statusCode == 200) {
        final Map<String, dynamic> data =
            jsonDecode(res.body) as Map<String, dynamic>;
        return Right(Reserve.fromMap(data));
      }

      return Left(
        AppFailure('Failed to create reservation: ${res.statusCode}'),
      );
    } catch (e) {
      return Left(AppFailure(e.toString()));
    }
  }

  Future<Either<AppFailure, List<Reserve>>> getReservedByMember(
    String memberId,
  ) async {
    try {
      final res = await http.get(
        Uri.parse('${ServerConstant.serverURL}/reservations/member/$memberId'),
      );
      if (res.statusCode == 200) {
        final List<dynamic> data = jsonDecode(res.body) as List<dynamic>;
        final books = data
            .map((e) => Reserve.fromMap(e as Map<String, dynamic>))
            .toList();
        return Right(books);
      }
      if (res.statusCode == 404) {
        return Left(AppFailure('No reservations found for member: $memberId'));
      }
      return Left(
        AppFailure('Failed to fetch reservations: ${res.statusCode}'),
      );
    } catch (e) {
      return Left(AppFailure(e.toString()));
    }
  }
}

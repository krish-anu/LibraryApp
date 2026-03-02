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
        AppFailure(
          _extractErrorMessage(
            res.body,
            fallback: 'Unable to reserve this book right now.',
          ),
        ),
      );
    } catch (e) {
      return Left(AppFailure('Unable to reserve this book right now.'));
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

  String _extractErrorMessage(String body, {required String fallback}) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) {
        for (final key in const [
          'detail',
          'Detail',
          'error',
          'Error',
          'message',
          'Message',
        ]) {
          final value = decoded[key];
          if (value is String && value.trim().isNotEmpty) return value.trim();
        }
      }
    } catch (_) {
      // Non-JSON error body, use fallback.
    }

    final lowerBody = body.toLowerCase();
    final detailIndex = lowerBody.indexOf('detail');
    if (detailIndex >= 0) {
      final colonIndex = body.indexOf(':', detailIndex);
      final equalIndex = body.indexOf('=', detailIndex);
      final separatorIndex = [colonIndex, equalIndex]
          .where((idx) => idx >= 0)
          .fold<int>(-1, (minIdx, idx) {
            if (minIdx == -1) return idx;
            return idx < minIdx ? idx : minIdx;
          });

      if (separatorIndex >= 0 && separatorIndex + 1 < body.length) {
        var extracted = body.substring(separatorIndex + 1).trim();
        const leadingTrimChars = " {[(\"'";
        const trailingTrimChars = " }]),\"'";
        while (extracted.isNotEmpty &&
            leadingTrimChars.contains(extracted[0])) {
          extracted = extracted.substring(1).trimLeft();
        }
        while (extracted.isNotEmpty &&
            trailingTrimChars.contains(extracted[extracted.length - 1])) {
          extracted = extracted.substring(0, extracted.length - 1).trimRight();
        }
        if (extracted.isNotEmpty) return extracted;
      }
    }

    return fallback;
  }
}

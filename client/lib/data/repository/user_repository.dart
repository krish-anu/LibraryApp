import 'dart:convert';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:fpdart/fpdart.dart';
import 'package:libraryapp/core/constants/server_constant.dart';
import 'package:libraryapp/core/failure/failure.dart';
import 'package:libraryapp/core/services/authenticated_http_client.dart';
import 'package:libraryapp/models/user_profile.dart';
import 'package:libraryapp/models/profile_stats.dart';

part 'user_repository.g.dart';

@riverpod
UserRepository userRepository(Ref ref) {
  return UserRepository();
}

@riverpod
Future<UserProfile> fetchUserProfile(Ref ref, String userId) async {
  final repository = ref.watch(userRepositoryProvider);
  final res = await repository.getUserById(userId);
  return res.fold((l) => throw l.message, (r) => r);
}

@riverpod
Future<ProfileStats> fetchUserStats(Ref ref, String userId) async {
  final repository = ref.watch(userRepositoryProvider);
  final res = await repository.getUserStats(userId);
  return res.fold((l) => throw l.message, (r) => r);
}

class UserRepository {
  Future<Either<Failure, UserProfile>> getUserById(String userId) async {
    try {
      final res = await AuthenticatedHttpClient.get(
        Uri.parse('${ServerConstant.serverURL}/users/$userId'),
        headers: {'Content-Type': 'application/json'},
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        return right(UserProfile.fromMap(data));
      } else {
        return left(Failure(res.body));
      }
    } catch (e) {
      return left(Failure(e.toString()));
    }
  }

  Future<Either<Failure, UserProfile>> getUserByMemberId(
    String memberId,
  ) async {
    try {
      final res = await AuthenticatedHttpClient.get(
        Uri.parse('${ServerConstant.serverURL}/users/by-member/$memberId'),
        headers: {'Content-Type': 'application/json'},
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        return right(UserProfile.fromMap(data));
      } else {
        return left(Failure(res.body));
      }
    } catch (e) {
      return left(Failure(e.toString()));
    }
  }

  Future<Either<Failure, ProfileStats>> getUserStats(String userId) async {
    try {
      final res = await AuthenticatedHttpClient.get(
        Uri.parse('${ServerConstant.serverURL}/users/$userId/stats'),
        headers: {'Content-Type': 'application/json'},
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        return right(ProfileStats.fromMap(data));
      } else {
        return left(Failure(res.body));
      }
    } catch (e) {
      return left(Failure(e.toString()));
    }
  }

  Future<Either<Failure, UserProfile>> updateUser(
    String userId,
    Map<String, dynamic> updateData,
  ) async {
    try {
      final res = await AuthenticatedHttpClient.put(
        Uri.parse('${ServerConstant.serverURL}/users/$userId'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(updateData),
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        return right(UserProfile.fromMap(data));
      } else {
        return left(Failure(res.body));
      }
    } catch (e) {
      return left(Failure(e.toString()));
    }
  }
}

import 'dart:convert';

import 'package:fpdart/fpdart.dart';
import 'package:libraryapp/core/constants/server_constant.dart';
import 'package:libraryapp/core/failure/failure.dart';
import 'package:libraryapp/core/services/authenticated_http_client.dart';
import 'package:libraryapp/models/user.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'auth_remote_repository.g.dart';

@riverpod
AuthRemoteRepository authRemoteRepository(Ref ref) {
  return AuthRemoteRepository();
}

class AuthRemoteRepository {
  Future<Either<AppFailure, User>> signup(
    String name,
    String email,
    String password,
  ) async {
    return Left(
      AppFailure(
        'Legacy backend signup is disabled. Use Asgardeo registration instead.',
      ),
    );
  }

  Future<Either<AppFailure, User>> login(String email, String password) async {
    return Left(
      AppFailure(
        'Legacy password login is disabled. Use Asgardeo PKCE login instead.',
      ),
    );
  }

  Future<Either<AppFailure, User>> getCurrentUserData(String token) async {
    try {
      final response = await AuthenticatedHttpClient.get(
        Uri.parse('${ServerConstant.serverURL}/auth/'),
        headers: {'Content-Type': 'application/json', 'x-auth-token': token},
      );
      final resBodyMap = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode != 200) {
        return Left(AppFailure(resBodyMap['detail']));
      }
      return Right(User.fromMap(resBodyMap).copyWith(token: token));
    } catch (e) {
      return Left(AppFailure(e.toString()));
    }
  }

  Future<Either<AppFailure, User>> getUserById(String id) async {
    try {
      final response = await AuthenticatedHttpClient.get(
        Uri.parse('${ServerConstant.serverURL}/users/$id'),
        headers: {'Content-Type': 'application/json'},
      );
      final resBodyMap = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode != 200) {
        return Left(AppFailure(resBodyMap['detail'] ?? 'Failed to fetch user'));
      }

      // Map server `name` -> client `userName`, token not provided here
      final userMap = {
        'userName': resBodyMap['name'] ?? '',
        'email': resBodyMap['email'] ?? '',
        'id': resBodyMap['id'] ?? id,
        'token': '',
      };

      return Right(User.fromMap(userMap));
    } catch (e) {
      return Left(AppFailure(e.toString()));
    }
  }

  Future<Either<AppFailure, User>> getUserByMemberId(String memberId) async {
    try {
      final response = await AuthenticatedHttpClient.get(
        Uri.parse('${ServerConstant.serverURL}/users/by-member/$memberId'),
        headers: {'Content-Type': 'application/json'},
      );
      final resBodyMap = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode != 200) {
        return Left(AppFailure(resBodyMap['detail'] ?? 'Failed to fetch user'));
      }

      final userMap = {
        'userName': resBodyMap['name'] ?? '',
        'email': resBodyMap['email'] ?? '',
        'id': resBodyMap['id'] ?? '',
        'token': '',
      };

      return Right(User.fromMap(userMap));
    } catch (e) {
      return Left(AppFailure(e.toString()));
    }
  }
}

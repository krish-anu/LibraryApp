import 'dart:convert';

import 'package:fpdart/fpdart.dart';
import 'package:http/http.dart' as http;
import 'package:libraryapp/core/constants/server_constant.dart';
import 'package:libraryapp/core/failure/failure.dart';
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
    try {
      final response = await http.post(
        Uri.parse('${ServerConstant.serverURL}/auth/signup'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'name': name, 'email': email, 'password': password}),
      );
      final resBodyMap = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode != 201) {
        //handle error
        return Left(AppFailure(resBodyMap['detail']));
      }
      return Right(User.fromMap(resBodyMap));
    } catch (e) {
      return Left(AppFailure(e.toString()));
    }
  }

  Future<Either<AppFailure, User>> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('${ServerConstant.serverURL}/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );
      final resBodyMap = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode != 200) {
        return Left(AppFailure(resBodyMap['detail']));
      }
      return Right(
        User.fromMap(resBodyMap['user']).copyWith(token: resBodyMap['token']),
      );
    } catch (e) {
      return Left(AppFailure(e.toString()));
    }
  }

  Future<Either<AppFailure, User>> getCurrentUserData(String token) async {
    try {
      final response = await http.get(
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
      final response = await http.get(
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
      final response = await http.get(
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

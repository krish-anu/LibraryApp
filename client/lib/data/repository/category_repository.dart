import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:libraryapp/core/constants/server_constant.dart';
import 'package:libraryapp/models/category.dart';

final fetchCategoriesProvider = FutureProvider<List<Category>>((ref) async {
  final res = await http.get(Uri.parse('${ServerConstant.serverURL}/category'));
  if (res.statusCode == 200) {
    final List<dynamic> data = jsonDecode(res.body);
    return data
        .map((e) => Category.fromMap(e as Map<String, dynamic>))
        .toList();
  } else {
    throw Exception('Failed to load categories: ${res.statusCode}');
  }
});

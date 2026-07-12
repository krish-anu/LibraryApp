import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:libraryapp/core/constants/server_constant.dart';
import 'package:libraryapp/core/services/authenticated_http_client.dart';
import 'package:libraryapp/models/content.dart';

final contentRepositoryProvider = Provider<ContentRepository>((ref) {
  return ContentRepository();
});

final fetchBlogsProvider = FutureProvider<List<BlogPost>>((ref) async {
  final repository = ref.watch(contentRepositoryProvider);
  return repository.getBlogs();
});

final fetchVideosProvider = FutureProvider<List<LibraryVideo>>((ref) async {
  final repository = ref.watch(contentRepositoryProvider);
  return repository.getVideos();
});

class ContentRepository {
  Future<List<BlogPost>> getBlogs() async {
    final res = await AuthenticatedHttpClient.get(
      Uri.parse('${ServerConstant.serverURL}/blogs'),
    );
    if (res.statusCode != 200) {
      throw Exception('Failed to load blogs: ${res.statusCode}');
    }

    final List<dynamic> data = jsonDecode(res.body);
    return data
        .map((e) => BlogPost.fromMap(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<LibraryVideo>> getVideos() async {
    final res = await AuthenticatedHttpClient.get(
      Uri.parse('${ServerConstant.serverURL}/videos'),
    );
    if (res.statusCode != 200) {
      throw Exception('Failed to load videos: ${res.statusCode}');
    }

    final List<dynamic> data = jsonDecode(res.body);
    return data
        .map((e) => LibraryVideo.fromMap(e as Map<String, dynamic>))
        .toList();
  }
}

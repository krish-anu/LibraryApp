class BlogPost {
  final String id;
  final String title;
  final String excerpt;
  final String content;
  final String author;
  final String category;
  final String? coverImage;
  final int readMinutes;
  final DateTime publishedAt;

  const BlogPost({
    required this.id,
    required this.title,
    required this.excerpt,
    required this.content,
    required this.author,
    required this.category,
    required this.coverImage,
    required this.readMinutes,
    required this.publishedAt,
  });

  factory BlogPost.fromMap(Map<String, dynamic> map) {
    return BlogPost(
      id: map['id']?.toString() ?? '',
      title: map['title']?.toString() ?? '',
      excerpt: map['excerpt']?.toString() ?? '',
      content: map['content']?.toString() ?? '',
      author: map['author']?.toString() ?? 'Library Team',
      category: map['category']?.toString() ?? 'Library',
      coverImage: map['cover_image']?.toString(),
      readMinutes: (map['read_minutes'] as num?)?.toInt() ?? 3,
      publishedAt:
          DateTime.tryParse(map['published_at']?.toString() ?? '') ??
          DateTime.now(),
    );
  }
}

class LibraryVideo {
  final String id;
  final String title;
  final String description;
  final String youtubeVideoId;
  final String? youtubeUrlValue;
  final String speaker;
  final String category;
  final String duration;
  final String? thumbnailUrl;
  final DateTime publishedAt;

  const LibraryVideo({
    required this.id,
    required this.title,
    required this.description,
    required this.youtubeVideoId,
    required this.youtubeUrlValue,
    required this.speaker,
    required this.category,
    required this.duration,
    required this.thumbnailUrl,
    required this.publishedAt,
  });

  String get resolvedYoutubeVideoId =>
      extractYoutubeVideoId(youtubeUrlValue) ??
      extractYoutubeVideoId(youtubeVideoId) ??
      '';
  String get youtubeUrl => youtubeUrlValue?.trim().isNotEmpty == true
      ? youtubeUrlValue!.trim()
      : 'https://www.youtube.com/watch?v=$resolvedYoutubeVideoId';
  String get embedUrl =>
      'https://www.youtube.com/embed/$resolvedYoutubeVideoId';
  String get effectiveThumbnailUrl =>
      thumbnailUrl ??
      (resolvedYoutubeVideoId.isNotEmpty
          ? 'https://img.youtube.com/vi/$resolvedYoutubeVideoId/hqdefault.jpg'
          : '');

  static String? extractYoutubeVideoId(String? value) {
    final raw = value?.trim();
    if (raw == null || raw.isEmpty) return null;

    final rawIdMatch = RegExp(r'^[a-zA-Z0-9_-]{6,32}$').firstMatch(raw);
    if (rawIdMatch != null) return raw;

    final uri = Uri.tryParse(raw);
    if (uri == null) return null;

    final queryVideoId = uri.queryParameters['v'];
    if (queryVideoId != null && queryVideoId.trim().isNotEmpty) {
      return _cleanVideoId(queryVideoId);
    }

    final segments = uri.pathSegments;
    if (uri.host.contains('youtu.be') && segments.isNotEmpty) {
      return _cleanVideoId(segments.first);
    }

    for (final marker in ['embed', 'shorts', 'live', 'v']) {
      final index = segments.indexOf(marker);
      if (index >= 0 && segments.length > index + 1) {
        return _cleanVideoId(segments[index + 1]);
      }
    }

    return null;
  }

  static String _cleanVideoId(String value) {
    return value.split(RegExp(r'[?&#/]')).first.trim();
  }

  factory LibraryVideo.fromMap(Map<String, dynamic> map) {
    return LibraryVideo(
      id: map['id']?.toString() ?? '',
      title: map['title']?.toString() ?? '',
      description: map['description']?.toString() ?? '',
      youtubeVideoId: map['youtube_video_id']?.toString() ?? '',
      youtubeUrlValue: map['youtube_url']?.toString(),
      speaker: map['speaker']?.toString() ?? 'Library Team',
      category: map['category']?.toString() ?? 'Learning',
      duration: map['duration']?.toString() ?? '',
      thumbnailUrl: map['thumbnail_url']?.toString(),
      publishedAt:
          DateTime.tryParse(map['published_at']?.toString() ?? '') ??
          DateTime.now(),
    );
  }
}

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
    required this.speaker,
    required this.category,
    required this.duration,
    required this.thumbnailUrl,
    required this.publishedAt,
  });

  String get youtubeUrl => 'https://www.youtube.com/watch?v=$youtubeVideoId';
  String get embedUrl => 'https://www.youtube.com/embed/$youtubeVideoId';
  String get effectiveThumbnailUrl =>
      thumbnailUrl ??
      'https://img.youtube.com/vi/$youtubeVideoId/hqdefault.jpg';

  factory LibraryVideo.fromMap(Map<String, dynamic> map) {
    return LibraryVideo(
      id: map['id']?.toString() ?? '',
      title: map['title']?.toString() ?? '',
      description: map['description']?.toString() ?? '',
      youtubeVideoId: map['youtube_video_id']?.toString() ?? '',
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

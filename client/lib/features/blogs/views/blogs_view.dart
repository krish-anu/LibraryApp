import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:libraryapp/core/theme/app_pallete.dart';
import 'package:libraryapp/core/widgets/common/common_app_bar.dart';
import 'package:libraryapp/data/repository/content_repository.dart';
import 'package:libraryapp/features/blogs/views/blog_detail_view.dart';
import 'package:libraryapp/models/content.dart';

class BlogsView extends ConsumerWidget {
  const BlogsView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final blogs = ref.watch(fetchBlogsProvider);

    return Scaffold(
      backgroundColor: Pallete.scaffoldBackground,
      appBar: const CommonAppBar(title: 'Blogs', centerTitle: true),
      body: blogs.when(
        data: (items) => _BlogsContent(
          blogs: items,
          onRefresh: () async => ref.invalidate(fetchBlogsProvider),
        ),
        loading: () => const Center(
          child: CircularProgressIndicator(color: Pallete.primaryLight),
        ),
        error: (error, stackTrace) => _ErrorState(
          message: error.toString(),
          onRetry: () => ref.invalidate(fetchBlogsProvider),
        ),
      ),
    );
  }
}

class _BlogsContent extends StatelessWidget {
  final List<BlogPost> blogs;
  final Future<void> Function() onRefresh;

  const _BlogsContent({required this.blogs, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    if (blogs.isEmpty) {
      return const _EmptyState(
        icon: Icons.article_outlined,
        title: 'No blogs yet',
        subtitle: 'Library stories and reading tips will appear here.',
      );
    }

    return RefreshIndicator(
      color: Pallete.primaryLight,
      onRefresh: onRefresh,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        itemCount: blogs.length,
        separatorBuilder: (context, index) => const SizedBox(height: 14),
        itemBuilder: (context, index) {
          final blog = blogs[index];
          return _BlogCard(
            blog: blog,
            featured: index == 0,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => BlogDetailView(blog: blog)),
            ),
          );
        },
      ),
    );
  }
}

class _BlogCard extends StatelessWidget {
  final BlogPost blog;
  final bool featured;
  final VoidCallback onTap;

  const _BlogCard({
    required this.blog,
    required this.featured,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Pallete.cardBackground,
      borderRadius: BorderRadius.circular(8),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: featured ? 180 : 132,
              width: double.infinity,
              child: _BlogImage(imageUrl: blog.coverImage),
            ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _CategoryBadge(label: blog.category),
                      const SizedBox(width: 8),
                      Text(
                        '${blog.readMinutes} min read',
                        style: TextStyle(
                          color: Pallete.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    blog.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Pallete.textPrimary,
                      fontSize: featured ? 20 : 17,
                      fontWeight: FontWeight.w800,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    blog.excerpt,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Pallete.textSecondary,
                      fontSize: 14,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BlogImage extends StatelessWidget {
  final String? imageUrl;

  const _BlogImage({required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    final url = imageUrl;
    if (url == null || url.isEmpty) {
      return const ColoredBox(
        color: Pallete.cardAccent,
        child: Center(child: Icon(Icons.article_outlined, size: 42)),
      );
    }

    return Image.network(
      url,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) => const ColoredBox(
        color: Pallete.cardAccent,
        child: Center(child: Icon(Icons.article_outlined, size: 42)),
      ),
    );
  }
}

class _CategoryBadge extends StatelessWidget {
  final String label;

  const _CategoryBadge({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: Pallete.cardAccent,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Pallete.textPrimary,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: Pallete.warning, size: 56),
            const SizedBox(height: 12),
            const Text(
              'Could not load blogs',
              style: TextStyle(
                color: Pallete.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: Pallete.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 18),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh, color: Colors.white),
              label: const Text('Retry', style: TextStyle(color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Pallete.primaryLight,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _EmptyState({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Pallete.textSecondary, size: 56),
            const SizedBox(height: 14),
            Text(
              title,
              style: const TextStyle(
                color: Pallete.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(color: Pallete.textSecondary, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}

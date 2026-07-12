import 'package:flutter/material.dart';
import 'package:libraryapp/core/theme/app_pallete.dart';
import 'package:libraryapp/core/widgets/common/common_app_bar.dart';
import 'package:libraryapp/models/content.dart';

class BlogDetailView extends StatelessWidget {
  final BlogPost blog;

  const BlogDetailView({super.key, required this.blog});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Pallete.scaffoldBackground,
      appBar: const CommonAppBar(title: 'Blog', showBack: true),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _BlogCover(imageUrl: blog.coverImage, height: 240),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _MetaRow(blog: blog),
                  const SizedBox(height: 14),
                  Text(
                    blog.title,
                    style: const TextStyle(
                      color: Pallete.textPrimary,
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      height: 1.15,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    blog.excerpt,
                    style: TextStyle(
                      color: Pallete.textSecondary,
                      fontSize: 16,
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    blog.content,
                    style: const TextStyle(
                      color: Pallete.textPrimary,
                      fontSize: 16,
                      height: 1.65,
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

class _MetaRow extends StatelessWidget {
  final BlogPost blog;

  const _MetaRow({required this.blog});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        _Pill(label: blog.category),
        Text(
          '${blog.readMinutes} min read',
          style: TextStyle(color: Pallete.textSecondary, fontSize: 13),
        ),
        Text(
          'by ${blog.author}',
          style: TextStyle(color: Pallete.textSecondary, fontSize: 13),
        ),
      ],
    );
  }
}

class _Pill extends StatelessWidget {
  final String label;

  const _Pill({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
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

class _BlogCover extends StatelessWidget {
  final String? imageUrl;
  final double height;

  const _BlogCover({required this.imageUrl, required this.height});

  @override
  Widget build(BuildContext context) {
    final url = imageUrl;
    return SizedBox(
      width: double.infinity,
      height: height,
      child: url == null || url.isEmpty
          ? Container(
              color: Pallete.cardAccent,
              child: const Icon(
                Icons.article_outlined,
                color: Pallete.iconColor,
                size: 48,
              ),
            )
          : Image.network(
              url,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                color: Pallete.cardAccent,
                child: const Icon(
                  Icons.article_outlined,
                  color: Pallete.iconColor,
                  size: 48,
                ),
              ),
            ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:libraryapp/core/theme/app_pallete.dart';
import 'package:libraryapp/core/widgets/common/common_app_bar.dart';
import 'package:libraryapp/data/repository/content_repository.dart';
import 'package:libraryapp/models/content.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';

class VideosView extends ConsumerStatefulWidget {
  const VideosView({super.key});

  @override
  ConsumerState<VideosView> createState() => _VideosViewState();
}

class _VideosViewState extends ConsumerState<VideosView> {
  String? _selectedVideoId;

  @override
  Widget build(BuildContext context) {
    final videos = ref.watch(fetchVideosProvider);

    return Scaffold(
      backgroundColor: Pallete.scaffoldBackground,
      appBar: const CommonAppBar(title: 'Videos', centerTitle: true),
      body: videos.when(
        data: (items) => _buildContent(items),
        loading: () => const Center(
          child: CircularProgressIndicator(color: Pallete.primaryLight),
        ),
        error: (error, stackTrace) => _ErrorState(
          message: error.toString(),
          onRetry: () => ref.invalidate(fetchVideosProvider),
        ),
      ),
    );
  }

  Widget _buildContent(List<LibraryVideo> videos) {
    if (videos.isEmpty) {
      return const _EmptyState();
    }

    final selected = videos.firstWhere(
      (video) => video.id == _selectedVideoId,
      orElse: () => videos.first,
    );

    return RefreshIndicator(
      color: Pallete.primaryLight,
      onRefresh: () async => ref.invalidate(fetchVideosProvider),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          _FeaturedVideo(video: selected),
          const SizedBox(height: 18),
          const Text(
            'Watch next',
            style: TextStyle(
              color: Pallete.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          ...videos.map(
            (video) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _VideoListItem(
                video: video,
                selected: video.id == selected.id,
                onTap: () => setState(() => _selectedVideoId = video.id),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FeaturedVideo extends StatelessWidget {
  final LibraryVideo video;

  const _FeaturedVideo({required this.video});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Pallete.cardBackground,
      borderRadius: BorderRadius.circular(8),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AspectRatio(
            aspectRatio: 16 / 9,
            child: YouTubeEmbed(videoId: video.youtubeVideoId),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _CategoryBadge(label: video.category),
                    if (video.duration.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      Text(
                        video.duration,
                        style: TextStyle(
                          color: Pallete.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                    const Spacer(),
                    IconButton(
                      tooltip: 'Open in YouTube',
                      onPressed: () => _openExternal(video),
                      icon: const Icon(Icons.open_in_new, size: 20),
                      color: Pallete.iconColor,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  video.title,
                  style: const TextStyle(
                    color: Pallete.textPrimary,
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  video.description,
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
    );
  }

  Future<void> _openExternal(LibraryVideo video) async {
    final uri = Uri.parse(video.youtubeUrl);
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}

class YouTubeEmbed extends StatefulWidget {
  final String videoId;

  const YouTubeEmbed({super.key, required this.videoId});

  @override
  State<YouTubeEmbed> createState() => _YouTubeEmbedState();
}

class _YouTubeEmbedState extends State<YouTubeEmbed> {
  late final WebViewController _controller;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.black)
      ..loadRequest(Uri.parse(_embedUrl(widget.videoId)));
  }

  @override
  void didUpdateWidget(covariant YouTubeEmbed oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.videoId != widget.videoId) {
      _controller.loadRequest(Uri.parse(_embedUrl(widget.videoId)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.black,
      child: WebViewWidget(controller: _controller),
    );
  }

  String _embedUrl(String videoId) {
    return 'https://www.youtube.com/embed/$videoId?playsinline=1&rel=0&modestbranding=1';
  }
}

class _VideoListItem extends StatelessWidget {
  final LibraryVideo video;
  final bool selected;
  final VoidCallback onTap;

  const _VideoListItem({
    required this.video,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? Pallete.cardAccent : Pallete.cardBackground,
      borderRadius: BorderRadius.circular(8),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Row(
          children: [
            SizedBox(
              width: 128,
              height: 82,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    video.effectiveThumbnailUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        const ColoredBox(
                          color: Pallete.cardAccent,
                          child: Icon(Icons.play_circle_outline),
                        ),
                  ),
                  const Center(
                    child: Icon(
                      Icons.play_circle_fill,
                      color: Colors.white,
                      size: 34,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      video.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Pallete.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      video.speaker,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Pallete.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
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
              'Could not load videos',
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
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.video_library_outlined,
              color: Pallete.textSecondary,
              size: 56,
            ),
            const SizedBox(height: 14),
            const Text(
              'No videos yet',
              style: TextStyle(
                color: Pallete.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Embedded library videos will appear here.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Pallete.textSecondary, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}

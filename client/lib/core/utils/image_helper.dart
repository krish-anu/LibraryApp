import 'package:flutter/widgets.dart';

const String _defaultBookCoverAsset = 'assets/book/book_cover.webp';
const String _defaultProfileAsset = 'assets/person.webp';

/// Returns a proper ImageProvider for the given [path].
///
/// - If [path] is an HTTP(S) URL, returns [NetworkImage].
/// - Otherwise treats it as an asset path and returns [AssetImage].
ImageProvider imageProviderFromPath(String? path) {
  final p = (path ?? '').trim();
  if (p.isEmpty) return const AssetImage(_defaultProfileAsset);

  final uri = Uri.tryParse(p);
  if (uri != null && (uri.scheme == 'http' || uri.scheme == 'https')) {
    final host = uri.host.toLowerCase();
    if (host == 'example.com' || host == 'via.placeholder.com') {
      return const AssetImage(_defaultBookCoverAsset);
    }
    return NetworkImage(p);
  }

  // Normalize possible `client/` prefix produced by server seed data
  String assetPath = p;
  if (assetPath.startsWith('client/')) {
    assetPath = assetPath.replaceFirst('client/', '');
  }

  if (assetPath.startsWith('./')) {
    assetPath = assetPath.substring(2);
  }

  if (assetPath.startsWith('/')) {
    assetPath = assetPath.substring(1);
  }

  final embeddedAssetsIndex = assetPath.indexOf('assets/');
  if (embeddedAssetsIndex > 0) {
    assetPath = assetPath.substring(embeddedAssetsIndex);
  }

  // If the path looks like a filename without assets/ prefix, try to prepend
  if (!assetPath.startsWith('assets/')) {
    assetPath = 'assets/book/$assetPath';
  }

  assetPath = assetPath.replaceAll('//', '/');

  if (assetPath == 'assets/person.webp') {
    return const AssetImage(_defaultProfileAsset);
  }

  return AssetImage(assetPath);
}

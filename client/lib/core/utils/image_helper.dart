import 'package:flutter/widgets.dart';

/// Returns a proper ImageProvider for the given [path].
///
/// - If [path] is an HTTP(S) URL, returns [NetworkImage].
/// - Otherwise treats it as an asset path and returns [AssetImage].
ImageProvider imageProviderFromPath(String? path) {
  final p = path ?? '';
  if (p.isEmpty) return const AssetImage('assets/placeholder.png');

  final uri = Uri.tryParse(p);
  if (uri != null && (uri.scheme == 'http' || uri.scheme == 'https')) {
    return NetworkImage(p);
  }

  // Normalize possible `client/` prefix produced by server seed data
  String assetPath = p;
  if (assetPath.startsWith('client/')) {
    assetPath = assetPath.replaceFirst('client/', '');
  }

  // If the path looks like a filename without assets/ prefix, try to prepend
  if (!assetPath.startsWith('assets/')) {
    assetPath = 'assets/book/$assetPath';
  }

  return AssetImage(assetPath);
}

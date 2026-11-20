import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

/// Album art that may be a local file path (on-device library) or an
/// http(s) URL (Discover / Jamendo). Network images are cached on disk.
class ArtImage extends StatelessWidget {
  final String path;
  final BoxFit fit;
  final Widget Function(BuildContext context) fallback;
  final Widget Function(BuildContext context)? placeholder;

  const ArtImage({
    super.key,
    required this.path,
    required this.fallback,
    this.placeholder,
    this.fit = BoxFit.cover,
  });

  static bool isRemote(String path) =>
      path.startsWith('http://') || path.startsWith('https://');

  /// Image provider for [path] (network or file).
  static ImageProvider provider(String path) => isRemote(path)
      ? CachedNetworkImageProvider(path)
      : FileImage(File(path)) as ImageProvider;

  @override
  Widget build(BuildContext context) {
    if (isRemote(path)) {
      return CachedNetworkImage(
        imageUrl: path,
        fit: fit,
        fadeInDuration: const Duration(milliseconds: 250),
        placeholder: (context, _) =>
            placeholder?.call(context) ?? fallback(context),
        errorWidget: (context, _, _) => fallback(context),
      );
    }
    return Image.file(
      File(path),
      fit: fit,
      errorBuilder: (context, error, stackTrace) => fallback(context),
    );
  }
}

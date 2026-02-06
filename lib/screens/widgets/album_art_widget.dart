import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:rhythmflow/core/theme/theme_extension.dart';

class AlbumArtWidget extends StatefulWidget {
  final String? albumArt;
  final double? width;
  final double? height;
  final double borderRadius;
  final List<BoxShadow>? boxShadow;
  final IconData defaultIcon;
  final double defaultIconSize;
  final bool isNetworkImage;

  const AlbumArtWidget({
    super.key,
    this.albumArt,
    this.width,
    this.height,
    required this.borderRadius,
    this.boxShadow,
    this.defaultIcon = Icons.music_note,
    this.isNetworkImage = false,
    double? defaultIconSize,
  }) : defaultIconSize = defaultIconSize ?? 32.0;

  @override
  State<AlbumArtWidget> createState() => _AlbumArtWidgetState();
}

class _AlbumArtWidgetState extends State<AlbumArtWidget> {
  bool _isLoading = true;
  bool _hasError = false;

  /// True when we have a non-null, non-empty path to show (treat empty string as no art).
  bool get _hasValidAlbumArt {
    final path = widget.albumArt;
    return path != null && path.trim().isNotEmpty;
  }

  @override
  void initState() {
    super.initState();
    _checkImageExists();
  }

  @override
  void didUpdateWidget(AlbumArtWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.albumArt != widget.albumArt) {
      _checkImageExists();
    }
  }

  Future<void> _checkImageExists() async {
    if (!_hasValidAlbumArt) {
      setState(() {
        _isLoading = false;
        _hasError = false;
      });
      return;
    }

    if (widget.isNetworkImage) {
      setState(() {
        _isLoading = false;
        _hasError = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      final file = File(widget.albumArt!);
      final exists = await file.exists();
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = !exists;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
        });
      }
    }
  }

  /// Icon size as ~50% of container so it scales with tile; capped for unbounded.
  double _iconSize(double containerSize) {
    final fromContainer = containerSize * 0.5;
    final fromDefault = math.min(widget.defaultIconSize.sp, 48.sp).toDouble();
    return containerSize.isFinite && containerSize > 0 ? fromContainer : fromDefault;
  }

  /// Classic padding ~12% of container for consistent spacing on all devices.
  double _classicPadding(double containerSize) {
    if (containerSize.isFinite && containerSize > 0) {
      return containerSize * 0.12;
    }
    return 8.r.toDouble();
  }

  Widget _buildPlaceholderContent({
    required double iconSize,
    required double padding,
    required Widget icon,
  }) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(padding),
        child: icon,
      ),
    );
  }

  Widget _buildDefaultAlbumArt(
    double iconSize,
    double padding, {
    double? effectiveWidth,
    double? effectiveHeight,
  }) {
    final w = widget.width ?? effectiveWidth;
    final h = widget.height ?? effectiveHeight;
    return Container(
      width: w,
      height: h,
      constraints: w != null && h != null && w > 0 && h > 0
          ? BoxConstraints(minWidth: w, maxWidth: w, minHeight: h, maxHeight: h)
          : null,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(widget.borderRadius),
        gradient: context.primaryGradient,
        boxShadow:
            widget.boxShadow ??
            [
              BoxShadow(
                color: context.isDark
                    ? Colors.black.withValues(alpha: 0.5)
                    : Colors.black.withValues(alpha: 0.2),
                blurRadius: 8.r,
                offset: Offset(0, 2.h),
              ),
            ],
      ),
      child: _buildPlaceholderContent(
        iconSize: iconSize,
        padding: padding,
        icon: Icon(
          widget.defaultIcon,
          size: iconSize,
          color: Colors.white.withValues(alpha: 0.9),
        ),
      ),
    );
  }

  /// Default album art (icon + gradient) for use in loading/error or when no art.
  /// [overrideWidth]/[overrideHeight] are used when placeholder is shown inside
  /// the image builder so it gets the same size as the image and avoids 0/infinite constraints.
  Widget _buildDefaultAlbumArtInline(
    double iconSize,
    double padding, {
    double? overrideWidth,
    double? overrideHeight,
  }) {
    final w = overrideWidth ?? widget.width;
    final h = overrideHeight ?? widget.height;
    final hasValidSize = w != null &&
        h != null &&
        w.isFinite &&
        h.isFinite &&
        w > 0 &&
        h > 0;
    final safeIconSize = (iconSize.isFinite && iconSize > 0)
        ? iconSize
        : math.min(widget.defaultIconSize.sp, 48.sp).toDouble();
    final safePadding = (padding.isFinite && padding >= 0) ? padding : 8.r.toDouble();

    return Container(
      width: w,
      height: h,
      constraints: hasValidSize
          ? BoxConstraints(
              minWidth: w,
              maxWidth: w,
              minHeight: h,
              maxHeight: h,
            )
          : null,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(widget.borderRadius),
        gradient: context.primaryGradient,
        boxShadow:
            widget.boxShadow ??
            [
              BoxShadow(
                color: context.isDark
                    ? Colors.black.withValues(alpha: 0.5)
                    : Colors.black.withValues(alpha: 0.2),
                blurRadius: 8.r,
                offset: Offset(0, 2.h),
              ),
            ],
      ),
      child: hasValidSize
          ? _buildPlaceholderContent(
              iconSize: safeIconSize,
              padding: safePadding,
              icon: Icon(
                widget.defaultIcon,
                size: safeIconSize,
                color: Colors.white.withValues(alpha: 0.9),
              ),
            )
          : null,
    );
  }

  Widget _buildImageWidget({double? effectiveWidth, double? effectiveHeight}) {
    final w = widget.width ?? effectiveWidth;
    final h = widget.height ?? effectiveHeight;
    final hasSize = w != null && h != null && w > 0 && h > 0;
    final minSide = hasSize ? math.min(w, h) : 0.0;
    final inlineIconSize = hasSize
        ? minSide * 0.5
        : math.min(widget.defaultIconSize.sp, 48.sp).toDouble();
    final inlinePadding = hasSize ? minSide * 0.12 : 8.r.toDouble();
    final double? width = w;
    final double? height = h;
    Widget placeholder() => _buildDefaultAlbumArtInline(
          inlineIconSize,
          inlinePadding,
          overrideWidth: w,
          overrideHeight: h,
        );
    return Container(
      width: w,
      height: h,
      constraints: hasSize && width != null && height != null
          ? BoxConstraints(
              minWidth: width,
              maxWidth: width,
              minHeight: height,
              maxHeight: height,
            )
          : null,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(widget.borderRadius),
        boxShadow:
            widget.boxShadow ??
            [
              BoxShadow(
                color: context.isDark
                    ? Colors.black.withValues(alpha: 0.5)
                    : Colors.black.withValues(alpha: 0.2),
                blurRadius: 8.r,
                offset: Offset(0, 2.h),
              ),
            ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(widget.borderRadius),
        child: SizedBox(
          width: w,
          height: h,
          child: widget.isNetworkImage
              ? Image.network(
                  widget.albumArt!,
                  width: w,
                  height: h,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return placeholder();
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return placeholder();
                  },
                )
              : Image.file(
                  File(widget.albumArt!),
                  width: w,
                  height: h,
                  fit: BoxFit.cover,
                  frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
                    if (frame == null) return placeholder();
                    return child;
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return placeholder();
                  },
                ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final fromConstraints = math.min(
          constraints.maxWidth.isFinite ? constraints.maxWidth : 0.0,
          constraints.maxHeight.isFinite ? constraints.maxHeight : 0.0,
        ).toDouble();
        final fromWidget = (widget.width != null &&
                widget.height != null &&
                widget.width!.isFinite &&
                widget.height!.isFinite)
            ? math.min(widget.width!, widget.height!).toDouble()
            : 0.0;
        final containerSize = fromWidget > 0 ? fromWidget : (fromConstraints > 0 ? fromConstraints : 0.0);
        final iconSize = _iconSize(containerSize);
        final padding = _classicPadding(containerSize);
        final effectiveWidth = constraints.maxWidth.isFinite && constraints.maxWidth > 0
            ? constraints.maxWidth
            : null;
        final effectiveHeight = constraints.maxHeight.isFinite && constraints.maxHeight > 0
            ? constraints.maxHeight
            : null;

        Widget content;
        Object switchKey;
        if (!_hasValidAlbumArt || _hasError || _isLoading) {
          content = _buildDefaultAlbumArt(
            iconSize,
            padding,
            effectiveWidth: effectiveWidth,
            effectiveHeight: effectiveHeight,
          );
          switchKey = 'default';
        } else {
          content = _buildImageWidget(
            effectiveWidth: effectiveWidth,
            effectiveHeight: effectiveHeight,
          );
          switchKey = widget.albumArt!;
        }

        return AnimatedSwitcher(
          duration: _transitionDuration,
          switchInCurve: _transitionCurve,
          switchOutCurve: _transitionCurve,
          transitionBuilder: (Widget child, Animation<double> animation) {
            return FadeTransition(
              opacity: animation,
              child: RepaintBoundary(child: child),
            );
          },
          child: KeyedSubtree(key: ValueKey(switchKey), child: content),
        );
      },
    );
  }

  static const Duration _transitionDuration = Duration(milliseconds: 300);
  static const Curve _transitionCurve = Curves.easeOut;
}

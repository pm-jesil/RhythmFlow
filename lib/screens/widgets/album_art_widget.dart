import 'dart:io';

import 'package:flutter/material.dart';
import 'art_image.dart';
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
  }) : defaultIconSize = defaultIconSize ?? 60.0;

  @override
  State<AlbumArtWidget> createState() => _AlbumArtWidgetState();
}

class _AlbumArtWidgetState extends State<AlbumArtWidget> {
  bool _isLoading = true;
  bool _hasError = false;

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

  /// URLs (Discover / Jamendo art) are network images even when the caller
  /// did not set [AlbumArtWidget.isNetworkImage].
  bool get _isRemote =>
      widget.isNetworkImage ||
      (widget.albumArt != null && ArtImage.isRemote(widget.albumArt!));

  Future<void> _checkImageExists() async {
    if (widget.albumArt == null) {
      setState(() {
        _isLoading = false;
        _hasError = false;
      });
      return;
    }

    if (_isRemote) {
      // For network images, we don't need to check existence
      // The loading and error states will be handled by the Image.network widget
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

  Widget _buildDefaultAlbumArt() {
    return Container(
      width: widget.width,
      height: widget.height,
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
      child: Icon(
        widget.defaultIcon,
        size: widget.defaultIconSize.sp,
        color: Colors.white.withValues(alpha: 0.8),
      ),
    );
  }

  Widget _buildLoadingWidget() {
    return Container(
      width: widget.width,
      height: widget.height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(widget.borderRadius),
        color: context.surfaceColor.withValues(alpha: 0.1),
        boxShadow:
            widget.boxShadow ??
            [
              BoxShadow(
                color: context.isDark
                    ? Colors.black.withValues(alpha: 0.3)
                    : Colors.black.withValues(alpha: 0.1),
                blurRadius: 4.r,
                offset: Offset(0, 1.h),
              ),
            ],
      ),
      child: Center(
        child: SizedBox(
          width: 24.w,
          height: 24.h,
          child: CircularProgressIndicator(
            strokeWidth: 2.w,
            valueColor: AlwaysStoppedAnimation<Color>(context.primaryStart),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Container(
      width: widget.width,
      height: widget.height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(widget.borderRadius),
        color: context.error.withValues(alpha: 0.1),
        boxShadow:
            widget.boxShadow ??
            [
              BoxShadow(
                color: context.isDark
                    ? Colors.black.withValues(alpha: 0.3)
                    : Colors.black.withValues(alpha: 0.1),
                blurRadius: 4.r,
                offset: Offset(0, 1.h),
              ),
            ],
      ),
      child: Icon(
        Icons.broken_image,
        size: widget.defaultIconSize.sp,
        color: context.error.withValues(alpha: 0.6),
      ),
    );
  }

  Widget _buildImageWidget() {
    return Container(
      width: widget.width,
      height: widget.height,
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
        child: _isRemote
            ? ArtImage(
                path: widget.albumArt!,
                placeholder: (_) => _buildLoadingWidget(),
                fallback: (_) => _buildErrorWidget(),
              )
            : ArtImage(
                path: widget.albumArt!,
                placeholder: (_) => _buildLoadingWidget(),
                fallback: (_) => _buildErrorWidget(),
              ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.albumArt == null || _hasError) {
      return _buildDefaultAlbumArt();
    } else if (_isLoading) {
      return _buildLoadingWidget();
    } else {
      return _buildImageWidget();
    }
  }
}

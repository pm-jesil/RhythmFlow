import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class CustomScrollingText extends StatefulWidget {
  final String text;
  final FontWeight? fontWeight;
  final double? fontSize;
  final Color? color;
  final TextAlign textAlign;
  final double? cardWidth;
  final double? height;
  final bool isTitleScrolling;

  const CustomScrollingText({
    super.key,
    required this.text,
    this.fontWeight,
    this.fontSize,
    this.color,
    this.textAlign = TextAlign.left,
    this.cardWidth,
    this.height,
    this.isTitleScrolling = false,
  });

  @override
  State<CustomScrollingText> createState() => _CustomScrollingTextState();
}

class _CustomScrollingTextState extends State<CustomScrollingText>
    with TickerProviderStateMixin {
  bool _isDisposed = false;
  late AnimationController _scrollController;
  late Animation<double> _scrollAnimation;
  bool _isScrolling = false;

  @override
  void initState() {
    super.initState();
    _scrollController = AnimationController(
      duration: const Duration(seconds: 10), // Adjust duration as needed
      vsync: this,
    );
    _scrollAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _scrollController, curve: Curves.linear),
    );
  }

  @override
  void dispose() {
    _isDisposed = true;
    _scrollController.dispose();
    super.dispose();
  }

  void _startScrolling() {
    if (!_isDisposed && mounted && !_isScrolling) {
      _isScrolling = true;
      _scrollController.forward().then((_) {
        if (!_isDisposed && mounted) {
          _scrollController.reverse().then((_) {
            if (!_isDisposed && mounted) {
              _isScrolling = false;
              // Restart scrolling after a pause
              Future.delayed(const Duration(milliseconds: 1000), () {
                if (!_isDisposed && mounted) {
                  _startScrolling();
                }
              });
            }
          });
        }
      });
    }
  }


  /// Helper function to determine if text needs scrolling
  static bool shouldScrollText({
    required String text,
    required BuildContext context,
    FontWeight? fontWeight,
    double? fontSize,
    Color? color,
    double? cardWidth,
  }) {
    if (text.isEmpty) return false;

    // Create a TextPainter to measure the text with exact same style as displayed
    final textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          fontWeight: fontWeight ?? FontWeight.bold,
          fontSize: fontSize ?? 12.sp,
          color: color ?? Theme.of(context).colorScheme.onSurface,
          fontFamily: 'Poppins',
        ),
      ),
      textDirection: TextDirection.ltr,
      maxLines: 1, // Single line measurement
    );

    textPainter.layout(maxWidth: double.infinity);

    // Calculate available width - use provided cardWidth or default
    final availableWidth = cardWidth ?? 140.w - 16.w; // Subtract internal padding

    // Return true if text width exceeds available width
    return textPainter.width > availableWidth;
  }

  @override
  Widget build(BuildContext context) {
    // Create TextStyle from individual parameters
    final textStyle = TextStyle(
      fontWeight: widget.fontWeight ?? FontWeight.bold,
      fontSize: widget.fontSize ?? 12.sp,
      color: widget.color ?? Theme.of(context).colorScheme.onSurface,
      fontFamily: 'Poppins',
      height: 1.2,
    );

    // If disposed, return regular text
    if (_isDisposed) {
      return Text(
        widget.text,
        style: textStyle,
        textAlign: widget.textAlign,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      );
    }


    // Check if text needs scrolling based on length
    bool shouldScroll = shouldScrollText(
      text: widget.text,
      context: context,
      fontWeight: widget.fontWeight,
      fontSize: widget.fontSize,
      color: widget.color,
      cardWidth: widget.cardWidth,
    );

    // If isTitleScrolling is false or text doesn't need scrolling, show regular text
    if (!widget.isTitleScrolling || !shouldScroll) {
      return Text(
        widget.text,
        style: textStyle,
        textAlign: widget.textAlign,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      );
    }

    return SizedBox(
      height: widget.height ?? 20.h,
      child: _buildCustomScrollingText(textStyle),
    );
  }

  Widget _buildCustomScrollingText(TextStyle textStyle) {
    if (_isDisposed || !mounted) {
      return Text(
        widget.text,
        style: textStyle,
        textAlign: widget.textAlign,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      );
    }

    // Start scrolling animation
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_isDisposed && mounted) {
        _startScrolling();
      }
    });

    return AnimatedBuilder(
      animation: _scrollAnimation,
      builder: (context, child) {
        if (_isDisposed || !mounted) {
          return Text(
            widget.text,
            style: textStyle,
            textAlign: widget.textAlign,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          );
        }

        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const NeverScrollableScrollPhysics(),
          child: Transform.translate(
            offset: Offset(-_scrollAnimation.value * 100, 0),
            child: Text(
              widget.text,
              style: textStyle,
              textAlign: widget.textAlign,
            ),
          ),
        );
      },
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../theme/theme_extension.dart';

class CustomTabViewAppBar extends StatefulWidget
    implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final bool showSortButton;
  final bool showSearchButton;
  final bool showSettingsButton;
  final VoidCallback? onSettingsPressed;
  final VoidCallback? onSortPressed;
  final VoidCallback? onSearchPressed;
  final Widget? leading;
  final ScrollController? scrollController;
  final bool isRequiredHideAppBar;

  const CustomTabViewAppBar({
    super.key,
    required this.title,
    this.actions,
    this.showSortButton = false,
    this.showSearchButton = true,
    this.showSettingsButton = false,
    this.onSettingsPressed,
    this.onSortPressed,
    this.onSearchPressed,
    this.leading,
    this.scrollController,
    this.isRequiredHideAppBar = true,
  });

  @override
  State<CustomTabViewAppBar> createState() => _CustomTabViewAppBarState();

  @override
  Size get preferredSize => Size.fromHeight(80.h);
}

class _CustomTabViewAppBarState extends State<CustomTabViewAppBar>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late AnimationController _searchAnimationController;
  late Animation<double> _searchSlideAnimation;
  late TextEditingController _searchController;
  late FocusNode _searchFocusNode;
  bool _isVisible = true;
  double _lastScrollPosition = 0.0;
  bool _isSearchPressed = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _searchAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _searchSlideAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _searchAnimationController,
        curve: Curves.easeInOut,
      ),
    );

    _searchController = TextEditingController();
    _searchFocusNode = FocusNode();

    // Listen to focus changes for better UI updates
    _searchFocusNode.addListener(() {
      setState(() {}); // Trigger rebuild for focus state
    });

    // Listen to scroll changes if scrollController is provided
    if (widget.scrollController != null) {
      widget.scrollController!.addListener(_onScroll);
    }
  }

  @override
  void dispose() {
    if (widget.scrollController != null) {
      widget.scrollController!.removeListener(_onScroll);
    }
    _animationController.dispose();
    _searchAnimationController.dispose();
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (widget.scrollController == null || !widget.isRequiredHideAppBar) return;

    final currentScrollPosition = widget.scrollController!.offset;
    final scrollDelta = currentScrollPosition - _lastScrollPosition;

    // Only trigger if scroll delta is significant to prevent jitter
    if (scrollDelta.abs() < 2) return;

    // Immediate response for better sync with scroll speed
    if (scrollDelta > 5 && _isVisible && currentScrollPosition > 30) {
      // Scrolling down - hide app bar (reduced threshold for faster response)
      _hideAppBar();
    } else if (scrollDelta < -5 && !_isVisible) {
      onSearchClose();
      // Scrolling up - show app bar (reduced threshold for faster response)
      _showAppBar();
    }

    _lastScrollPosition = currentScrollPosition;
  }

  void _hideAppBar() {
    if (!_isVisible) return;
    setState(() {
      _isVisible = false;
    });
    _animationController.reverse();
  }

  void _showAppBar() {
    if (_isVisible) return;
    setState(() {
      _isVisible = true;
    });
    _animationController.forward();
  }

  void onSearchPressed() {
    setState(() => _isSearchPressed = true);
    _searchAnimationController.forward();
    // Focus the search field after animation starts
    Future.delayed(const Duration(milliseconds: 150), () {
      if (mounted) {
        _searchFocusNode.requestFocus();
      }
    });
    widget.onSearchPressed?.call();
  }

  void onSearchClose() {
    setState(() => _isSearchPressed = false);
    _searchAnimationController.reverse();
    _searchController.clear();
    _searchFocusNode.unfocus();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        height: (_isVisible || !widget.isRequiredHideAppBar) ? 66.h : 0,
        decoration: const BoxDecoration(color: Colors.transparent),
        child: ClipRect(
          child: Container(
            height: kToolbarHeight + MediaQuery.of(context).padding.top,
            decoration: const BoxDecoration(color: Colors.transparent),
            child: SafeArea(
              child: Padding(
                padding: EdgeInsets.only(left: 16.w, right: 16.w, top: 10.h),
                child: Stack(
                  children: [
                    // Normal app bar content
                    AnimatedOpacity(
                      opacity: _isSearchPressed ? 0.0 : 1.0,
                      duration: const Duration(milliseconds: 200),
                      child: Row(
                        children: [
                          // Leading widget
                          if (widget.leading != null) widget.leading!,

                          // Title
                          Expanded(
                            child: Text(
                              widget.title,
                              style: TextStyle(
                                color: context.onSurfaceColor,
                                fontWeight: FontWeight.w600,
                                fontSize: 20.sp,
                                letterSpacing: 0.2,
                              ),
                            ),
                          ),

                          // Actions
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Search Icon
                              if (widget.showSearchButton)
                                _buildActionButton(
                                  context: context,
                                  icon: Icons.search_rounded,
                                  onPressed: onSearchPressed,
                                ),

                              // Custom actions
                              if (widget.actions != null) ...widget.actions!,

                              // Spacing
                              if (widget.actions != null ||
                                  widget.showSortButton)
                                SizedBox(width: 4.w),

                              // Sort button (if enabled)
                              if (widget.showSortButton)
                                _buildActionButton(
                                  context: context,
                                  icon: Icons.sort_rounded,
                                  onPressed: widget.onSortPressed!,
                                ),

                              if (widget.showSettingsButton)
                                _buildActionButton(
                                  context: context,
                                  icon: Icons.settings_rounded,
                                  onPressed: widget.onSettingsPressed!,
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Search field
                    AnimatedBuilder(
                      animation: _searchSlideAnimation,
                      builder: (context, child) {
                        return Transform.translate(
                          offset: Offset(
                            MediaQuery.of(context).size.width *
                                _searchSlideAnimation.value,
                            0,
                          ),
                          child: SizedBox(
                            width: double.infinity,
                            child: Row(
                              children: [
                                // Back/Close button
                                _buildActionButton(
                                  context: context,
                                  icon: Icons.arrow_forward_ios_rounded,
                                  onPressed: onSearchClose,
                                ),

                                SizedBox(width: 8.w),

                                // Search field
                                _buildSearchWidget(context),

                                SizedBox(width: 8.w),

                                // Clear button
                                if (_searchController.text.isNotEmpty)
                                  _buildActionButton(
                                    context: context,
                                    icon: Icons.close_rounded,
                                    onPressed: () {
                                      _searchController.clear();
                                      setState(() {});
                                      widget.onSearchPressed?.call();
                                    },
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  IconButton _buildActionButton({
    required BuildContext context,
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return IconButton(
      onPressed: onPressed,
      icon: Icon(icon, color: context.onSurfaceVariantColor, size: 18.sp),
      style: IconButton.styleFrom(
        backgroundColor: context.onSurfaceVariantColor.withValues(alpha: 0.1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.r),
        ),
        padding: EdgeInsets.all(4.w),
      ),
    );
  }

  Expanded _buildSearchWidget(BuildContext context) {
    return Expanded(
      child: Container(
        decoration: BoxDecoration(
          color: context.onSurfaceVariantColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
            color: _searchFocusNode.hasFocus
                ? context.primaryStart.withValues(alpha: 0.3)
                : Colors.transparent,
            width: 1.0,
          ),
        ),
        child: TextField(
          controller: _searchController,
          focusNode: _searchFocusNode,
          style: TextStyle(
            color: context.onSurfaceColor,
            fontSize: 16.sp,
            fontWeight: FontWeight.w400,
          ),
          decoration: InputDecoration(
            hintText: 'Search...',
            hintStyle: TextStyle(
              color: context.onSurfaceVariantColor.withValues(alpha: 0.6),
              fontSize: 16.sp,
              fontWeight: FontWeight.w400,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: BorderSide.none,
            ),
            contentPadding: EdgeInsets.symmetric(
              vertical: 8.h,
              horizontal: 12.w,
            ),
            isDense: true,
          ),
          cursorColor: context.primaryStart,
          onChanged: (value) {
            // Handle search text changes
            setState(() {}); // Trigger rebuild for clear button
            widget.onSearchPressed?.call();
          },
        ),
      ),
    );
  }
}

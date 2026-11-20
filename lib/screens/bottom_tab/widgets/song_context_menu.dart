import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../core/theme/theme_extension.dart';
import '../../../utils/logger/logger.dart';

class SongContextMenu extends StatefulWidget {
  final String songTitle;
  final String artistName;
  final String albumName;
  final String songId;
  final Offset position;
  final Size size;
  final Function(String action, String songId, String songTitle, String artistName, String albumName)? onMenuAction;

  const SongContextMenu({
    super.key,
    required this.songTitle,
    required this.artistName,
    required this.albumName,
    required this.songId,
    required this.position,
    required this.size,
    this.onMenuAction,
  });

  @override
  State<SongContextMenu> createState() => _SongContextMenuState();
}

class _SongContextMenuState extends State<SongContextMenu>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;
  final AppLogger _logger = AppLogger('SongContextMenu');

  static const List<Map<String, dynamic>> _menuItems = [
    {'icon': Icons.share, 'title': 'Share Song', 'action': 'share', 'color': 'primary'},
    {'icon': Icons.info_outline, 'title': 'View Song Info', 'action': 'info', 'color': 'primary'},
    {'icon': Icons.playlist_add, 'title': 'Add to Playlist', 'action': 'playlist', 'color': 'primary'},
    {'icon': Icons.notifications_active_outlined, 'title': 'Make Ringtone', 'action': 'ringtone', 'color': 'primary'},
    {'icon': Icons.album, 'title': 'Go to Album', 'action': 'album', 'color': 'primary'},
    {'icon': Icons.person, 'title': 'Go to Artist', 'action': 'artist', 'color': 'primary'},
    {'icon': Icons.delete_outline, 'title': 'Delete', 'action': 'delete', 'color': 'error'},
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final menuWidth = 200.0;
    final menuHeight = 256.0; // 7 items

    double left = widget.position.dx + (widget.size.width / 2) - (menuWidth / 2);
    double top = widget.position.dy - menuHeight - 8;
    if (top < 0) {
      top = widget.position.dy + widget.size.height + 8;
    }

    return Material(
      color: Colors.transparent,
      child: Stack(
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              width: double.infinity,
              height: double.infinity,
              color: Colors.transparent,
            ),
          ),
          Positioned(
            left: left,
            top: top,
            child: AnimatedBuilder(
              animation: _animationController,
              builder: (context, child) {
                return Transform.scale(
                  scale: _scaleAnimation.value,
                  child: Opacity(
                    opacity: _opacityAnimation.value,
                    child: Container(
                      width: menuWidth,
                      decoration: BoxDecoration(
                        color: context.surfaceColor,
                        borderRadius: BorderRadius.circular(16.r),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.2),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 8.h),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: _menuItems
                              .map((item) => _buildMenuItem(
                                    icon: item['icon'] as IconData,
                                    title: item['title'] as String,
                                    color: _getItemColor(context, item['color'] as String),
                                    onTap: () => _handleMenuAction(item['action'] as String),
                                  ))
                              .toList(),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Color _getItemColor(BuildContext context, String colorType) {
    switch (colorType) {
      case 'error':
        return context.error;
      case 'primary':
      default:
        return context.primaryStart;
    }
  }

  void _handleMenuAction(String action) {
    _logger.i('🎯 Menu action: $action for ${widget.songTitle}');
    
    // Close the menu first
    Navigator.of(context).pop();
    
    // Execute action via callback if available
    if (widget.onMenuAction != null) {
      widget.onMenuAction!(
        action,
        widget.songId,
        widget.songTitle,
        widget.artistName,
        widget.albumName,
      );
    }
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
          child: Row(
            children: [
              Icon(icon, color: color, size: 20.sp),
              SizedBox(width: 12.w),
              Flexible(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: context.onSurfaceColor,
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
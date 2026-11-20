import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:liquid_glass_renderer/liquid_glass_renderer.dart';

import '../../core/theme/theme_extension.dart';
import '../app_settings/bloc/app_settings_bloc.dart';

/// Labels of the two music sources.
class MusicSourceLabels {
  MusicSourceLabels._();
  static const String local = 'My Music';
  static const String online = 'Discover';
}

/// Compact "My Music | Discover" toggle shown under the greeting card.
///
/// Styled like the bottom tab bar (glass background, thin border, soft
/// shadow, gradient pill on the selected item) but much lower.
class MusicSourceSwitch extends StatelessWidget {
  const MusicSourceSwitch({super.key, this.height});

  final double? height;

  @override
  Widget build(BuildContext context) {
    final isOnline = context.select<AppSettingsBloc, bool>(
      (bloc) => bloc.state.isOnlineSource,
    );
    final h = height ?? 38.h;
    final radius = h / 2;

    void select(String source) {
      if ((source == MusicSourceKeys.online) == isOnline) return;
      HapticFeedback.lightImpact();
      context.read<AppSettingsBloc>().add(
        AppSettingsEvent.updateMusicSource(source: source),
      );
    }

    return Semantics(
      container: true,
      label: 'Music source',
      child: Container(
        height: h,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(radius),
          boxShadow: [
            BoxShadow(
              color: context.isDark
                  ? Colors.black.withValues(alpha: 0.2)
                  : context.onSurfaceColor.withValues(alpha: 0.08),
              blurRadius: 8.r,
              offset: Offset(0, 3.h),
            ),
          ],
          border: Border.all(
            color: context.onSurfaceColor.withValues(alpha: 0.1),
            width: 0.5.w,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(radius),
          child: LiquidGlass(
            shape: LiquidRoundedSuperellipse(
              side: BorderSide.none,
              borderRadius: Radius.circular(radius),
            ),
            settings: LiquidGlassSettings(
              thickness: 10.0,
              blur: 3.r,
              glassColor: context.isDark
                  ? const Color.fromARGB(38, 255, 255, 255)
                  : const Color.fromARGB(59, 26, 25, 25),
            ),
            glassContainsChild: false,
            child: Padding(
              padding: EdgeInsets.all(3.r),
              child: Stack(
                children: [
                  // Sliding gradient pill.
                  AnimatedAlign(
                    duration: const Duration(milliseconds: 260),
                    curve: Curves.easeInOutCubic,
                    alignment: isOnline
                        ? Alignment.centerRight
                        : Alignment.centerLeft,
                    child: FractionallySizedBox(
                      widthFactor: 0.5,
                      heightFactor: 1,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: context.primaryGradient,
                          borderRadius: BorderRadius.circular(radius),
                          boxShadow: [
                            BoxShadow(
                              color: context.primaryStart.withValues(alpha: 0.35),
                              blurRadius: 8.r,
                              offset: Offset(0, 2.h),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      _Segment(
                        key: const ValueKey('source_local'),
                        label: MusicSourceLabels.local,
                        icon: CupertinoIcons.music_albums,
                        selected: !isOnline,
                        onTap: () => select(MusicSourceKeys.local),
                      ),
                      _Segment(
                        key: const ValueKey('source_online'),
                        label: MusicSourceLabels.online,
                        icon: CupertinoIcons.globe,
                        selected: isOnline,
                        onTap: () => select(MusicSourceKeys.online),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Segment extends StatelessWidget {
  const _Segment({
    super.key,
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected
        ? Colors.white
        : context.onSurfaceColor.withValues(alpha: 0.7);
    return Expanded(
      child: Semantics(
        button: true,
        selected: selected,
        label: label,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: Center(
            child: AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: TextStyle(
                color: color,
                fontSize: 12.sp,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                letterSpacing: 0.4,
                fontFamily: 'Poppins',
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedScale(
                    duration: const Duration(milliseconds: 200),
                    scale: selected ? 1.0 : 0.92,
                    child: Icon(icon, size: 16.sp, color: color),
                  ),
                  SizedBox(width: 6.w),
                  Text(label),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

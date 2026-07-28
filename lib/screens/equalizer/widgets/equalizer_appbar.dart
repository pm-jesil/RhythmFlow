import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:just_audio/just_audio.dart';
import 'package:rhythmflow/core/theme/theme_extension.dart';
import 'package:rhythmflow/screens/equalizer/widgets/equalizer_hero_tags.dart';

// ── Combined top-bar ──────────────────────────────────────────────────────────

/// Full top-bar for the Equalizer screen.
/// Cross-fades and slides between [EqualizerAppBar] and [EqualizerActionBar]
/// (single animation driver — [EqualizerActionBar] has no inner slide).
class EqualizerTopBar extends StatelessWidget {
  const EqualizerTopBar({
    super.key,
    this.eq,
    required this.onBack,
    this.onAddPreset,
    required this.showActionBar,
    required this.hasPendingSave,
    required this.currentPresetModified,
    required this.isCustomPreset,
    required this.onConfirmSelection,
    required this.onUndo,
    required this.onUpdate,
  });

  final AndroidEqualizer? eq;
  final VoidCallback onBack;
  final VoidCallback? onAddPreset;

  /// Whether the action bar (Undo / Save / Save as New / Update) should be
  /// shown instead of
  /// the normal app bar. Pass `eq != null && (hasPendingSave || modified)`.
  final bool showActionBar;
  final bool hasPendingSave;
  final bool currentPresetModified;
  final bool isCustomPreset;
  final VoidCallback onConfirmSelection;
  final VoidCallback onUndo;
  final VoidCallback onUpdate;

  /// Top-bar height — delegates to the shared [EqualizerHeroTags.topBarHeight].
  static double heightFor(BuildContext context) =>
      EqualizerHeroTags.topBarHeight(context);

  @override
  Widget build(BuildContext context) {
    final barHeight = heightFor(context);
    const curve = Curves.easeOutCubic;
    return SizedBox(
      height: barHeight,
      child: ClipRect(
        child: Stack(
          fit: StackFit.expand,
          clipBehavior: Clip.hardEdge,
          children: [
            // Normal app bar — slides out when action mode is active.
            AnimatedSlide(
              duration: EqualizerHeroTags.topBarSwitchDuration,
              curve: curve,
              offset: showActionBar ? const Offset(0, -1) : Offset.zero,
              child: AnimatedOpacity(
                duration: EqualizerHeroTags.topBarFadeDuration,
                curve: Curves.easeOut,
                opacity: showActionBar ? 0.0 : 1.0,
                child: IgnorePointer(
                  ignoring: showActionBar,
                  child: HeroMode(
                    enabled: !showActionBar,
                    child: EqualizerAppBar(
                      eq: eq,
                      onBack: onBack,
                      onAddPreset: onAddPreset,
                    ),
                  ),
                ),
              ),
            ),
            // Action bar — slides in when action mode is active.
            AnimatedSlide(
              duration: EqualizerHeroTags.topBarSwitchDuration,
              curve: curve,
              offset: showActionBar ? Offset.zero : const Offset(0, -1),
              child: AnimatedOpacity(
                duration: EqualizerHeroTags.topBarFadeDuration,
                curve: Curves.easeOut,
                opacity: showActionBar ? 1.0 : 0.0,
                child: IgnorePointer(
                  ignoring: !showActionBar,
                  child: HeroMode(
                    enabled: showActionBar,
                    child: EqualizerActionBar(
                      hasPendingSave: hasPendingSave,
                      currentPresetModified: currentPresetModified,
                      isCustomPreset: isCustomPreset,
                      onConfirmSelection: onConfirmSelection,
                      onUndo: onUndo,
                      onUpdate: onUpdate,
                      barHeight: barHeight,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── App Bar ───────────────────────────────────────────────────────────────────

/// Normal Equalizer app bar: back button + title + optional add-preset button.
/// Also used directly as `appBar:` on the iOS placeholder scaffold, hence
/// still implements [PreferredSizeWidget].
class EqualizerAppBar extends StatelessWidget implements PreferredSizeWidget {
  const EqualizerAppBar({
    super.key,
    this.eq,
    required this.onBack,
    this.onAddPreset,
  });

  final AndroidEqualizer? eq;
  final VoidCallback onBack;
  final VoidCallback? onAddPreset;

  @override
  Size get preferredSize => const Size.fromHeight(60);

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.sizeOf(context).height;
    final toolbarHeight = (screenHeight * 0.095).clamp(54.r, 66.r);
    return AppBar(
      toolbarHeight: toolbarHeight,
      title: Hero(
        tag: EqualizerHeroTags.title,
        child: Material(
          type: MaterialType.transparency,
          child: Text(
            'Equalizer',
            style: TextStyle(
              color: context.onSurfaceColor,
              fontSize: 8.5.sp,
              fontWeight: FontWeight.w600,
              fontFamily: 'Poppins',
            ),
          ),
        ),
      ),
      backgroundColor: context.backgroundColor,
      elevation: 0,
      centerTitle: true,
      leading: Hero(
        tag: EqualizerHeroTags.backButton,
        child: Material(
          type: MaterialType.transparency,
          child: IconButton(
            icon: Icon(
              CupertinoIcons.back,
              color: context.onSurfaceColor,
              size: 10.sp,
            ),
            iconSize: 15.r,
            padding: EdgeInsets.symmetric(horizontal: 14.r, vertical: 8.r),
            style: IconButton.styleFrom(
              minimumSize: Size(44.r, 44.r),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              visualDensity: VisualDensity.standard,
            ),
            onPressed: onBack,
          ),
        ),
      ),
      actions: [
        if (eq != null && onAddPreset != null) _buildAddButton(context),
      ],
    );
  }

  Widget _buildAddButton(BuildContext context) {
    return Hero(
      tag: EqualizerHeroTags.addButton,
      child: Material(
        type: MaterialType.transparency,
        child: IconButton(
          icon: Icon(
            CupertinoIcons.add,
            color: context.primaryStart,
            size: 10.sp,
          ),
          iconSize: 15.r,
          padding: EdgeInsets.symmetric(horizontal: 14.r, vertical: 8.r),
          style: IconButton.styleFrom(
            minimumSize: Size(52.r, 52.r),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            visualDensity: VisualDensity.standard,
          ),
          onPressed: onAddPreset,
          tooltip: 'Add preset',
        ),
      ),
    );
  }
}

// ── Action Bar ────────────────────────────────────────────────────────────────

/// Slides down into the top-bar area when there are pending preset changes.
/// Contains an Undo button and the primary Save / Save as New / Update button.
class EqualizerActionBar extends StatelessWidget {
  const EqualizerActionBar({
    super.key,
    required this.hasPendingSave,
    required this.currentPresetModified,
    required this.isCustomPreset,
    required this.onConfirmSelection,
    required this.onUndo,
    required this.onUpdate,
    this.barHeight,
  });

  final bool hasPendingSave;
  final bool currentPresetModified;
  final bool isCustomPreset;
  final VoidCallback onConfirmSelection;
  final VoidCallback onUndo;
  final VoidCallback onUpdate;
  final double? barHeight;

  static String primaryLabelFor({
    required bool currentPresetModified,
    required bool isCustomPreset,
  }) {
    if (currentPresetModified) {
      return isCustomPreset ? 'Update' : 'Save as new';
    }
    return 'Save';
  }

  String get _primaryLabel {
    return primaryLabelFor(
      currentPresetModified: currentPresetModified,
      isCustomPreset: isCustomPreset,
    );
  }

  VoidCallback _primaryAction() {
    if (currentPresetModified) {
      return () {
        HapticFeedback.mediumImpact();
        onUpdate();
      };
    }
    return () {
      HapticFeedback.mediumImpact();
      onConfirmSelection();
    };
  }

  @override
  Widget build(BuildContext context) {
    final compact = barHeight != null && barHeight! < 58.r;
    final hPad = compact ? 14.r : 18.r;
    final vPad = compact ? 5.r : 7.r;
    final btnVPad = compact ? 4.r : 6.r;
    final radius = compact ? 8.r : 10.r;
    final gap = compact ? 6.r : 8.r;
    final fontSize = compact ? 7.sp : 8.sp;
    final minH = compact ? 22.r : 26.r;

    return SizedBox(
      height: barHeight,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: hPad, vertical: vPad),
        decoration: BoxDecoration(
          color: context.backgroundColor.withValues(alpha: 0.97),
          border: Border(
            bottom: BorderSide(
              color: context.primaryStart.withValues(alpha: 0.14),
              width: 1,
            ),
          ),
          boxShadow: [
            BoxShadow(
              color: context.primaryStart.withValues(alpha: 0.07),
              blurRadius: 12.r,
              offset: Offset(0, 4.r),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              flex: 40,
              child: Hero(
                tag: EqualizerHeroTags.actionUndoButton,
                child: Material(
                  type: MaterialType.transparency,
                  child: OutlinedButton(
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      onUndo();
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: context.onSurfaceVariantColor,
                      side: BorderSide(
                        color: context.primaryStart.withValues(alpha: 0.4),
                        width: 1.0,
                      ),
                      padding: EdgeInsets.symmetric(vertical: btnVPad),
                      minimumSize: Size.fromHeight(minH),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(radius),
                      ),
                    ),
                    child: Text(
                      'Undo',
                      style: TextStyle(
                        fontSize: fontSize,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(width: gap),
            Expanded(
              flex: 60,
              child: Hero(
                tag: EqualizerHeroTags.actionPrimaryButton,
                child: Material(
                  type: MaterialType.transparency,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [context.primaryStart, context.primaryEnd],
                      ),
                      borderRadius: BorderRadius.circular(radius),
                      boxShadow: [
                        BoxShadow(
                          color: context.primaryStart.withValues(alpha: 0.28),
                          blurRadius: 8.r,
                          offset: Offset(0, 3.r),
                        ),
                      ],
                    ),
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 220),
                      switchInCurve: Curves.easeOutCubic,
                      switchOutCurve: Curves.easeInCubic,
                      transitionBuilder: (child, anim) => FadeTransition(
                        opacity: anim,
                        child: child,
                      ),
                      child: FilledButton(
                        key: ValueKey(_primaryLabel),
                        onPressed: _primaryAction(),
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(vertical: btnVPad),
                          minimumSize: Size.fromHeight(minH),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(radius),
                          ),
                        ),
                        child: Text(
                          _primaryLabel,
                          style: TextStyle(
                            fontSize: fontSize,
                            fontWeight: FontWeight.w700,
                            fontFamily: 'Poppins',
                            letterSpacing: 0.3,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

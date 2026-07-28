import 'package:flutter/widgets.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Shared [Hero] tags and layout constants for equalizer portrait ↔ landscape
/// transitions. Both [EqualizerTopBar] and [EqualizerPortraitTransitionShell]
/// import this file so they stay in sync.
class EqualizerHeroTags {
  EqualizerHeroTags._();

  // ── Hero tags ──────────────────────────────────────────────────────────────
  static const backButton = 'equalizer/back-button';
  static const title = 'equalizer/title';
  static const addButton = 'equalizer/add-button';
  static const actionUndoButton = 'equalizer/action-undo-button';
  static const actionPrimaryButton = 'equalizer/action-primary-button';
  static const sectionHeader = 'equalizer/section-header';
  static const slidersCard = 'equalizer/sliders-card';
  static const bottomRow = 'equalizer/bottom-row';

  // ── Shared animation durations (kept in sync between EqualizerTopBar and shell) ──
  static const topBarSwitchDuration = Duration(milliseconds: 300);
  static const topBarFadeDuration = Duration(milliseconds: 240);

  /// Top-bar height used by the landscape screen and the portrait shell.
  static double topBarHeight(BuildContext context) {
    final h = MediaQuery.sizeOf(context).height;
    return (h * 0.095).clamp(54.r, 66.r);
  }
}

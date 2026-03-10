import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:just_audio/just_audio.dart';
import 'package:rhythmflow/core/constants/app_constants.dart';
import 'package:rhythmflow/core/theme/theme_extension.dart';
import 'package:rhythmflow/screens/equalizer/widgets/master_volume_knob.dart';
import 'package:rhythmflow/screens/equalizer/bloc/equalizer_bloc.dart';

// ── Bottom row: L volume knob | Presets + Reverb chips | R volume knob ───────

class EqualizerBottomKnobRow extends StatefulWidget {
  const EqualizerBottomKnobRow({
    super.key,
    required this.eq,
    required this.state,
    required this.height,
    required this.volumeLeft,
    required this.volumeRight,
    required this.onVolumeLeftChanged,
    required this.onVolumeRightChanged,
    required this.selectedPresetId,
    this.presetRemoving,
    required this.onPresetSelected,
    this.onPresetDeleteRequested,
    required this.onReverbSelected,
  });

  final AndroidEqualizer eq;
  final EqualizerState state;
  final double height;
  final double volumeLeft;
  final double volumeRight;
  final ValueChanged<double> onVolumeLeftChanged;
  final ValueChanged<double> onVolumeRightChanged;
  final String selectedPresetId;
  final ({String id, String name, List<double> gains})? presetRemoving;
  final void Function(String id, String name, List<double> gains)
  onPresetSelected;
  final void Function(String id, String name, List<double> gains)?
  onPresetDeleteRequested;
  final Future<void> Function(int presetId) onReverbSelected;

  @override
  State<EqualizerBottomKnobRow> createState() => _EqualizerBottomKnobRowState();
}

class _EqualizerBottomKnobRowState extends State<EqualizerBottomKnobRow> {
  final ScrollController _presetScroll = ScrollController();
  final ScrollController _reverbScroll = ScrollController();

  // Keep chip keys so we can measure their positions for auto-scroll
  final Map<String, GlobalKey> _chipKeys = {};

  @override
  void dispose() {
    _presetScroll.dispose();
    _reverbScroll.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant EqualizerBottomKnobRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedPresetId != widget.selectedPresetId) {
      _scrollToSelected(widget.selectedPresetId);
    }
  }

  void _scrollToSelected(String id) {
    final key = _chipKeys[id];
    if (key == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctx = key.currentContext;
      if (ctx == null) return;
      Scrollable.ensureVisible(
        ctx,
        alignment: 0.3,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOutCubic,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final chipRowHeight = (widget.height * 0.45).clamp(28.r, 35.h);
    return SizedBox(
      height: widget.height,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.only(top: 15.w),
            height: widget.height,
            width: 70.w,
            child: MasterVolumeKnob(
              label: 'L',
              value: widget.volumeLeft,
              compact: true,
              onChanged: widget.onVolumeLeftChanged,
            ),
          ),
          Expanded(
            child: Container(
              height: double.infinity,
              padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    context.surfaceColor.withValues(alpha: 0.7),
                    context.surfaceColor.withValues(alpha: 0.5),
                  ],
                ),
                borderRadius: BorderRadius.circular(10.r),
                border: Border.all(
                  color: context.primaryStart.withValues(
                    alpha: context.isDark ? 0.28 : 0.18,
                  ),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: context.primaryStart.withValues(
                      alpha: context.isDark ? 0.08 : 0.04,
                    ),
                    blurRadius: 8.r,
                    offset: Offset(0, 2.h),
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildPresetsCompact(context, chipRowHeight),
                  if (Platform.isAndroid)
                    _buildReverbCompact(context, chipRowHeight),
                ],
              ),
            ),
          ),
          Container(
            padding: EdgeInsets.only(top: 15.w),
            height: widget.height,
            width: 70.w,
            child: MasterVolumeKnob(
              label: 'R',
              value: widget.volumeRight,
              compact: true,
              onChanged: widget.onVolumeRightChanged,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChipSectionLabel(
    BuildContext context,
    String label,
    IconData icon,
  ) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 7.sp, color: context.primaryStart),
        SizedBox(width: 2.w),
        Text(
          label,
          style: TextStyle(
            color: context.onSurfaceVariantColor,
            fontSize: 7.sp,
            fontWeight: FontWeight.w500,
            fontFamily: 'Poppins',
            letterSpacing: 0.3,
          ),
        ),
      ],
    );
  }

  Widget _buildPresetsCompact(BuildContext context, double chipRowHeight) {
    final builtIn = [
      ('flat', 'Flat', EqualizerBandPresets.flat),
      ('bass_boost', 'Bass Boost', EqualizerBandPresets.bassBoost),
      ('treble', 'Treble', EqualizerBandPresets.treble),
      ('vocal', 'Vocal', EqualizerBandPresets.vocal),
      ('rock', 'Rock', EqualizerBandPresets.rock),
      ('pop', 'Pop', EqualizerBandPresets.pop),
      ('jazz', 'Jazz', EqualizerBandPresets.jazz),
      ('classical', 'Classical', EqualizerBandPresets.classical),
      ('studio', 'Studio', EqualizerBandPresets.studio),
      ('small_room', 'Small Room', EqualizerBandPresets.smallRoom),
      ('small_hall', 'Small Hall', EqualizerBandPresets.smallHall),
      ('concert_hall', 'Concert Hall', EqualizerBandPresets.concertHall),
      ('live_stage', 'Live Stage', EqualizerBandPresets.liveStage),
      ('ambient_space', 'Ambient Space', EqualizerBandPresets.ambientSpace),
      ('car_cabin', 'Car Cabin', EqualizerBandPresets.carCabin),
      (
        'headphones_boost',
        'Headphones Boost',
        EqualizerBandPresets.headphonesBoost,
      ),
    ];
    var custom = (widget.state.equalizerCustomPresets ?? {}).values
        .map((e) => (e.id, e.name, List<double>.from(e.gains)))
        .toList();
    if (widget.presetRemoving != null) {
      custom = [
        ...custom,
        (
          widget.presetRemoving!.id,
          widget.presetRemoving!.name,
          widget.presetRemoving!.gains,
        ),
      ];
    }
    final presets = [
      ...builtIn.map((e) => (e.$1, e.$2, List<double>.from(e.$3))),
      ...custom,
    ];

    return SizedBox(
      height: chipRowHeight,
      child: Row(
        children: [
          _buildChipSectionLabel(
            context,
            'PRESETS',
            CupertinoIcons.music_note_list,
          ),
          SizedBox(width: 4.w),
          Expanded(
            child: ListView.separated(
              controller: _presetScroll,
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              itemCount: presets.length,
              separatorBuilder: (_, __) => SizedBox(width: 3.w),
              itemBuilder: (context, index) {
                final (id, name, gains) = presets[index];
                final isSelected = widget.selectedPresetId == id;
                final isCustom =
                    id.startsWith('custom_') || widget.presetRemoving?.id == id;
                final isRemoving = widget.presetRemoving?.id == id;

                _chipKeys.putIfAbsent(id, () => GlobalKey());

                return AnimatedOpacity(
                  duration: const Duration(milliseconds: 300),
                  opacity: isRemoving ? 0.0 : 1.0,
                  child: _AnimatedEqChip(
                    key: _chipKeys[id],
                    label: name,
                    isSelected: isSelected,
                    isCustom: isCustom,
                    onSelected: isRemoving
                        ? null
                        : () {
                            widget.onPresetSelected(
                              id,
                              name,
                              List<double>.from(gains),
                            );
                          },
                    onDelete: isCustom && widget.onPresetDeleteRequested != null
                        ? () => widget.onPresetDeleteRequested!(
                            id,
                            name,
                            List<double>.from(gains),
                          )
                        : null,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReverbCompact(BuildContext context, double chipRowHeight) {
    final presets = [
      (EqualizerReverbPresets.none, 'None'),
      (EqualizerReverbPresets.smallRoom, 'S.Room'),
      (EqualizerReverbPresets.mediumRoom, 'M.Room'),
      (EqualizerReverbPresets.largeRoom, 'L.Room'),
      (EqualizerReverbPresets.mediumHall, 'M.Hall'),
      (EqualizerReverbPresets.largeHall, 'L.Hall'),
      (EqualizerReverbPresets.plate, 'Plate'),
    ];
    final selectedReverb = widget.state.reverbEnabled
        ? widget.state.reverbPreset
        : EqualizerReverbPresets.none;

    return SizedBox(
      height: chipRowHeight,
      child: Row(
        children: [
          _buildChipSectionLabel(context, 'REVERB', CupertinoIcons.waveform),
          SizedBox(width: 4.w),
          Expanded(
            child: ListView.separated(
              controller: _reverbScroll,
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              itemCount: presets.length,
              separatorBuilder: (_, __) => SizedBox(width: 3.w),
              itemBuilder: (context, index) {
                final (id, name) = presets[index];
                final isSelected = selectedReverb == id;

                return _AnimatedEqChip(
                  label: name,
                  isSelected: isSelected,
                  isCustom: false,
                  onSelected: () async {
                    final preset = isSelected
                        ? EqualizerReverbPresets.none
                        : id;
                    await widget.onReverbSelected(preset);
                  },
                  onDelete: null,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ── Animated Chip ────────────────────────────────────────────────────────────

/// A premium animated chip for preset/reverb selection. Supports:
/// - Scale animation on selection (0.85 → 1.0)
/// - Color morph: transparent → primaryStart glow background
/// - Glowing animated border on selection
/// - Font weight/color animation
/// - Optional delete icon (only visible when selected + custom)
class _AnimatedEqChip extends StatefulWidget {
  final String label;
  final bool isSelected;
  final bool isCustom;
  final VoidCallback? onSelected;
  final VoidCallback? onDelete;

  const _AnimatedEqChip({
    super.key,
    required this.label,
    required this.isSelected,
    required this.isCustom,
    required this.onSelected,
    required this.onDelete,
  });

  @override
  State<_AnimatedEqChip> createState() => _AnimatedEqChipState();
}

class _AnimatedEqChipState extends State<_AnimatedEqChip>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnim;
  late Animation<double> _glowAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );
    _scaleAnim = Tween<double>(
      begin: 0.88,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));
    _glowAnim = CurvedAnimation(parent: _controller, curve: Curves.easeOut);

    if (widget.isSelected) _controller.value = 1.0;
  }

  @override
  void didUpdateWidget(covariant _AnimatedEqChip oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isSelected != oldWidget.isSelected) {
      if (widget.isSelected) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final glow = _glowAnim.value;
        final isSelected = widget.isSelected;

        // Single AnimatedContainer — shadow + fill + border all on one BoxDecoration.
        // Root fix for rounded shadow: remove spreadRadius entirely.
        // Flutter's BoxShadow expands by spreadRadius as a plain Rect BEFORE applying
        // borderRadius, so non-zero spreadRadius produces visually square corners.
        // Using only blurRadius means the glow blur is always applied to the RRect
        // shape directly, giving perfectly rounded pill-shaped glow on all 4 corners.
        return Transform.scale(
          scale: _scaleAnim.value,
          child: GestureDetector(
            onTap: () {
              if (widget.onSelected != null) {
                HapticFeedback.lightImpact();
                widget.onSelected!();
              }
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 280),
              curve: Curves.easeOutCubic,
              padding: EdgeInsets.symmetric(
                horizontal: widget.isCustom && isSelected ? 5.w : 7.w,
                vertical: 3.h,
              ),
              decoration: BoxDecoration(
                gradient: isSelected
                    ? LinearGradient(
                        colors: [
                          context.primaryStart.withValues(
                            alpha: 0.18 + glow * 0.10,
                          ),
                          context.primaryEnd.withValues(
                            alpha: 0.14 + glow * 0.08,
                          ),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : null,
                // color: transparent when no gradient — ensures Flutter always
                // uses the RRect paint path (with borderRadius) for this decoration,
                // so boxShadow is rendered rounded even when gradient is null.
                color: isSelected
                    ? null
                    : context.onSurfaceVariantColor.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(20.r),
                border: Border.all(
                  color: isSelected
                      ? context.primaryStart
                          .withValues(alpha: 0.5 + glow * 0.4)
                      : context.onSurfaceVariantColor.withValues(alpha: 0.2),
                  width: isSelected ? 1.4 : 0.8,
                ),
                // No spreadRadius — blur alone gives a perfectly rounded pill glow.
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: context.primaryStart.withValues(
                            alpha: 0.22 + glow * 0.28,
                          ),
                          blurRadius: 9.r + glow * 7,
                          // spreadRadius intentionally omitted — see comment above
                        ),
                      ]
                    : [],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 250),
                    style: TextStyle(
                      fontSize: 6.sp,
                      fontWeight: isSelected
                          ? FontWeight.w700
                          : FontWeight.w400,
                      fontFamily: 'Poppins',
                      color: isSelected
                          ? context.primaryStart
                          : context.onSurfaceVariantColor,
                    ),
                    child: Text(widget.label),
                  ),
                  // Custom delete 'x' — only visible when selected
                  if (widget.isCustom && widget.onDelete != null)
                    AnimatedSize(
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeOutCubic,
                      child: isSelected
                          ? Padding(
                              padding: EdgeInsets.only(left: 3.w),
                              child: GestureDetector(
                                onTap: () {
                                  HapticFeedback.mediumImpact();
                                  widget.onDelete!();
                                },
                                child: Icon(
                                  CupertinoIcons.xmark_circle_fill,
                                  size: 7.sp,
                                  color: const Color(0xFFFF6B6B),
                                ),
                              ),
                            )
                          : const SizedBox.shrink(),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

// ── Save / Update / Select / Undo bar ────────────────────────────────────────

class EqualizerBottomSaveUpdateButton extends StatelessWidget {
  const EqualizerBottomSaveUpdateButton({
    super.key,
    required this.hasPendingSave,
    required this.currentPresetModified,
    required this.isCustomPreset,
    required this.onConfirmSelection,
    required this.onUndo,
    required this.onUpdate,
  });

  final bool hasPendingSave;
  final bool currentPresetModified;
  final bool isCustomPreset;
  final VoidCallback onConfirmSelection;
  final VoidCallback onUndo;
  final VoidCallback onUpdate;

  @override
  Widget build(BuildContext context) {
    final showSelectOnly = hasPendingSave && !currentPresetModified;
    final showUndoUpdate = currentPresetModified;
    final visible = showSelectOnly || showUndoUpdate;
    if (!visible) return const SizedBox.shrink();

    return AnimatedSlide(
      offset: visible ? Offset.zero : const Offset(0, 1),
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutBack,
      child: AnimatedOpacity(
        opacity: visible ? 1 : 0,
        duration: const Duration(milliseconds: 260),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 260),
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeIn,
          transitionBuilder: (child, animation) => FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.15),
                end: Offset.zero,
              ).animate(animation),
              child: child,
            ),
          ),
          child: Container(
            key: ValueKey(showSelectOnly ? 'select' : 'undoupdate'),
            padding: EdgeInsets.fromLTRB(
              10.w,
              4.h,
              10.w,
              4.h + MediaQuery.of(context).padding.bottom,
            ),
            decoration: BoxDecoration(
              color: context.surfaceColor,
              border: Border(
                top: BorderSide(
                  color: context.primaryStart.withValues(alpha: 0.15),
                  width: 1,
                ),
              ),
              boxShadow: [
                BoxShadow(
                  color: context.primaryStart.withValues(alpha: 0.08),
                  blurRadius: 10.r,
                  offset: Offset(0, -3.h),
                ),
                BoxShadow(
                  color: context.onSurfaceColor.withValues(alpha: 0.06),
                  blurRadius: 6.r,
                  offset: Offset(0, -1.h),
                ),
              ],
            ),
            child: SafeArea(
              top: false,
              child: showSelectOnly
                  ? _buildSelectButton(context)
                  : _buildUndoUpdateRow(context),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSelectButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [context.primaryStart, context.primaryEnd],
          ),
          borderRadius: BorderRadius.circular(8.r),
          boxShadow: [
            BoxShadow(
              color: context.primaryStart.withValues(alpha: 0.35),
              blurRadius: 8.r,
              offset: Offset(0, 3.h),
            ),
          ],
        ),
        child: FilledButton(
          onPressed: () {
            HapticFeedback.mediumImpact();
            onConfirmSelection();
          },
          style: FilledButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            foregroundColor: Colors.white,
            padding: EdgeInsets.symmetric(vertical: 4.h),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8.r),
            ),
          ),
          child: Text(
            'Select',
            style: TextStyle(
              fontSize: 10.sp,
              fontWeight: FontWeight.w700,
              fontFamily: 'Poppins',
              letterSpacing: 0.5,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUndoUpdateRow(BuildContext context) {
    return Row(
      children: [
        Expanded(
          flex: 40,
          child: OutlinedButton(
            onPressed: () {
              HapticFeedback.lightImpact();
              onUndo();
            },
            style: OutlinedButton.styleFrom(
              foregroundColor: context.onSurfaceVariantColor,
              side: BorderSide(
                color: context.primaryStart.withValues(alpha: 0.45),
                width: 1.2,
              ),
              padding: EdgeInsets.symmetric(vertical: 4.h),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.r),
              ),
            ),
            child: Text(
              'Undo',
              style: TextStyle(
                fontSize: 9.sp,
                fontWeight: FontWeight.w600,
                fontFamily: 'Poppins',
              ),
            ),
          ),
        ),
        SizedBox(width: 6.w),
        Expanded(
          flex: 60,
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [context.primaryStart, context.primaryEnd],
              ),
              borderRadius: BorderRadius.circular(8.r),
              boxShadow: [
                BoxShadow(
                  color: context.primaryStart.withValues(alpha: 0.35),
                  blurRadius: 8.r,
                  offset: Offset(0, 3.h),
                ),
              ],
            ),
            child: FilledButton(
              onPressed: () {
                HapticFeedback.mediumImpact();
                onUpdate();
              },
              style: FilledButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 4.h),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.r),
                ),
              ),
              child: Text(
                isCustomPreset ? 'Update' : 'Save as new',
                style: TextStyle(
                  fontSize: 9.sp,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'Poppins',
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

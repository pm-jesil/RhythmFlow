import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:rhythmflow/core/constants/app_constants.dart';
import 'package:rhythmflow/core/theme/theme_extension.dart';
import 'package:rhythmflow/screens/equalizer/bloc/equalizer_bloc.dart';
import 'package:rhythmflow/screens/equalizer/widgets/master_volume_knob.dart';

class EqualizerBottomKnobRow extends StatefulWidget {
  const EqualizerBottomKnobRow({
    super.key,
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
  });

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

  @override
  State<EqualizerBottomKnobRow> createState() => _EqualizerBottomKnobRowState();
}

class _EqualizerBottomKnobRowState extends State<EqualizerBottomKnobRow> {
  static const List<({String id, String label})> _builtInPresetChips = [
    (id: 'flat', label: 'Flat'),
    (id: 'bass_boost', label: 'Bass Boost'),
    (id: 'treble', label: 'Treble'),
    (id: 'vocal', label: 'Vocal'),
    (id: 'rock', label: 'Rock'),
    (id: 'pop', label: 'Pop'),
    (id: 'jazz', label: 'Jazz'),
    (id: 'classical', label: 'Classical'),
    (id: 'studio', label: 'Studio'),
    (id: 'small_room', label: 'Small Room'),
    (id: 'medium_room', label: 'Medium Room'),
    (id: 'large_room', label: 'Large Room'),
    (id: 'small_hall', label: 'Small Hall'),
    (id: 'medium_hall', label: 'Medium Hall'),
    (id: 'large_hall', label: 'Large Hall'),
    (id: 'plate', label: 'Plate'),
    (id: 'concert_hall', label: 'Concert Hall'),
    (id: 'live_stage', label: 'Live Stage'),
    (id: 'ambient_space', label: 'Ambient Space'),
    (id: 'car_cabin', label: 'Car Cabin'),
    (id: 'headphones_boost', label: 'Headphones Boost'),
  ];

  final ScrollController _presetScroll = ScrollController();
  final Map<String, GlobalKey> _chipKeys = {};
  String? _deleteArmedPresetId;

  @override
  void dispose() {
    _presetScroll.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant EqualizerBottomKnobRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedPresetId != widget.selectedPresetId) {
      _scrollToSelected(widget.selectedPresetId);
    }
    if (_deleteArmedPresetId != null && widget.presetRemoving?.id == _deleteArmedPresetId) {
      _deleteArmedPresetId = null;
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
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOutCubic,
      );
    });
  }

  void _clearDeleteArm() {
    if (_deleteArmedPresetId == null) return;
    setState(() => _deleteArmedPresetId = null);
  }

  @override
  Widget build(BuildContext context) {
    final chipRowHeight = (widget.height * 0.56).clamp(28.r, 38.r);
    return SizedBox(
      height: widget.height,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            height: widget.height,
            width: 150.r,
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
              padding: EdgeInsets.symmetric(horizontal: 18.r, vertical: 8.r),
              decoration: BoxDecoration(
                color: context.surfaceColor.withValues(
                  alpha: context.isDark ? 0.62 : 0.78,
                ),
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(
                  color: context.onSurfaceVariantColor.withValues(alpha: 0.18),
                  width: 1,
                ),
              ),
              child: _buildPresetsCompact(context, chipRowHeight),
            ),
          ),
          SizedBox(
            height: widget.height,
            width: 150.r,
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
        Icon(icon, size: 8.sp, color: context.primaryStart),
        SizedBox(width: 4.r),
        Text(
          label,
          style: TextStyle(
            color: context.onSurfaceVariantColor,
            fontSize: 7.sp,
            fontWeight: FontWeight.w600,
            fontFamily: 'Poppins',
            letterSpacing: 0.35,
          ),
        ),
      ],
    );
  }

  Widget _buildPresetsCompact(BuildContext context, double chipRowHeight) {
    final builtIn = _builtInPresetChips
        .map(
          (preset) => (
            preset.id,
            preset.label,
            EqualizerBandPresets.getGains(preset.id),
          ),
        )
        .toList();

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
    custom.sort((a, b) => a.$1.compareTo(b.$1));
    final presets = [...builtIn, ...custom];

    return SizedBox(
      height: chipRowHeight,
      child: Row(
        children: [
          _buildChipSectionLabel(
            context,
            'PRESETS',
            CupertinoIcons.music_note_list,
          ),
          SizedBox(width: 8.r),
          Expanded(
            child: ListView.separated(
              controller: _presetScroll,
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              itemCount: presets.length,
              separatorBuilder: (context, index) => SizedBox(width: 6.r),
              itemBuilder: (context, index) {
                final (id, name, gains) = presets[index];
                final isSelected = widget.selectedPresetId == id;
                final isCustom =
                    id.startsWith('custom_') || widget.presetRemoving?.id == id;
                final isRemoving = widget.presetRemoving?.id == id;
                final isDeleteArmed = _deleteArmedPresetId == id && isCustom;

                _chipKeys.putIfAbsent(id, () => GlobalKey());

                return AnimatedOpacity(
                  duration: const Duration(milliseconds: 260),
                  opacity: isRemoving ? 0.0 : 1.0,
                  child: _AnimatedEqChip(
                    key: _chipKeys[id],
                    label: name,
                    isSelected: isSelected,
                    isCustom: isCustom,
                    isDeleteArmed: isDeleteArmed,
                    onTap: isRemoving
                        ? null
                        : () {
                            if (isDeleteArmed) {
                              if (widget.onPresetDeleteRequested != null) {
                                HapticFeedback.mediumImpact();
                                _clearDeleteArm();
                                widget.onPresetDeleteRequested!(
                                  id,
                                  name,
                                  List<double>.from(gains),
                                );
                              }
                              return;
                            }
                            if (_deleteArmedPresetId != null) {
                              _clearDeleteArm();
                            }
                            HapticFeedback.lightImpact();
                            widget.onPresetSelected(
                              id,
                              name,
                              List<double>.from(gains),
                            );
                          },
                    onLongPress: isCustom &&
                            !isRemoving &&
                            widget.onPresetDeleteRequested != null
                        ? () {
                            HapticFeedback.mediumImpact();
                            setState(
                              () => _deleteArmedPresetId = isDeleteArmed ? null : id,
                            );
                          }
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
}

class _AnimatedEqChip extends StatelessWidget {
  const _AnimatedEqChip({
    super.key,
    required this.label,
    required this.isSelected,
    required this.isCustom,
    required this.isDeleteArmed,
    required this.onTap,
    required this.onLongPress,
  });

  final String label;
  final bool isSelected;
  final bool isCustom;
  final bool isDeleteArmed;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    final fillColor = isDeleteArmed
        ? const Color(0xFFC62828).withValues(alpha: context.isDark ? 0.24 : 0.16)
        : isSelected
            ? context.primaryStart.withValues(alpha: context.isDark ? 0.26 : 0.16)
            : context.onSurfaceVariantColor.withValues(
                alpha: context.isDark ? 0.10 : 0.08,
              );

    final borderColor = isDeleteArmed
        ? const Color(0xFFC62828).withValues(alpha: 0.9)
        : isSelected
            ? context.primaryStart.withValues(alpha: 0.45)
            : context.onSurfaceVariantColor.withValues(alpha: 0.22);

    final textColor = isDeleteArmed
        ? const Color(0xFFC62828)
        : isSelected
            ? context.primaryStart
            : context.onSurfaceVariantColor;

    return AnimatedScale(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOutCubic,
      scale: isSelected ? 1.0 : 0.97,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              onLongPress: onLongPress,
              borderRadius: BorderRadius.circular(10.r),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                constraints: BoxConstraints(
                  minWidth: 56.r,
                  maxWidth: 92.r,
                  minHeight: 28.r,
                ),
                padding: EdgeInsets.symmetric(horizontal: 8.r, vertical: 5.r),
                decoration: BoxDecoration(
                  color: fillColor,
                  borderRadius: BorderRadius.circular(10.r),
                  border: Border.all(color: borderColor, width: 1),
                ),
                child: Center(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 180),
                    child: isDeleteArmed
                        ? Icon(
                            CupertinoIcons.delete_solid,
                            key: const ValueKey('delete_icon'),
                            size: 9.sp,
                            color: const Color(0xFFC62828),
                          )
                        : Text(
                            label,
                            key: const ValueKey('preset_label'),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                            softWrap: true,
                            style: TextStyle(
                              fontSize: 6.6.sp,
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.w500,
                              height: 1.2,
                              fontFamily: 'Poppins',
                              color: textColor,
                            ),
                          ),
                  ),
                ),
              ),
            ),
          ),
          if (isCustom && !isDeleteArmed)
            Positioned(
              top: -3.r,
              right: -3.r,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: context.surfaceColor,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: context.primaryStart.withValues(alpha: 0.55),
                    width: 1,
                  ),
                ),
                child: Padding(
                  padding: EdgeInsets.all(1.6.r),
                  child: Icon(
                    CupertinoIcons.pencil,
                    size: 5.4.sp,
                    color: context.primaryStart,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

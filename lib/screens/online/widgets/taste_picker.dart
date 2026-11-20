import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../core/theme/theme_extension.dart';
import '../../../utils/services/jamendo/taste_models.dart';

/// Spotify-style multi-select of genres and moods ("vibes").
class TastePicker extends StatelessWidget {
  const TastePicker({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  final List<String> selected;
  final ValueChanged<List<String>> onChanged;

  void _toggle(String id) {
    HapticFeedback.selectionClick();
    final next = [...selected];
    if (!next.remove(id)) next.add(id);
    onChanged(next);
  }

  @override
  Widget build(BuildContext context) {
    Widget group(String title, List<MusicTaste> tastes) => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(bottom: 6.h),
          child: Text(
            title,
            style: TextStyle(
              color: context.onSurfaceVariantColor.withValues(alpha: 0.8),
              fontSize: 11.sp,
              fontFamily: 'Poppins',
            ),
          ),
        ),
        Wrap(
          spacing: 8.w,
          runSpacing: 8.h,
          children: [
            for (final t in tastes)
              TasteChip(
                taste: t,
                selected: selected.contains(t.id),
                onTap: () => _toggle(t.id),
              ),
          ],
        ),
      ],
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        group('Genres', MusicTastes.genres),
        SizedBox(height: 12.h),
        group('Moods', MusicTastes.moods),
      ],
    );
  }
}

class TasteChip extends StatelessWidget {
  const TasteChip({
    super.key,
    required this.taste,
    required this.selected,
    required this.onTap,
    this.compact = false,
  });

  final MusicTaste taste;
  final bool selected;
  final VoidCallback onTap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: taste.label,
      child: GestureDetector(
        key: ValueKey('taste_${taste.id}'),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 10.w : 12.w,
            vertical: compact ? 6.h : 8.h,
          ),
          decoration: BoxDecoration(
            gradient: selected ? context.primaryGradient : null,
            color: selected ? null : context.onSurfaceColor.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(20.r),
            border: Border.all(
              color: selected
                  ? Colors.transparent
                  : context.onSurfaceColor.withValues(alpha: 0.1),
            ),
          ),
          child: Text(
            '${taste.emoji}  ${taste.label}',
            style: TextStyle(
              color: selected ? Colors.white : context.onSurfaceColor,
              fontSize: compact ? 11.sp : 12.sp,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
              fontFamily: 'Poppins',
            ),
          ),
        ),
      ),
    );
  }
}

/// Bottom sheet wrapping [TastePicker]; returns the new selection.
Future<List<String>?> showTastePicker(
  BuildContext context, {
  List<String> selected = const [],
}) {
  return showModalBottomSheet<List<String>>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _TasteSheet(initial: selected),
  );
}

class _TasteSheet extends StatefulWidget {
  const _TasteSheet({required this.initial});
  final List<String> initial;

  @override
  State<_TasteSheet> createState() => _TasteSheetState();
}

class _TasteSheetState extends State<_TasteSheet> {
  late List<String> _selected = [...widget.initial];

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.8,
      maxChildSize: 0.95,
      builder: (context, controller) => Container(
        decoration: BoxDecoration(
          color: context.surfaceColor,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
        ),
        child: Column(
          children: [
            Expanded(
              child: ListView(
                controller: controller,
                padding: EdgeInsets.fromLTRB(20.w, 18.h, 20.w, 12.h),
                children: [
                  Text(
                    'Your music vibes',
                    style: TextStyle(
                      color: context.onSurfaceColor,
                      fontSize: 18.sp,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'Poppins',
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    'Pick ${MusicTastes.recommendedPicks} or more for better suggestions',
                    style: TextStyle(color: context.onSurfaceVariantColor, fontSize: 12.sp),
                  ),
                  SizedBox(height: 14.h),
                  TastePicker(
                    selected: _selected,
                    onChanged: (t) => setState(() => _selected = t),
                  ),
                ],
              ),
            ),
            SafeArea(
              top: false,
              child: Padding(
                padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 12.h),
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    key: const ValueKey('tastes_done'),
                    onPressed: _selected.isEmpty
                        ? null
                        : () => Navigator.of(context).pop(List<String>.from(_selected)),
                    child: Text(
                      _selected.isEmpty ? 'Pick at least one' : 'Done · ${_selected.length} selected',
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

/// Field tile showing the selected tastes; opens [showTastePicker].
class TastesField extends StatelessWidget {
  const TastesField({super.key, required this.tastes, required this.onChanged});

  final List<String> tastes;
  final ValueChanged<List<String>> onChanged;

  @override
  Widget build(BuildContext context) {
    final labels = tastes.map(MusicTastes.byId).whereType<MusicTaste>().map((t) => t.label).toList();
    final value = labels.isEmpty
        ? null
        : labels.length <= 3
        ? labels.join(', ')
        : '${labels.take(3).join(', ')} +${labels.length - 3}';
    return Material(
      color: Colors.transparent,
      child: InkWell(
        key: const ValueKey('region_tastes'),
        borderRadius: BorderRadius.circular(16.r),
        onTap: () async {
          final picked = await showTastePicker(context, selected: tastes);
          if (picked != null) onChanged(picked);
        },
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16.r),
            color: context.onSurfaceColor.withValues(alpha: 0.04),
            border: Border.all(
              color: value != null
                  ? context.primaryStart.withValues(alpha: 0.5)
                  : context.onSurfaceColor.withValues(alpha: 0.12),
            ),
          ),
          child: Row(
            children: [
              Icon(Icons.auto_awesome, color: context.primaryStart, size: 20.sp),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Music vibes',
                      style: TextStyle(color: context.onSurfaceVariantColor, fontSize: 11.sp, fontFamily: 'Poppins'),
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      value ?? 'Rap, Lo-fi, Romantic…',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: value != null
                            ? context.onSurfaceColor
                            : context.onSurfaceVariantColor.withValues(alpha: 0.7),
                        fontSize: 14.sp,
                        fontWeight: value != null ? FontWeight.w600 : FontWeight.w400,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

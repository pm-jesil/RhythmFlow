import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../core/theme/theme_extension.dart';
import '../../../utils/services/jamendo/region_models.dart';

/// Bottom sheet listing the countries that have Jamendo artists.
Future<MusicCountry?> showCountryPicker(
  BuildContext context, {
  String? selected,
}) {
  return showModalBottomSheet<MusicCountry>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _PickerSheet<MusicCountry>(
      title: 'Choose your country',
      subtitle: 'Only countries with artists on Jamendo are listed',
      searchHint: 'Search countries',
      search: MusicRegions.searchCountries,
      isSelected: (c) => c.alpha2 == selected,
      leading: (c) => Text(c.flag, style: TextStyle(fontSize: 22.sp)),
      title_: (c) => c.name,
      trailing: (c) => '${c.artistCount} artists',
      onTap: (ctx, c) => Navigator.of(ctx).pop(c),
    ),
  );
}

/// Bottom sheet to pick one or more languages (first = primary).
Future<List<String>?> showLanguagePicker(
  BuildContext context, {
  List<String> selected = const [],
}) {
  return showModalBottomSheet<List<String>>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _LanguagePickerSheet(initial: selected),
  );
}

class _LanguagePickerSheet extends StatefulWidget {
  const _LanguagePickerSheet({required this.initial});
  final List<String> initial;

  @override
  State<_LanguagePickerSheet> createState() => _LanguagePickerSheetState();
}

class _LanguagePickerSheetState extends State<_LanguagePickerSheet> {
  late final List<String> _selected = [...widget.initial];

  @override
  Widget build(BuildContext context) {
    return _PickerSheet<MusicLanguage>(
      title: 'Your music languages',
      subtitle: 'Pick one or more. The first one is your main language',
      searchHint: 'Search languages',
      search: MusicRegions.searchLanguages,
      isSelected: (l) => _selected.contains(l.code),
      leading: (l) {
        final index = _selected.indexOf(l.code);
        return _LanguageBadge(code: l.code, order: index < 0 ? null : index + 1);
      },
      title_: (l) => l.name,
      trailing: (l) => l.nativeName == l.name ? '' : l.nativeName,
      onTap: (_, l) => setState(() {
        if (!_selected.remove(l.code)) _selected.add(l.code);
      }),
      footer: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 12.h),
          child: GradientButton(
            label: _selected.isEmpty
                ? 'Select at least one language'
                : 'Done · ${_selected.length} selected',
            onPressed: _selected.isEmpty
                ? null
                : () => Navigator.of(context).pop(List<String>.from(_selected)),
          ),
        ),
      ),
    );
  }
}

class _LanguageBadge extends StatelessWidget {
  const _LanguageBadge({required this.code, this.order});
  final String code;
  final int? order;

  @override
  Widget build(BuildContext context) {
    final selected = order != null;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      width: 34.r,
      height: 34.r,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: selected ? context.primaryGradient : null,
        color: selected ? null : context.onSurfaceColor.withValues(alpha: 0.06),
      ),
      child: Text(
        selected ? '$order' : code.toUpperCase(),
        style: TextStyle(
          color: selected ? Colors.white : context.onSurfaceVariantColor,
          fontSize: 11.sp,
          fontWeight: FontWeight.w700,
          fontFamily: 'Poppins',
        ),
      ),
    );
  }
}

/// Generic searchable picker sheet matching the app's rounded style.
class _PickerSheet<T> extends StatefulWidget {
  const _PickerSheet({
    super.key,
    required this.title,
    required this.subtitle,
    required this.searchHint,
    required this.search,
    required this.isSelected,
    required this.leading,
    required this.title_,
    required this.trailing,
    required this.onTap,
    this.footer,
  });

  final String title;
  final String subtitle;
  final String searchHint;
  final List<T> Function(String query) search;
  final bool Function(T item) isSelected;
  final Widget Function(T item) leading;
  final String Function(T item) title_;
  final String Function(T item) trailing;
  final void Function(BuildContext context, T item) onTap;
  final Widget? footer;

  @override
  State<_PickerSheet<T>> createState() => _PickerSheetState<T>();
}

class _PickerSheetState<T> extends State<_PickerSheet<T>> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final items = widget.search(_query);
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, controller) => Container(
        decoration: BoxDecoration(
          color: context.surfaceColor,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
        ),
        child: Column(
          children: [
            SizedBox(height: 10.h),
            Container(
              width: 40.w,
              height: 4.h,
              decoration: BoxDecoration(
                color: context.onSurfaceColor.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(2.r),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(20.w, 14.h, 20.w, 4.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.title,
                    style: TextStyle(
                      color: context.onSurfaceColor,
                      fontSize: 18.sp,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'Poppins',
                    ),
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    widget.subtitle,
                    style: TextStyle(
                      color: context.onSurfaceVariantColor,
                      fontSize: 12.sp,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
              child: TextField(
                autofocus: false,
                onChanged: (q) => setState(() => _query = q),
                style: TextStyle(color: context.onSurfaceColor, fontFamily: 'Poppins'),
                decoration: InputDecoration(
                  hintText: widget.searchHint,
                  prefixIcon: const Icon(CupertinoIcons.search),
                  isDense: true,
                  filled: true,
                  fillColor: context.onSurfaceColor.withValues(alpha: 0.05),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14.r),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            Expanded(
              child: items.isEmpty
                  ? Center(
                      child: Text(
                        'Nothing found',
                        style: TextStyle(color: context.onSurfaceVariantColor),
                      ),
                    )
                  : ListView.builder(
                      controller: controller,
                      itemCount: items.length,
                      itemBuilder: (context, index) {
                        final item = items[index];
                        final selected = widget.isSelected(item);
                        final trailing = widget.trailing(item);
                        return ListTile(
                          key: ValueKey('picker_${widget.title_(item)}'),
                          onTap: () => widget.onTap(context, item),
                          leading: widget.leading(item),
                          title: Text(
                            widget.title_(item),
                            style: TextStyle(
                              color: context.onSurfaceColor,
                              fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                              fontFamily: 'Poppins',
                              fontSize: 14.sp,
                            ),
                          ),
                          trailing: ConstrainedBox(
                            // ListTile trailing space is limited; long native
                            // names (e.g. "Bahasa Indonesia") are ellipsized.
                            constraints: BoxConstraints(maxWidth: 140.w),
                            child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (trailing.isNotEmpty)
                                Flexible(
                                  child: Text(
                                    trailing,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: context.onSurfaceVariantColor,
                                      fontSize: 11.sp,
                                    ),
                                  ),
                                ),
                              if (selected) ...[
                                SizedBox(width: 8.w),
                                Icon(
                                  CupertinoIcons.checkmark_alt_circle_fill,
                                  color: context.primaryStart,
                                  size: 20.sp,
                                ),
                              ],
                            ],
                          ),
                          ),
                        );
                      },
                    ),
            ),
            ?widget.footer,
          ],
        ),
      ),
    );
  }
}

/// Two tappable fields (country + languages), used on the Welcome screen,
/// in Profile and in the Discover setup sheet.
class RegionFields extends StatelessWidget {
  const RegionFields({
    super.key,
    required this.country,
    required this.languages,
    required this.onCountryChanged,
    required this.onLanguagesChanged,
  });

  final String? country;
  final List<String> languages;
  final ValueChanged<String> onCountryChanged;
  final ValueChanged<List<String>> onLanguagesChanged;

  @override
  Widget build(BuildContext context) {
    final c = MusicRegions.countryByAlpha2(country);
    final langs = languages
        .map(MusicRegions.languageByCode)
        .whereType<MusicLanguage>()
        .toList();
    return Column(
      children: [
        RegionField(
          key: const ValueKey('region_country'),
          icon: CupertinoIcons.location_solid,
          label: 'Country',
          value: c == null ? null : '${c.flag}  ${c.name}',
          placeholder: 'Where are you listening from?',
          onTap: () async {
            final picked = await showCountryPicker(context, selected: country);
            if (picked != null) onCountryChanged(picked.alpha2);
          },
        ),
        SizedBox(height: 12.h),
        RegionField(
          key: const ValueKey('region_languages'),
          icon: CupertinoIcons.globe,
          label: 'Music language',
          value: langs.isEmpty ? null : langs.map((l) => l.name).join(', '),
          placeholder: 'Which languages do you enjoy?',
          onTap: () async {
            final picked = await showLanguagePicker(context, selected: languages);
            if (picked != null) onLanguagesChanged(picked);
          },
        ),
      ],
    );
  }
}

class RegionField extends StatelessWidget {
  const RegionField({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    required this.placeholder,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String? value;
  final String placeholder;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final hasValue = value != null && value!.isNotEmpty;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16.r),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16.r),
            color: context.onSurfaceColor.withValues(alpha: 0.04),
            border: Border.all(
              color: hasValue
                  ? context.primaryStart.withValues(alpha: 0.5)
                  : context.onSurfaceColor.withValues(alpha: 0.12),
            ),
          ),
          child: Row(
            children: [
              Icon(icon, color: context.primaryStart, size: 20.sp),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        color: context.onSurfaceVariantColor,
                        fontSize: 11.sp,
                        fontFamily: 'Poppins',
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      hasValue ? value! : placeholder,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: hasValue
                            ? context.onSurfaceColor
                            : context.onSurfaceVariantColor.withValues(alpha: 0.7),
                        fontSize: 14.sp,
                        fontWeight: hasValue ? FontWeight.w600 : FontWeight.w400,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                CupertinoIcons.chevron_down,
                size: 16.sp,
                color: context.onSurfaceVariantColor,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Primary gradient button used across the Discover UI.
class GradientButton extends StatelessWidget {
  const GradientButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 200),
      opacity: enabled ? 1 : 0.5,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(16.r),
          child: Ink(
            height: 50.h,
            decoration: BoxDecoration(
              gradient: context.primaryGradient,
              borderRadius: BorderRadius.circular(16.r),
              boxShadow: enabled
                  ? [
                      BoxShadow(
                        color: context.primaryStart.withValues(alpha: 0.35),
                        blurRadius: 12.r,
                        offset: Offset(0, 4.h),
                      ),
                    ]
                  : null,
            ),
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            child: Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null) ...[
                    Icon(icon, color: Colors.white, size: 18.sp),
                    SizedBox(width: 8.w),
                  ],
                  Flexible(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Poppins',
                      ),
                    ),
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

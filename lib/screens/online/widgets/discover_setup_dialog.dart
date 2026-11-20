import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../core/theme/theme_extension.dart';
import '../../../utils/services/jamendo/region_models.dart';
import '../../app_settings/bloc/app_settings_bloc.dart';
import '../bloc/discover_bloc.dart';
import 'region_pickers.dart';

/// Asks for country + languages the first time Discover is opened, then shows
/// a "setting up your music" experience while Discover really loads, and
/// closes itself when everything is ready.
///
/// Returns true when the region was saved.
Future<bool?> showDiscoverSetupDialog(BuildContext context, {bool editing = false}) {
  return showGeneralDialog<bool>(
    context: context,
    barrierDismissible: false,
    barrierLabel: 'Personalise Discover',
    barrierColor: Colors.black.withValues(alpha: 0.45),
    transitionDuration: const Duration(milliseconds: 320),
    pageBuilder: (_, _, _) => DiscoverSetupDialog(editing: editing),
    transitionBuilder: (context, anim, _, child) {
      final curved = CurvedAnimation(parent: anim, curve: Curves.easeOutBack);
      return BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 6 * anim.value, sigmaY: 6 * anim.value),
        child: FadeTransition(
          opacity: anim,
          child: ScaleTransition(scale: Tween(begin: 0.92, end: 1.0).animate(curved), child: child),
        ),
      );
    },
  );
}

enum SetupStage { ask, settingUp, done }

class DiscoverSetupDialog extends StatefulWidget {
  const DiscoverSetupDialog({super.key, this.editing = false});

  final bool editing;

  /// Minimum time the "setting up" stage is shown (feels intentional rather
  /// than flickering) and the maximum it waits for Jamendo.
  static Duration minSetupTime = const Duration(milliseconds: 2400);
  static Duration maxSetupTime = const Duration(seconds: 25);
  static Duration doneTime = const Duration(milliseconds: 1100);

  @override
  State<DiscoverSetupDialog> createState() => _DiscoverSetupDialogState();
}

class _SetupStep {
  final String label;
  final List<String> sectionIds;
  const _SetupStep(this.label, this.sectionIds);
}

class _DiscoverSetupDialogState extends State<DiscoverSetupDialog> {
  SetupStage _stage = SetupStage.ask;
  String? _country;
  List<String> _languages = const [];
  List<_SetupStep> _steps = const [];
  final Set<int> _doneSteps = {};
  StreamSubscription<DiscoverState>? _sub;
  Timer? _timeout;
  DateTime? _startedAt;

  @override
  void initState() {
    super.initState();
    final settings = context.read<AppSettingsBloc>().state;
    _country = settings.musicCountry;
    _languages = settings.musicLanguages;
    if (_country == null || _languages.isEmpty) {
      // Offline suggestion from the device locale (no network call).
      final locale = WidgetsBinding.instance.platformDispatcher.locale;
      final suggestion = MusicRegions.suggestFromLocale(locale.languageCode, locale.countryCode);
      _country ??= suggestion.country?.alpha2;
      if (_languages.isEmpty && suggestion.language != null) {
        _languages = [suggestion.language!.code];
      }
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    _timeout?.cancel();
    super.dispose();
  }

  bool get _canSubmit => (_country?.isNotEmpty ?? false) && _languages.isNotEmpty;

  void _submit() {
    if (!_canSubmit) return;
    HapticFeedback.mediumImpact();
    final country = MusicRegions.countryByAlpha2(_country)!;
    final language = MusicRegions.languageByCode(_languages.first);
    _steps = [
      const _SetupStep('Saving your preferences', []),
      _SetupStep('Finding artists from ${country.name}', const [DiscoverSectionIds.country]),
      _SetupStep(
        language == null || language.isGlobal
            ? 'Picking popular songs'
            : 'Picking ${language.name} songs',
        const [DiscoverSectionIds.language],
      ),
      const _SetupStep('Building your mixes', [
        DiscoverSectionIds.trending,
        DiscoverSectionIds.mixes,
        DiscoverSectionIds.newReleases,
      ]),
      const _SetupStep('Tuning live radio', [DiscoverSectionIds.radio, DiscoverSectionIds.artists]),
    ];
    _startedAt = DateTime.now();
    setState(() {
      _stage = SetupStage.settingUp;
      _doneSteps.add(0);
    });

    final discover = context.read<DiscoverBloc>();
    _sub = discover.stream.listen(_onDiscover);
    // Saving the region makes OnlineDependencies trigger
    // DiscoverEvent.regionChanged; send it directly too in case the
    // region is unchanged (re-run of the setup).
    context.read<AppSettingsBloc>().add(
      AppSettingsEvent.updateMusicRegion(country: _country!, languages: _languages),
    );
    discover.add(DiscoverEvent.regionChanged(country: _country, languages: _languages));
    if (widget.editing) discover.add(const DiscoverEvent.loadHome(force: true));
    _timeout = Timer(DiscoverSetupDialog.maxSetupTime, _finish);
    _onDiscover(discover.state);
  }

  void _onDiscover(DiscoverState state) {
    if (_stage != SetupStage.settingUp) return;
    if (state.country != _country) return;
    var changed = false;
    for (var i = 1; i < _steps.length; i++) {
      if (_doneSteps.contains(i)) continue;
      final ids = _steps[i].sectionIds;
      final finished = ids.every((id) {
        final section = state.sections[id];
        return section != null && !section.isLoading && section.status != SectionStatus.idle;
      });
      if (finished) {
        _doneSteps.add(i);
        changed = true;
      }
    }
    if (changed && mounted) setState(() {});
    if (_doneSteps.length == _steps.length) _finish();
  }

  /// Set synchronously so that the several Discover updates (and the
  /// timeout) that can arrive while waiting cannot close the dialog twice,
  /// which would also pop the screen underneath.
  bool _finishing = false;

  Future<void> _finish() async {
    if (_stage != SetupStage.settingUp || _finishing) return;
    _finishing = true;
    _timeout?.cancel();
    await _sub?.cancel();
    _sub = null;
    final elapsed = DateTime.now().difference(_startedAt ?? DateTime.now());
    final remaining = DiscoverSetupDialog.minSetupTime - elapsed;
    if (remaining > Duration.zero) await Future<void>.delayed(remaining);
    if (!mounted) return;
    HapticFeedback.lightImpact();
    setState(() {
      _doneSteps.addAll(List.generate(_steps.length, (i) => i));
      _stage = SetupStage.done;
    });
    await Future<void>.delayed(DiscoverSetupDialog.doneTime);
    if (mounted) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Center(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 20.w),
          child: Material(
            color: Colors.transparent,
            child: Container(
              constraints: BoxConstraints(maxWidth: 420.w),
              padding: EdgeInsets.fromLTRB(20.w, 22.h, 20.w, 18.h),
              decoration: BoxDecoration(
                color: context.surfaceColor,
                borderRadius: BorderRadius.circular(28.r),
                border: Border.all(color: context.onSurfaceColor.withValues(alpha: 0.08)),
                boxShadow: [
                  BoxShadow(
                    color: context.primaryStart.withValues(alpha: 0.25),
                    blurRadius: 40.r,
                    offset: Offset(0, 12.h),
                  ),
                ],
              ),
              child: AnimatedSize(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 350),
                  child: switch (_stage) {
                    SetupStage.ask => _buildAsk(),
                    SetupStage.settingUp => _buildSettingUp(),
                    SetupStage.done => _buildDone(),
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _title(String title, String subtitle) => Column(
    children: [
      Text(
        title,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: context.onSurfaceColor,
          fontSize: 20.sp,
          fontWeight: FontWeight.w700,
          fontFamily: 'Poppins',
        ),
      ),
      SizedBox(height: 6.h),
      Text(
        subtitle,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: context.onSurfaceVariantColor,
          fontSize: 12.5.sp,
          fontFamily: 'Poppins',
          height: 1.35,
        ),
      ),
    ],
  );

  Widget _buildAsk() {
    return Column(
      key: const ValueKey('setup_ask'),
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: EdgeInsets.all(14.r),
          decoration: BoxDecoration(gradient: context.primaryGradient, shape: BoxShape.circle),
          child: Icon(CupertinoIcons.globe, color: Colors.white, size: 28.sp),
        ),
        SizedBox(height: 14.h),
        _title(
          widget.editing ? 'Update your Discover' : 'Personalise Discover',
          'Tell us where you listen from and the languages you love. '
              "We'll find free music made for you.",
        ),
        SizedBox(height: 18.h),
        RegionFields(
          country: _country,
          languages: _languages,
          onCountryChanged: (c) => setState(() => _country = c),
          onLanguagesChanged: (l) => setState(() => _languages = l),
        ),
        SizedBox(height: 18.h),
        GradientButton(
          key: const ValueKey('setup_submit'),
          label: widget.editing ? 'Update my music' : 'Set up my music',
          icon: CupertinoIcons.sparkles,
          onPressed: _canSubmit ? _submit : null,
        ),
        SizedBox(height: 4.h),
        TextButton(
          key: const ValueKey('setup_skip'),
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(
            widget.editing ? 'Cancel' : 'Not now',
            style: TextStyle(color: context.onSurfaceVariantColor, fontFamily: 'Poppins'),
          ),
        ),
      ],
    );
  }

  Widget _buildSettingUp() {
    return Column(
      key: const ValueKey('setup_progress'),
      mainAxisSize: MainAxisSize.min,
      children: [
        const _EqualizerRing(),
        SizedBox(height: 16.h),
        _title('Setting up your music player', 'This only takes a moment…'),
        SizedBox(height: 18.h),
        for (var i = 0; i < _steps.length; i++)
          _StepRow(
            label: _steps[i].label,
            done: _doneSteps.contains(i),
            active: i == _firstPending,
          ),
      ],
    );
  }

  int get _firstPending {
    for (var i = 0; i < _steps.length; i++) {
      if (!_doneSteps.contains(i)) return i;
    }
    return -1;
  }

  Widget _buildDone() {
    return Column(
      key: const ValueKey('setup_done'),
      mainAxisSize: MainAxisSize.min,
      children: [
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: 1),
          duration: const Duration(milliseconds: 500),
          curve: Curves.elasticOut,
          builder: (_, v, child) => Transform.scale(scale: v, child: child),
          child: Container(
            padding: EdgeInsets.all(18.r),
            decoration: BoxDecoration(gradient: context.primaryGradient, shape: BoxShape.circle),
            child: Icon(CupertinoIcons.checkmark_alt, color: Colors.white, size: 34.sp),
          ),
        ),
        SizedBox(height: 16.h),
        _title("You're all set", 'Enjoy your Discover feed'),
        SizedBox(height: 8.h),
      ],
    );
  }
}

class _StepRow extends StatelessWidget {
  const _StepRow({required this.label, required this.done, required this.active});
  final String label;
  final bool done;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 5.h),
      child: Row(
        children: [
          SizedBox(
            width: 22.r,
            height: 22.r,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              transitionBuilder: (c, a) => ScaleTransition(scale: a, child: c),
              child: done
                  ? Icon(
                      CupertinoIcons.checkmark_circle_fill,
                      key: const ValueKey('done'),
                      color: context.primaryStart,
                      size: 22.r,
                    )
                  : active
                  ? CircularProgressIndicator(
                      key: const ValueKey('active'),
                      strokeWidth: 2.2,
                      color: context.primaryStart,
                    )
                  : Icon(
                      CupertinoIcons.circle,
                      key: const ValueKey('todo'),
                      color: context.onSurfaceVariantColor.withValues(alpha: 0.4),
                      size: 22.r,
                    ),
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 250),
              style: TextStyle(
                color: done || active ? context.onSurfaceColor : context.onSurfaceVariantColor,
                fontSize: 13.sp,
                fontWeight: active ? FontWeight.w600 : FontWeight.w400,
                fontFamily: 'Poppins',
              ),
              child: Text(label),
            ),
          ),
        ],
      ),
    );
  }
}

/// Rotating gradient ring with bouncing equalizer bars.
class _EqualizerRing extends StatefulWidget {
  const _EqualizerRing();

  @override
  State<_EqualizerRing> createState() => _EqualizerRingState();
}

class _EqualizerRingState extends State<_EqualizerRing> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = 84.r;
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) {
        final t = _c.value;
        return SizedBox(
          width: size,
          height: size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Transform.rotate(
                angle: t * 2 * math.pi,
                child: Container(
                  width: size,
                  height: size,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: SweepGradient(
                      colors: [
                        context.primaryStart,
                        context.primaryEnd,
                        context.primaryStart.withValues(alpha: 0.05),
                        context.primaryStart,
                      ],
                    ),
                  ),
                ),
              ),
              Container(
                width: size - 8.r,
                height: size - 8.r,
                decoration: BoxDecoration(color: context.surfaceColor, shape: BoxShape.circle),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  for (var i = 0; i < 5; i++)
                    Container(
                      margin: EdgeInsets.symmetric(horizontal: 2.w),
                      width: 5.w,
                      height: (10 + 18 * (0.5 + 0.5 * math.sin(2 * math.pi * (t * 2 + i * 0.18)))).h,
                      decoration: BoxDecoration(
                        gradient: context.primaryGradient,
                        borderRadius: BorderRadius.circular(3.r),
                      ),
                    ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

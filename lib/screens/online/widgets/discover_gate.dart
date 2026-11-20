import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../core/theme/theme_extension.dart';
import '../../app_settings/bloc/app_settings_bloc.dart';
import 'discover_setup_dialog.dart';
import 'region_pickers.dart';

/// Shows [child] only when the user is signed in (profile name) and has
/// finished the Discover setup (country, languages, tastes). Otherwise shows
/// a call to action that opens the one-step setup form.
class DiscoverGate extends StatelessWidget {
  const DiscoverGate({super.key, required this.child, this.fullScreen = true});

  final Widget child;
  final bool fullScreen;

  @override
  Widget build(BuildContext context) {
    final ready = context.select<AppSettingsBloc, bool>((b) => b.state.isDiscoverReady);
    if (ready) return child;
    final prompt = const DiscoverSetupPrompt();
    if (!fullScreen) return prompt;
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: context.backgroundGradient),
        child: SafeArea(
          child: Center(
            child: Padding(padding: EdgeInsets.all(24.w), child: prompt),
          ),
        ),
      ),
    );
  }
}

class DiscoverSetupPrompt extends StatelessWidget {
  const DiscoverSetupPrompt({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<AppSettingsBloc>().state;
    final missing = <String>[
      if (!settings.isProfileComplete) 'your name',
      if (!settings.hasMusicRegion) 'country & language',
      if (!settings.hasMusicTastes) 'your vibes',
    ];
    return Container(
      key: const ValueKey('discover_setup_prompt'),
      padding: EdgeInsets.all(20.r),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24.r),
        gradient: LinearGradient(
          colors: [
            context.primaryStart.withValues(alpha: 0.14),
            context.primaryEnd.withValues(alpha: 0.08),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: context.primaryStart.withValues(alpha: 0.25)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: EdgeInsets.all(14.r),
            decoration: BoxDecoration(gradient: context.primaryGradient, shape: BoxShape.circle),
            child: Icon(CupertinoIcons.sparkles, color: Colors.white, size: 26.sp),
          ),
          SizedBox(height: 12.h),
          Text(
            'Finish setting up Discover',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: context.onSurfaceColor,
              fontSize: 17.sp,
              fontWeight: FontWeight.w700,
              fontFamily: 'Poppins',
            ),
          ),
          SizedBox(height: 6.h),
          Text(
            missing.isEmpty
                ? 'Almost there'
                : 'Tell us ${missing.join(', ')} to unlock free music picked for you.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: context.onSurfaceVariantColor,
              fontSize: 12.5.sp,
              fontFamily: 'Poppins',
            ),
          ),
          SizedBox(height: 16.h),
          GradientButton(
            key: const ValueKey('discover_setup_open'),
            label: 'Set up Discover',
            icon: CupertinoIcons.arrow_right_circle_fill,
            onPressed: () => showDiscoverSetupDialog(context),
          ),
        ],
      ),
    );
  }
}

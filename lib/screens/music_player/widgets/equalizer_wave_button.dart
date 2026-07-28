import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lottie/lottie.dart';
import 'package:rhythmflow/core/theme/theme_extension.dart';
import 'package:rhythmflow/core/router/app_router.dart';
import 'package:rhythmflow/screens/equalizer/bloc/equalizer_bloc.dart';

class EqualizerWaveButton extends StatelessWidget {
  const EqualizerWaveButton({super.key});

  void _handleTap(BuildContext context) {
    HapticFeedback.lightImpact();
    context.read<EqualizerBloc>().add(
      const EqualizerEvent.persistEqualizerState(isEnabled: true),
    );
    context.navigateToEqualizer();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _handleTap(context),
      child: Container(
        width: 30.w,
        height: 30.w,
        padding: EdgeInsets.all(6.r),
        decoration: BoxDecoration(
          color: context.primaryStart.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8.r),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(4.r),
          child: Lottie.asset(
            'assets/animations/equalizer_wave.json',
            fit: BoxFit.contain,
            repeat: false,
            animate: true,
          ),
        ),
      ),
    );
  }
}

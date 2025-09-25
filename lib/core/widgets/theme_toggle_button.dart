import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../theme/theme_bloc.dart';
import '../theme/theme_extension.dart';

class ThemeToggleButton extends StatelessWidget {
  const ThemeToggleButton({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ThemeBloc, ThemeState>(
      builder: (context, state) {
        final themeBloc = context.read<ThemeBloc>();
        
        return Container(
          decoration: BoxDecoration(
            color: context.cardColor,
            borderRadius: BorderRadius.circular(20.r),
            boxShadow: [
              BoxShadow(
                color: context.isDark 
                    ? Colors.black.withValues(alpha: 0.3)
                    : Colors.black.withValues(alpha: 0.1),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: IconButton(
            icon: Icon(
              state.themeIcon,
              color: context.onSurfaceColor,
              size: 20.sp,
            ),
            onPressed: () {
              if (state.isFollowingSystem) {
                themeBloc.toggle();
              } else {
                // Cycle through: light -> dark -> system
                if (state.isDarkMode) {
                  themeBloc.followSystem();
                } else {
                  themeBloc.setDark();
                }
              }
            },
          ),
        );
      },
    );
  }
}

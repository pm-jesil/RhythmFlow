import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../core/theme/theme_extension.dart';
import '../screens/app_settings/bloc/app_settings_bloc.dart';
import '../../core/constants/app_constants.dart';
import 'package:go_router/go_router.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen>
    with TickerProviderStateMixin {
  final _nicknameController = TextEditingController();

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Curves.easeOutCubic,
          ),
        );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _nicknameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: GestureDetector(
        onTap: () {
          // Dismiss keyboard when tapping outside
          FocusScope.of(context).unfocus();
        },
        child: Container(
          decoration: BoxDecoration(gradient: context.backgroundGradient),
          child: SafeArea(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(24.w),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight:
                      MediaQuery.of(context).size.height -
                      MediaQuery.of(context).padding.top -
                      MediaQuery.of(context).padding.bottom -
                      48.h,
                ),
                child: IntrinsicHeight(
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: SlideTransition(
                      position: _slideAnimation,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Header Section
                          _buildHeader(),
                          SizedBox(height: 30.h),

                          // Content Section
                          _buildContent(),
                          SizedBox(height: 30.h),

                          // Navigation Section
                          _buildNavigation(),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        // App Logo
        Container(
          width: 80.w,
          height: 80.w,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20.r),
            boxShadow: [
              BoxShadow(
                color: context.primaryStart.withValues(alpha: 0.3),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20.r),
            child: _buildAppIcon(),
          ),
        ),
        SizedBox(height: 20.h),

        // App Title
        Text(
          'RhythmFlow',
          style: TextStyle(
            color: context.onSurfaceColor,
            fontSize: 25.sp,
            fontWeight: FontWeight.bold,
            fontFamily: 'Poppins',
          ),
        ),
        SizedBox(height: 8.h),

        // Subtitle
        Text(
          AppConstants.appTagline,
          style: TextStyle(
            color: context.onSurfaceVariantColor,
            fontSize: 14.sp,
            fontFamily: 'Poppins',
          ),
        ),
      ],
    );
  }

  Widget _buildAppIcon() {
    // Use app icon from assets
    return Image.asset(
      'assets/images/rhythmflow_icon_512x512.png',
      width: 80.w,
      height: 80.w,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        // Fallback to gradient container with app name if image fails to load
        return Container(
          decoration: BoxDecoration(
            gradient: context.primaryGradient,
            borderRadius: BorderRadius.circular(20.r),
          ),
          child: Center(
            child: Text(
              'RF',
              style: TextStyle(
                color: Colors.white,
                fontSize: 32.sp,
                fontWeight: FontWeight.bold,
                fontFamily: 'Poppins',
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildContent() {
    return Column(
      children: [
        // Welcome Illustration
        Container(
          width: 100.w,
          height: 100.w,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                context.primaryStart.withValues(alpha: 0.1),
                context.primaryEnd.withValues(alpha: 0.1),
              ],
            ),
            borderRadius: BorderRadius.circular(60.r),
          ),
          child: Icon(
            Icons.waving_hand_rounded,
            color: context.primaryStart,
            size: 50.sp,
          ),
        ),
        SizedBox(height: 30.h),

        // Welcome Text
        Text(
          'Welcome to RhythmFlow!',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: context.onSurfaceColor,
            fontSize: 26.sp,
            fontWeight: FontWeight.bold,
            fontFamily: 'Poppins',
            height: 1.2,
          ),
        ),
        SizedBox(height: 12.h),

        // Description
        Text(
          'Ready to discover your music?',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: context.onSurfaceVariantColor,
            fontSize: 14.sp,
            fontFamily: 'Poppins',
            height: 1.5,
          ),
        ),
        SizedBox(height: 40.h),

        // Nickname Field
        _buildNicknameField(),
        SizedBox(height: 24.h),
      ],
    );
  }

  Widget _buildNicknameField() {
    return TextFormField(
      controller: _nicknameController,
      onChanged: (value) {
        setState(() {}); // Rebuild to update button state
      },
      textInputAction: TextInputAction.done,
      onFieldSubmitted: (value) {
        if (value.trim().isNotEmpty) {
          _completeSetup();
        }
      },
      style: TextStyle(
        color: context.onSurfaceColor,
        fontSize: 16.sp,
        fontFamily: 'Poppins',
      ),
      decoration: InputDecoration(
        labelText: 'What should we call you?',
        hintText: 'Enter your nickname',
        prefixIcon: Icon(
          Icons.face_rounded,
          color: context.primaryStart,
          size: 20.sp,
        ),
        filled: true,
        fillColor: context.cardColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: BorderSide(
            color: context.onSurfaceVariantColor.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: BorderSide(color: context.primaryStart, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: BorderSide(color: context.error, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: BorderSide(color: context.error, width: 2),
        ),
        contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
        labelStyle: TextStyle(
          color: context.onSurfaceVariantColor,
          fontFamily: 'Poppins',
        ),
        hintStyle: TextStyle(
          color: context.onSurfaceVariantColor.withValues(alpha: 0.7),
          fontFamily: 'Poppins',
        ),
      ),
    );
  }

  Widget _buildNavigation() {
    final isNicknameEmpty = _nicknameController.text.trim().isEmpty;

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: isNicknameEmpty ? null : _completeSetup,
        style: ElevatedButton.styleFrom(
          padding: EdgeInsets.symmetric(vertical: 16.h),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.r),
          ),
          backgroundColor: isNicknameEmpty
              ? context.onSurfaceVariantColor.withValues(alpha: 0.3)
              : context.primaryStart,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Get Started',
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
                fontFamily: 'Poppins',
                color: isNicknameEmpty
                    ? context.onSurfaceVariantColor
                    : Colors.white,
              ),
            ),
            SizedBox(width: 8.w),
            Icon(
              Icons.arrow_forward_rounded,
              size: 20.sp,
              color: isNicknameEmpty
                  ? context.onSurfaceVariantColor
                  : Colors.white,
            ),
          ],
        ),
      ),
    );
  }

  void _completeSetup() {
    // Save user profile (using nickname for both fields)
    final nickname = _nicknameController.text.trim();
    context.read<AppSettingsBloc>().add(
      AppSettingsEvent.updateUserProfile(
        userName: nickname, // Use nickname as userName too
        nickName: nickname,
      ),
    );

    // Navigate to main app using GoRouter
    context.go('/');
  }
}

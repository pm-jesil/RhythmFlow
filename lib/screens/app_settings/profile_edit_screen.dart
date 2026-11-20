import 'package:flutter/material.dart';
import '../online/widgets/region_pickers.dart';
import '../online/widgets/taste_picker.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../core/theme/theme_extension.dart';
import 'bloc/app_settings_bloc.dart';
import '../../../core/widgets/app_custom.dart';

class ProfileEditScreen extends StatefulWidget {
  const ProfileEditScreen({super.key});

  @override
  State<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends State<ProfileEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final _userNameController = TextEditingController();
  final _nicknameController = TextEditingController();
  
  bool _isLoading = false;
  String _originalUserName = '';
  String _originalNickName = '';

  // Discover personalisation
  String? _musicCountry;
  List<String> _musicLanguages = const [];
  List<String> _musicTastes = const [];
  String _originalRegion = '';

  String get _regionKey =>
      '${_musicCountry ?? ''}|${_musicLanguages.join(',')}|${_musicTastes.join(',')}';

  @override
  void initState() {
    super.initState();
    _loadCurrentProfile();
  }

  void _loadCurrentProfile() {
    final state = context.read<AppSettingsBloc>().state;
    _originalUserName = state.userName ?? '';
    _originalNickName = state.nickName ?? '';
    _userNameController.text = _originalUserName;
    _nicknameController.text = _originalNickName;
    _musicCountry = state.musicCountry;
    _musicLanguages = state.musicLanguages;
    _musicTastes = state.musicTastes;
    _originalRegion = _regionKey;
    
    // Add listeners to detect changes
    _userNameController.addListener(_onTextChanged);
    _nicknameController.addListener(_onTextChanged);
  }

  void _onTextChanged() {
    setState(() {}); // Rebuild to update button state
  }

  bool _hasChanges() {
    final currentUserName = _userNameController.text.trim();
    final currentNickName = _nicknameController.text.trim();
    
    return currentUserName != _originalUserName || 
           currentNickName != _originalNickName ||
           _regionKey != _originalRegion;
  }

  bool _isFormValid() {
    final userName = _userNameController.text.trim();
    final nickName = _nicknameController.text.trim();
    
    return userName.isNotEmpty && 
           nickName.isNotEmpty && 
           userName.length >= 2 && 
           nickName.length >= 2;
  }

  bool _canUpdate() {
    return _hasChanges() && _isFormValid() && !_isLoading;
  }

  @override
  void dispose() {
    _userNameController.dispose();
    _nicknameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.backgroundColor,
      appBar: _buildAppBar(),
      body: _buildBody(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: Text(
        'Edit Profile',
        style: TextStyle(
          color: context.onSurfaceColor,
          fontSize: 17.sp,
          fontWeight: FontWeight.w600,
          fontFamily: 'Poppins',
        ),
      ),
      backgroundColor: context.backgroundColor,
      elevation: 0,
      centerTitle: true,
      leading: IconButton(
        icon: Icon(
          Icons.arrow_back_ios_rounded,
          color: context.onSurfaceColor,
          size: 20.sp,
        ),
        onPressed: () => Navigator.of(context).pop(),
      ),
    );
  }

  Widget _buildBody() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16.w),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Section
            _buildHeader(),
            SizedBox(height: 32.h),
            
            // Form Fields
            _buildFormFields(),
            SizedBox(height: 40.h),
            
            // Update Button
            _buildUpdateButton(),
            SizedBox(height: 20.h),
            
            // Info Card
            _buildInfoCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Personal Information',
          style: TextStyle(
            color: context.onSurfaceColor,
            fontSize: 24.sp,
            fontWeight: FontWeight.bold,
            fontFamily: 'Poppins',
          ),
        ),
        SizedBox(height: 8.h),
        Text(
          'Update your profile information',
          style: TextStyle(
            color: context.onSurfaceVariantColor,
            fontSize: 16.sp,
            fontFamily: 'Poppins',
          ),
        ),
      ],
    );
  }

  Widget _buildFormFields() {
    return Column(
      children: [
        // User Name Field
        _buildTextField(
          controller: _userNameController,
          label: 'User Name',
          hint: 'Enter your full name',
          icon: Icons.person_rounded,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please enter your name';
            }
            if (value.trim().length < 2) {
              return 'Name must be at least 2 characters';
            }
            return null;
          },
        ),
        SizedBox(height: 20.h),
        
        // Nickname Field
        _buildTextField(
          controller: _nicknameController,
          label: 'Nickname',
          hint: 'What should we call you?',
          icon: Icons.face_rounded,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Nickname is required';
            }
            if (value.trim().length < 2) {
              return 'Nickname must be at least 2 characters';
            }
            return null;
          },
        ),
        SizedBox(height: 20.h),

        // Discover personalisation
        RegionFields(
          country: _musicCountry,
          languages: _musicLanguages,
          onCountryChanged: (c) => setState(() => _musicCountry = c),
          onLanguagesChanged: (l) => setState(() => _musicLanguages = l),
        ),
        SizedBox(height: 12.h),
        TastesField(
          tastes: _musicTastes,
          onChanged: (t) => setState(() => _musicTastes = t),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required String? Function(String?) validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: context.onSurfaceColor,
            fontSize: 16.sp,
            fontWeight: FontWeight.w500,
            fontFamily: 'Poppins',
          ),
        ),
        SizedBox(height: 8.h),
        TextFormField(
          controller: controller,
          validator: validator,
          style: TextStyle(
            color: context.onSurfaceColor,
            fontSize: 16.sp,
            fontFamily: 'Poppins',
          ),
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(
              icon,
              color: context.primaryStart,
              size: 20.sp,
            ),
            filled: true,
            fillColor: context.surfaceColor,
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
              borderSide: BorderSide(
                color: context.primaryStart,
                width: 2,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: BorderSide(
                color: context.error,
                width: 1,
              ),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: BorderSide(
                color: context.error,
                width: 2,
              ),
            ),
            contentPadding: EdgeInsets.symmetric(
              horizontal: 16.w,
              vertical: 16.h,
            ),
            hintStyle: TextStyle(
              color: context.onSurfaceVariantColor.withValues(alpha: 0.7),
              fontFamily: 'Poppins',
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildUpdateButton() {
    final canUpdate = _canUpdate();
    
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: canUpdate ? _updateProfile : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: canUpdate 
              ? context.primaryStart 
              : context.onSurfaceVariantColor.withValues(alpha: 0.3),
          foregroundColor: canUpdate ? Colors.white : context.onSurfaceVariantColor,
          padding: EdgeInsets.symmetric(vertical: 16.h),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.r),
          ),
          elevation: 0,
        ),
        child: _isLoading
            ? SizedBox(
                height: 20.h,
                width: 20.w,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Text(
                'Update Profile',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Poppins',
                  color: canUpdate ? Colors.white : context.onSurfaceVariantColor,
                ),
              ),
      ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: context.primaryStart.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: context.primaryStart.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_rounded,
            color: context.primaryStart,
            size: 20.sp,
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Text(
              'Your nickname will be displayed in the For You screen',
              style: TextStyle(
                color: context.onSurfaceColor,
                fontSize: 14.sp,
                fontFamily: 'Poppins',
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _updateProfile() async {
    if (!_canUpdate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Update Discover country / languages
      if (_regionKey != _originalRegion &&
          (_musicCountry?.isNotEmpty ?? false) &&
          _musicLanguages.isNotEmpty) {
        context.read<AppSettingsBloc>().add(
          AppSettingsEvent.updateMusicRegion(
            country: _musicCountry!,
            languages: _musicLanguages,
          ),
        );
      }
      if (_musicTastes.isNotEmpty) {
        context.read<AppSettingsBloc>().add(
          AppSettingsEvent.updateMusicTastes(tastes: _musicTastes),
        );
      }

      // Update profile
      context.read<AppSettingsBloc>().add(
        AppSettingsEvent.updateUserProfile(
          userName: _userNameController.text.trim(),
          nickName: _nicknameController.text.trim(),
        ),
      );

      // Show success message
      AppCustom.success(context, 'Profile updated successfully!');

      // Navigate back
      Navigator.of(context).pop();
    } catch (e) {
      // Show error message
      AppCustom.error(context, 'Failed to update profile. Please try again.');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}

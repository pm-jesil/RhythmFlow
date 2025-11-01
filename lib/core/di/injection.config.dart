// dart format width=80
// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// InjectableConfigGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:flutter/material.dart' as _i409;
import 'package:get_it/get_it.dart' as _i174;
import 'package:injectable/injectable.dart' as _i526;

import '../../screens/app_settings/bloc/app_settings_bloc.dart' as _i558;
import '../../screens/bottom_tab/bloc/music_bloc.dart' as _i264;
import '../../utils/services/audio_service.dart' as _i333;
import '../../utils/services/remote_control_service.dart' as _i298;
import 'injection.dart' as _i464;

extension GetItInjectableX on _i174.GetIt {
  // initializes the registration of main-scope dependencies inside of GetIt
  _i174.GetIt init({
    String? environment,
    _i526.EnvironmentFilter? environmentFilter,
  }) {
    final gh = _i526.GetItHelper(this, environment, environmentFilter);
    final registerModule = _$RegisterModule();
    gh.singleton<_i409.GlobalKey<_i409.NavigatorState>>(
      () => registerModule.navigatorKey,
    );
    gh.singleton<_i558.AppSettingsBloc>(() => _i558.AppSettingsBloc());
    gh.singleton<_i333.AudioService>(() => _i333.AudioService());
    gh.singleton<_i298.RemoteControlService>(
      () => _i298.RemoteControlService(),
    );
    gh.singleton<_i264.MusicBloc>(
      () => _i264.MusicBloc(
        gh<_i333.AudioService>(),
        gh<_i298.RemoteControlService>(),
        gh<_i558.AppSettingsBloc>(),
      ),
    );
    return this;
  }
}

class _$RegisterModule extends _i464.RegisterModule {}

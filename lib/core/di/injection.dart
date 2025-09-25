import 'package:get_it/get_it.dart';
import 'package:injectable/injectable.dart';
import 'package:flutter/material.dart';
import 'injection.config.dart';

final getIt = GetIt.instance;

@InjectableInit(
  initializerName: 'init',
  preferRelativeImports: true,
  asExtension: true,
)
Future<void> configureDependencies() async => getIt.init();

@module
abstract class RegisterModule {
  @singleton
  GlobalKey<NavigatorState> get navigatorKey => GlobalKey<NavigatorState>();
}

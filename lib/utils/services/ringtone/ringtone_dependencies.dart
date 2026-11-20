import '../../../core/di/injection.dart';
import '../../../screens/online/bloc/online_library_bloc.dart';
import '../../../screens/ringtones/bloc/ringtone_library_bloc.dart';
import 'ringtone_service.dart';

/// Registers the ringtone maker (service + "My Ringtones" bloc) in GetIt.
class RingtoneDependencies {
  RingtoneDependencies._();

  /// Call after OnlineDependencies.init (reuses finished Discover downloads).
  static void init() {
    if (getIt.isRegistered<RingtoneService>()) return;
    final library = getIt.isRegistered<OnlineLibraryBloc>() ? getIt<OnlineLibraryBloc>() : null;
    final service = RingtoneService(
      downloadedPath: (songId) {
        final d = library?.state.downloads[songId];
        return d?.phase == DownloadPhase.completed ? d?.localPath : null;
      },
    );
    getIt.registerSingleton<RingtoneService>(service);
    final bloc = RingtoneLibraryBloc(exists: service.exists)..add(const RingtoneLibraryEvent.verify());
    getIt.registerSingleton<RingtoneLibraryBloc>(bloc);
  }
}

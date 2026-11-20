import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';

import '../../../utils/logger/logger.dart';
import '../../../utils/models/ringtone/ringtone_model.dart';

part 'ringtone_library_event.dart';
part 'ringtone_library_state.dart';
part 'ringtone_library_bloc.freezed.dart';

/// "My Ringtones": the ringtones the user made, newest first, and which one
/// is set as the phone ringtone / notification / alarm. Persisted with
/// HydratedBloc. File work happens in RingtoneService; this bloc only keeps
/// the list.
class RingtoneLibraryBloc extends HydratedBloc<RingtoneLibraryEvent, RingtoneLibraryState> {
  static final AppLogger _logger = AppLogger('RingtoneLibraryBloc');

  /// Checks whether a ringtone file still exists (injected for tests).
  final Future<bool> Function(RingtoneItem item)? exists;

  RingtoneLibraryBloc({this.exists}) : super(const RingtoneLibraryState()) {
    on<_Added>((event, emit) {
      emit(state.copyWith(items: [event.item, ...state.items.where((i) => i.id != event.item.id)]));
    });
    on<_Updated>((event, emit) {
      emit(state.copyWith(
        items: [for (final i in state.items) i.id == event.item.id ? event.item : i],
      ));
    });
    on<_Removed>((event, emit) {
      emit(state.copyWith(
        items: state.items.where((i) => i.id != event.id).toList(),
        defaults: Map.of(state.defaults)..removeWhere((_, id) => id == event.id),
      ));
    });
    on<_MarkedDefault>((event, emit) {
      emit(state.copyWith(defaults: {...state.defaults, event.use.name: event.id}));
    });
    on<_Verify>((event, emit) async {
      final check = exists;
      if (check == null || state.items.isEmpty) return;
      final missing = <String>{};
      for (final item in state.items) {
        try {
          if (!await check(item)) missing.add(item.id);
        } catch (_) {}
      }
      if (missing.isEmpty) return;
      _logger.i('🧹 Removing ${missing.length} ringtone(s) deleted outside the app');
      emit(state.copyWith(
        items: state.items.where((i) => !missing.contains(i.id)).toList(),
        defaults: Map.of(state.defaults)..removeWhere((_, id) => missing.contains(id)),
      ));
    });
  }

  @override
  String get storagePrefix => 'RingtoneLibraryBloc';

  @override
  Map<String, dynamic>? toJson(RingtoneLibraryState state) => {
    'items': state.items.map((i) => i.toJson()).toList(),
    'defaults': state.defaults,
  };

  @override
  RingtoneLibraryState? fromJson(Map<String, dynamic> json) {
    try {
      final items = (json['items'] as List? ?? const [])
          .whereType<Map>()
          .map((e) => RingtoneItem.fromJson(Map<String, dynamic>.from(e)))
          .toList();
      final defaults = <String, String>{};
      final raw = json['defaults'];
      if (raw is Map) raw.forEach((k, v) => defaults['$k'] = '$v');
      return RingtoneLibraryState(items: items, defaults: defaults);
    } catch (e) {
      _logger.w('⚠️ Could not restore ringtones: $e');
      return null;
    }
  }
}

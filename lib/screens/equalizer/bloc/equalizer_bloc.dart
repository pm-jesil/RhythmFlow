import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:injectable/injectable.dart';

import 'equalizer_preset_entry.dart';

part 'equalizer_event.dart';
part 'equalizer_state.dart';
part 'equalizer_bloc.freezed.dart';

@singleton
class EqualizerBloc extends HydratedBloc<EqualizerEvent, EqualizerState> {
  EqualizerBloc() : super(EqualizerState.initial()) {
    on<_PersistEqualizerState>(_onPersistEqualizerState);
    on<_CreateEqualizerPreset>(_onCreateEqualizerPreset);
    on<_UpdateEqualizerPresetGains>(_onUpdateEqualizerPresetGains);
    on<_DeleteEqualizerPreset>(_onDeleteEqualizerPreset);
    on<_PersistAudioEffectsState>(_onPersistAudioEffectsState);
    on<_ResetToDefaults>(_onResetToDefaults);
  }

  @override
  String get storagePrefix => 'EqualizerBloc';

  void _onPersistEqualizerState(
    _PersistEqualizerState event,
    Emitter<EqualizerState> emit,
  ) {
    emit(state.copyWith(
      isEqualizerEnabled: event.isEnabled,
      equalizerBandGains: event.bandGains ?? state.equalizerBandGains,
      equalizerSavedPresetId: event.presetId ?? state.equalizerSavedPresetId,
      equalizerSavedPresetName:
          event.presetName ?? state.equalizerSavedPresetName,
    ));
  }

  void _onCreateEqualizerPreset(
    _CreateEqualizerPreset event,
    Emitter<EqualizerState> emit,
  ) {
    final current = Map<String, EqualizerPresetEntry>.from(
      state.equalizerCustomPresets ?? {},
    );
    current[event.id] = EqualizerPresetEntry(
      id: event.id,
      name: event.name,
      gains: event.gains,
    );
    emit(state.copyWith(equalizerCustomPresets: current));
  }

  void _onUpdateEqualizerPresetGains(
    _UpdateEqualizerPresetGains event,
    Emitter<EqualizerState> emit,
  ) {
    final current = Map<String, EqualizerPresetEntry>.from(
      state.equalizerCustomPresets ?? {},
    );
    if (current.containsKey(event.id)) {
      current[event.id] = EqualizerPresetEntry(
        id: event.id,
        name: event.name,
        gains: event.gains,
      );
      emit(state.copyWith(equalizerCustomPresets: current));
    }
  }

  void _onDeleteEqualizerPreset(
    _DeleteEqualizerPreset event,
    Emitter<EqualizerState> emit,
  ) {
    final current = Map<String, EqualizerPresetEntry>.from(
      state.equalizerCustomPresets ?? {},
    );
    current.remove(event.id);
    emit(state.copyWith(
      equalizerCustomPresets: current.isEmpty ? null : current,
    ));
  }

  void _onPersistAudioEffectsState(
    _PersistAudioEffectsState event,
    Emitter<EqualizerState> emit,
  ) {
    emit(state.copyWith(
      reverbEnabled: event.reverbEnabled ?? state.reverbEnabled,
      reverbPreset: event.reverbPreset ?? state.reverbPreset,
      echoEnabled: event.echoEnabled ?? state.echoEnabled,
      echoStrength: event.echoStrength ?? state.echoStrength,
      virtualizerEnabled: event.virtualizerEnabled ?? state.virtualizerEnabled,
      virtualizerStrength:
          event.virtualizerStrength ?? state.virtualizerStrength,
      loudnessEnabled: event.loudnessEnabled ?? state.loudnessEnabled,
      loudnessGainMb: event.loudnessGainMb ?? state.loudnessGainMb,
      bassBoostEnabled: event.bassBoostEnabled ?? state.bassBoostEnabled,
      bassBoostStrength: event.bassBoostStrength ?? state.bassBoostStrength,
    ));
  }

  void _onResetToDefaults(
    _ResetToDefaults event,
    Emitter<EqualizerState> emit,
  ) {
    emit(EqualizerState.initial());
  }

  static Map<String, EqualizerPresetEntry> _parseEqualizerCustomPresets(
    Map<String, dynamic> json,
  ) {
    final result = <String, EqualizerPresetEntry>{};
    var i = 0;
    for (final entry in json.entries) {
      final k = entry.key.toString();
      final v = entry.value;
      if (v is Map) {
        result[k] = EqualizerPresetEntry.fromJson(
          Map<String, dynamic>.from(v),
        );
      } else if (v is List) {
        final name = k;
        final id = 'custom_${name.hashCode.abs()}_$i';
        i++;
        result[id] = EqualizerPresetEntry(
          id: id,
          name: name,
          gains: v.map((e) => (e as num).toDouble()).toList(),
        );
      }
    }
    return result;
  }

  @override
  Map<String, dynamic>? toJson(EqualizerState state) {
    try {
      return {
        'isEqualizerEnabled': state.isEqualizerEnabled,
        'equalizerBandGains': state.equalizerBandGains,
        'equalizerSavedPresetId': state.equalizerSavedPresetId,
        'equalizerSavedPresetName': state.equalizerSavedPresetName,
        'equalizerCustomPresets': state.equalizerCustomPresets != null
            ? state.equalizerCustomPresets!.map(
                (k, v) => MapEntry(k, v.toJson()),
              )
            : null,
        'reverbEnabled': state.reverbEnabled,
        'reverbPreset': state.reverbPreset,
        'echoEnabled': state.echoEnabled,
        'echoStrength': state.echoStrength,
        'virtualizerEnabled': state.virtualizerEnabled,
        'virtualizerStrength': state.virtualizerStrength,
        'loudnessEnabled': state.loudnessEnabled,
        'loudnessGainMb': state.loudnessGainMb,
        'bassBoostEnabled': state.bassBoostEnabled,
        'bassBoostStrength': state.bassBoostStrength,
      };
    } catch (_) {
      return null;
    }
  }

  @override
  EqualizerState? fromJson(Map<String, dynamic> json) {
    try {
      return EqualizerState(
        isEqualizerEnabled: json['isEqualizerEnabled'] ?? false,
        equalizerBandGains: json['equalizerBandGains'] != null
            ? Map<String, double>.from(
                (json['equalizerBandGains'] as Map).map(
                  (k, v) => MapEntry(k.toString(), (v as num).toDouble()),
                ),
              )
            : null,
        equalizerSavedPresetId: json['equalizerSavedPresetId'] as String?,
        equalizerSavedPresetName: json['equalizerSavedPresetName'] as String?,
        equalizerCustomPresets: json['equalizerCustomPresets'] != null
            ? _parseEqualizerCustomPresets(
                json['equalizerCustomPresets'] as Map<String, dynamic>,
              )
            : null,
        reverbEnabled: json['reverbEnabled'] ?? false,
        reverbPreset: json['reverbPreset'] ?? 0,
        echoEnabled: json['echoEnabled'] ?? false,
        echoStrength: json['echoStrength'] ?? 0,
        virtualizerEnabled: json['virtualizerEnabled'] ?? false,
        virtualizerStrength: json['virtualizerStrength'] ?? 0,
        loudnessEnabled: json['loudnessEnabled'] ?? false,
        loudnessGainMb: json['loudnessGainMb'] ?? 0,
        bassBoostEnabled: json['bassBoostEnabled'] ?? false,
        bassBoostStrength: json['bassBoostStrength'] ?? 0,
      );
    } catch (e) {
      return null;
    }
  }
}

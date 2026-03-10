part of 'equalizer_bloc.dart';

@freezed
class EqualizerEvent with _$EqualizerEvent {
  /// Persists equalizer state (enable/disable and/or band gains).
  /// presetId/Name: which preset is now the saved/current one.
  const factory EqualizerEvent.persistEqualizerState({
    required bool isEnabled,
    Map<String, double>? bandGains,
    String? presetId,
    String? presetName,
  }) = _PersistEqualizerState;

  /// Creates a NEW custom preset (Add flow). id must be unique.
  const factory EqualizerEvent.createEqualizerPreset({
    required String id,
    required String name,
    required List<double> gains,
  }) = _CreateEqualizerPreset;

  /// Updates an EXISTING custom preset's gains (Update button flow).
  const factory EqualizerEvent.updateEqualizerPresetGains({
    required String id,
    required String name,
    required List<double> gains,
  }) = _UpdateEqualizerPresetGains;

  /// Deletes a custom preset by id.
  const factory EqualizerEvent.deleteEqualizerPreset({
    required String id,
  }) = _DeleteEqualizerPreset;

  /// Persists audio effects state (reverb, echo, virtualizer, loudness, bass boost).
  const factory EqualizerEvent.persistAudioEffectsState({
    bool? reverbEnabled,
    int? reverbPreset,
    bool? echoEnabled,
    int? echoStrength,
    bool? virtualizerEnabled,
    int? virtualizerStrength,
    bool? loudnessEnabled,
    int? loudnessGainMb,
    bool? bassBoostEnabled,
    int? bassBoostStrength,
  }) = _PersistAudioEffectsState;

  /// Resets equalizer and sound effects to defaults.
  const factory EqualizerEvent.resetToDefaults() = _ResetToDefaults;
}

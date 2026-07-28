part of 'equalizer_bloc.dart';

@freezed
class EqualizerEvent with _$EqualizerEvent {
  /// Initializes screen session values from the saved preset, if needed.
  const factory EqualizerEvent.initializeSession() = _InitializeSession;

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
  const factory EqualizerEvent.deleteEqualizerPreset({required String id}) =
      _DeleteEqualizerPreset;

  /// Persists preset + band gains + all effect values in one atomic update.
  const factory EqualizerEvent.commitSelection({
    required bool isEnabled,
    required Map<String, double> bandGains,
    required String presetId,
    required String presetName,
    required int echoStrength,
    required int virtualizerStrength,
    required int loudnessGainMb,
    required int bassBoostStrength,
  }) = _CommitSelection;

  /// Resets equalizer and sound effects to defaults.
  const factory EqualizerEvent.resetToDefaults() = _ResetToDefaults;
}

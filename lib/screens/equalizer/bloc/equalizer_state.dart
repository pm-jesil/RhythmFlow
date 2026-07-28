part of 'equalizer_bloc.dart';

@freezed
abstract class EqualizerState with _$EqualizerState {
  const factory EqualizerState({
    @Default(false) bool isEqualizerEnabled,
    @Default(null) Map<String, double>? equalizerBandGains,
    @Default(null) Map<String, EqualizerPresetEntry>? equalizerCustomPresets,
    @Default(null) String? equalizerSavedPresetId,
    @Default(null) String? equalizerSavedPresetName,
    // Audio effects (Android)
    @Default(false) bool echoEnabled,
    @Default(0) int echoStrength,
    @Default(false) bool virtualizerEnabled,
    @Default(0) int virtualizerStrength,
    @Default(false) bool loudnessEnabled,
    @Default(0) int loudnessGainMb,
    @Default(false) bool bassBoostEnabled,
    @Default(0) int bassBoostStrength,
  }) = _EqualizerState;

  factory EqualizerState.initial() => const EqualizerState(
        isEqualizerEnabled: false,
        equalizerBandGains: null,
        equalizerCustomPresets: null,
        equalizerSavedPresetId: 'flat',
        equalizerSavedPresetName: 'Flat',
        echoEnabled: false,
        echoStrength: 0,
        virtualizerEnabled: false,
        virtualizerStrength: 0,
        loudnessEnabled: false,
        loudnessGainMb: 0,
        bassBoostEnabled: false,
        bassBoostStrength: 0,
      );
}

part of 'ringtone_library_bloc.dart';

@freezed
abstract class RingtoneLibraryEvent with _$RingtoneLibraryEvent {
  const factory RingtoneLibraryEvent.added(RingtoneItem item) = _Added;

  /// Renamed (or otherwise changed) ringtone.
  const factory RingtoneLibraryEvent.updated(RingtoneItem item) = _Updated;

  const factory RingtoneLibraryEvent.removed(String id) = _Removed;

  /// [id] was set as the phone's [use] sound.
  const factory RingtoneLibraryEvent.markedDefault({
    required String id,
    required RingtoneUse use,
  }) = _MarkedDefault;

  /// Drops ringtones whose files were deleted outside the app.
  const factory RingtoneLibraryEvent.verify() = _Verify;
}

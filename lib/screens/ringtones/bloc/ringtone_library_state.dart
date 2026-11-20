part of 'ringtone_library_bloc.dart';

@freezed
abstract class RingtoneLibraryState with _$RingtoneLibraryState {
  const RingtoneLibraryState._();

  const factory RingtoneLibraryState({
    @Default(<RingtoneItem>[]) List<RingtoneItem> items,

    /// RingtoneUse.name -> ringtone id set from the app.
    @Default(<String, String>{}) Map<String, String> defaults,
  }) = _RingtoneLibraryState;

  int get count => items.length;

  RingtoneItem? byId(String id) {
    for (final i in items) {
      if (i.id == id) return i;
    }
    return null;
  }

  /// What [id] is currently set as (from this app).
  List<RingtoneUse> usesOf(String id) =>
      RingtoneUse.values.where((u) => defaults[u.name] == id).toList();

  Iterable<String> get names => items.map((i) => i.name);
}

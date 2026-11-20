import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../utils/models/ringtone/ringtone_model.dart';
import '../../../utils/models/song/song_model.dart';
import '../../../utils/services/ringtone/ringtone_service.dart';
import 'ringtone_library_bloc.dart';

part 'ringtone_editor_cubit.freezed.dart';

enum RingtoneEditorPhase { preparing, ready, saving, saved, error }

@freezed
abstract class RingtoneEditorState with _$RingtoneEditorState {
  const RingtoneEditorState._();

  const factory RingtoneEditorState({
    @Default(RingtoneEditorPhase.preparing) RingtoneEditorPhase phase,

    /// Download progress of a Discover song (null = not downloading).
    double? progress,
    String? sourcePath,
    @Default(Duration.zero) Duration songLength,
    @Default(Duration.zero) Duration start,
    @Default(RingtoneService.defaultLength) Duration end,
    String? error,

    /// A save error; the editor stays usable.
    String? saveError,
    RingtoneItem? saved,
  }) = _RingtoneEditorState;

  Duration get length => end - start;
  String? get selectionError => RingtoneService.validateSelection(start, end, songLength);
  bool get canSave => phase == RingtoneEditorPhase.ready && selectionError == null;
  bool get isDownloading => phase == RingtoneEditorPhase.preparing && progress != null;
}

/// Drives the ringtone editor: prepares the song (auto-download for
/// Discover), keeps the trim range valid and saves the ringtone.
class RingtoneEditorCubit extends Cubit<RingtoneEditorState> {
  final Song song;
  final RingtoneService service;
  final RingtoneLibraryBloc library;

  /// Where the song was when the editor opened (the selection starts there).
  final Duration? initialPosition;

  /// Fine-tune step of the -/+ buttons.
  static const Duration nudgeStep = Duration(milliseconds: 500);

  RingtoneEditorCubit({
    required this.song,
    required this.service,
    required this.library,
    this.initialPosition,
  }) : super(const RingtoneEditorState());

  Future<void> prepare() async {
    final reason = RingtoneService.unavailableReason(song);
    if (reason != null) {
      emit(state.copyWith(phase: RingtoneEditorPhase.error, error: reason));
      return;
    }
    emit(state.copyWith(phase: RingtoneEditorPhase.preparing, error: null, progress: song.isOnline ? 0 : null));
    try {
      final path = await service.prepareSource(
        song,
        onProgress: (p) {
          if (!isClosed && state.phase == RingtoneEditorPhase.preparing) {
            emit(state.copyWith(progress: p));
          }
        },
      );
      if (isClosed) return;
      final (start, end) = RingtoneService.defaultSelection(song.duration, position: initialPosition);
      emit(state.copyWith(
        phase: RingtoneEditorPhase.ready,
        sourcePath: path,
        progress: null,
        songLength: song.duration,
        start: start,
        end: end,
      ));
    } on RingtoneException catch (e) {
      if (!isClosed) emit(state.copyWith(phase: RingtoneEditorPhase.error, error: e.message, progress: null));
    } catch (_) {
      if (!isClosed) {
        emit(state.copyWith(
          phase: RingtoneEditorPhase.error,
          error: 'Could not open this song',
          progress: null,
        ));
      }
    }
  }

  /// The preview player found the real length (song metadata can be 0 or
  /// slightly off).
  void lengthDetected(Duration length) {
    if (length <= Duration.zero || length == state.songLength) return;
    final hadNoLength = state.songLength <= Duration.zero;
    var start = state.start;
    var end = state.end;
    if (hadNoLength) {
      (start, end) = RingtoneService.defaultSelection(length, position: initialPosition);
    } else {
      if (end > length) end = length;
      if (start > end - RingtoneService.minLength) {
        start = end - RingtoneService.minLength;
        if (start < Duration.zero) start = Duration.zero;
      }
    }
    emit(state.copyWith(songLength: length, start: start, end: end));
  }

  Duration get _maxEnd => state.songLength > Duration.zero ? state.songLength : const Duration(days: 1);

  /// Moves the start; the end follows to keep the length within limits.
  void setStart(Duration value) {
    var start = _clamp(value, Duration.zero, _maxEnd - RingtoneService.minLength);
    var end = state.end;
    if (end - start < RingtoneService.minLength) end = start + RingtoneService.minLength;
    if (end - start > RingtoneService.maxLength) end = start + RingtoneService.maxLength;
    if (end > _maxEnd) end = _maxEnd;
    if (start < Duration.zero) start = Duration.zero;
    _setRange(start, end);
  }

  /// Moves the end; the start follows to keep the length within limits.
  void setEnd(Duration value) {
    var end = _clamp(value, RingtoneService.minLength, _maxEnd);
    var start = state.start;
    if (end - start < RingtoneService.minLength) start = end - RingtoneService.minLength;
    if (end - start > RingtoneService.maxLength) start = end - RingtoneService.maxLength;
    if (start < Duration.zero) start = Duration.zero;
    _setRange(start, end);
  }

  void nudgeStart(int direction) => setStart(state.start + nudgeStep * direction);
  void nudgeEnd(int direction) => setEnd(state.end + nudgeStep * direction);

  void _setRange(Duration start, Duration end) {
    if (state.phase != RingtoneEditorPhase.ready) return;
    emit(state.copyWith(start: start, end: end, saveError: null));
  }

  static Duration _clamp(Duration v, Duration lo, Duration hi) => v < lo ? lo : (v > hi ? hi : v);

  /// Cuts and saves; on success the ringtone is added to "My Ringtones".
  Future<RingtoneItem?> save(String name) async {
    if (!state.canSave || state.sourcePath == null) return null;
    emit(state.copyWith(phase: RingtoneEditorPhase.saving, saveError: null));
    try {
      final safe = RingtoneService.sanitizeName(name, fallback: '${song.displayTitle} ringtone');
      final item = await service.create(
        song: song,
        sourcePath: state.sourcePath!,
        start: state.start,
        end: state.end,
        name: RingtoneService.uniqueName(safe, library.state.names),
        songLength: state.songLength,
      );
      library.add(RingtoneLibraryEvent.added(item));
      if (!isClosed) emit(state.copyWith(phase: RingtoneEditorPhase.saved, saved: item));
      return item;
    } on RingtoneException catch (e) {
      if (!isClosed) emit(state.copyWith(phase: RingtoneEditorPhase.ready, saveError: e.message));
    } catch (_) {
      if (!isClosed) {
        emit(state.copyWith(phase: RingtoneEditorPhase.ready, saveError: 'Could not save the ringtone'));
      }
    }
    return null;
  }
}

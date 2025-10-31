import 'song/song_model.dart';

class MyPlayerStateModel {
  final String? playlistId;
  final List<String> currentPlayList;
  final String? currentSongId;
  final String? previousSongId;
  final List<String> completedSongs;
  final int repeatModeIndex; // 0: off, 1: repeat+1, 2: loop
  final String filterKeyword; // Current search/filter keyword
  final bool isShuffle;
  final bool isPlaying;
  final Duration? lastPosition;

  const MyPlayerStateModel({
    this.playlistId,
    this.currentPlayList = const [],
    this.currentSongId,
    this.previousSongId,
    this.completedSongs = const [],
    this.repeatModeIndex = 0,
    this.filterKeyword = '',
    this.isShuffle = false,
    this.isPlaying = false,
    this.lastPosition,
  });

  // Copy with method for state updates
  MyPlayerStateModel copyWith({
    String? playlistId,
    List<String>? currentPlayList,
    String? currentSongId,
    String? previousSongId,
    List<String>? completedSongs,
    int? repeatModeIndex,
    String? filterKeyword,
    bool? isShuffle,
    bool? isPlaying,
    Duration? lastPosition,
  }) {
    return MyPlayerStateModel(
      playlistId: playlistId ?? this.playlistId,
      currentPlayList: currentPlayList ?? this.currentPlayList,
      currentSongId: currentSongId ?? this.currentSongId,
      previousSongId: previousSongId ?? this.previousSongId,
      completedSongs: completedSongs ?? this.completedSongs,
      repeatModeIndex: repeatModeIndex ?? this.repeatModeIndex,
      filterKeyword: filterKeyword ?? this.filterKeyword,
      isShuffle: isShuffle ?? this.isShuffle,
      isPlaying: isPlaying ?? this.isPlaying,
      lastPosition: lastPosition ?? this.lastPosition,
    );
  }

  // Helper methods
  bool get isEmpty => currentPlayList.isEmpty && currentSongId == null;
  bool get hasSongs => currentPlayList.isNotEmpty;
  int get remainingSongs => currentPlayList.length;
  int get completedCount => completedSongs.length;
  
  // Repeat mode helpers
  bool get isRepeatOff => repeatModeIndex == 0;
  bool get isRepeatOne => repeatModeIndex == 1;
  bool get isLoop => repeatModeIndex == 2;
  
  // Get repeat mode description
  String get repeatModeDescription {
    switch (repeatModeIndex) {
      case 0: return 'Off';
      case 1: return 'Repeat One';
      case 2: return 'Loop';
      default: return 'Off';
    }
  }

  // Get next song based on repeat settings and add current to completed
  // This is used ONLY when a song completes playing (respects repeat mode)
  MyPlayerStateModel nextSong() {
    if (currentPlayList.isEmpty || currentSongId == null) return this;
    
    // If repeat one mode, check previousSongId to determine behavior
    if (isRepeatOne) {
      // If previousSongId == currentSongId, it means we just repeated this song
      // Now we should play the next song and add current to completed
      if (previousSongId == currentSongId) {
        // Already repeated once - now play next song
        final currentIndex = currentPlayList.indexOf(currentSongId!);
        if (currentIndex >= 0 && currentIndex < currentPlayList.length - 1) {
          final nextSongId = currentPlayList[currentIndex + 1];
          return _addCurrentToCompletedAndSetNext(nextSongId);
        }
        // At end of playlist - can't play next
        return this;
      } else {
        // First time completing - repeat the same song and update previousSongId
        return copyWith(
          currentSongId: currentSongId,
          previousSongId: currentSongId, // Update previousSongId to current
        );
      }
    }
    
    // If loop mode (repeat all), loop back to first song if at end, otherwise play next
    final currentIndex = currentPlayList.indexOf(currentSongId!);
    if (isLoop) {
      if (currentIndex >= 0 && currentIndex < currentPlayList.length - 1) {
        // Not at end - play next song
        final nextSongId = currentPlayList[currentIndex + 1];
        return _addCurrentToCompletedAndSetNext(nextSongId);
      } else {
        // At end of playlist - loop back to first song
        final firstSongId = currentPlayList.first;
        return _addCurrentToCompletedAndSetNext(firstSongId);
      }
    }
    
    // Normal mode (repeat off) - play next song and add current to completed
    if (currentIndex >= 0 && currentIndex < currentPlayList.length - 1) {
      final nextSongId = currentPlayList[currentIndex + 1];
      return _addCurrentToCompletedAndSetNext(nextSongId);
    }
    
    return this;
  }

  // Get next song IGNORING repeat mode - used for Next button
  // This always moves to the next song in playlist and adds current to completed
  // If at end of playlist, loops back to first song (ignoring repeat mode)
  MyPlayerStateModel nextSongIgnoringRepeat() {
    if (currentPlayList.isEmpty || currentSongId == null) return this;
    
    // Always play next song and add current to completed (ignore repeat mode)
    final currentIndex = currentPlayList.indexOf(currentSongId!);
    if (currentIndex >= 0 && currentIndex < currentPlayList.length - 1) {
      // Not at end - play next song
      final nextSongId = currentPlayList[currentIndex + 1];
      return _addCurrentToCompletedAndSetNext(nextSongId);
    } else if (currentIndex >= 0 && currentPlayList.length > 1) {
      // At end of playlist - loop back to first song (ignore repeat mode)
      final firstSongId = currentPlayList.first;
      return _addCurrentToCompletedAndSetNext(firstSongId);
    }
    
    // Only one song in playlist - can't move to next
    return this;
  }

  // Get previous song from completed songs (songs stay in playlist)
  MyPlayerStateModel previousSong() {
    if (completedSongs.isEmpty) return this;
    
    // Get the last completed song (most recently completed)
    final lastCompletedSong = completedSongs.last;
    
    final newCompletedSongs = List<String>.from(completedSongs);
    
    // Remove the last completed song from completed list
    newCompletedSongs.removeLast();
    
    return copyWith(
      completedSongs: newCompletedSongs,
      currentSongId: lastCompletedSong,
      previousSongId: currentSongId,
    );
  }

  // Helper method to add current song to completed and set next song (KEEP in playlist)
  MyPlayerStateModel _addCurrentToCompletedAndSetNext(String nextSongId) {
    if (currentSongId == null || currentPlayList.isEmpty) return this;
    
    final newCompletedSongs = List<String>.from(completedSongs);
    
    // Add to completed songs (avoid duplication) - KEEP in currentPlayList
    if (!newCompletedSongs.contains(currentSongId)) {
      newCompletedSongs.add(currentSongId!);
    }
    
    return copyWith(
      completedSongs: newCompletedSongs,
      currentSongId: nextSongId,
      previousSongId: currentSongId,
    );
  }

  // Add current song to completed (KEEP in playlist)
  MyPlayerStateModel moveCurrentToCompleted() {
    if (currentSongId == null || currentPlayList.isEmpty) return this;
    
    final newCompletedSongs = List<String>.from(completedSongs);
    
    // Add to completed songs (avoid duplication) - KEEP in currentPlayList
    if (!newCompletedSongs.contains(currentSongId)) {
      newCompletedSongs.add(currentSongId!);
    }
    
    return copyWith(
      completedSongs: newCompletedSongs,
      currentSongId: null,
      previousSongId: currentSongId,
    );
  }

  // Shuffle current playlist
  MyPlayerStateModel shufflePlaylist() {
    if (currentPlayList.isEmpty) return this;
    
    final shuffledList = List<String>.from(currentPlayList);
    shuffledList.shuffle();
    
    return copyWith(currentPlayList: shuffledList);
  }

  // AI Shuffle - intelligently reorder playlist based on current song features
  MyPlayerStateModel aiShufflePlaylist(List<String> reorderedPlaylist) {
    if (reorderedPlaylist.isEmpty) return this;
    
    return copyWith(currentPlayList: reorderedPlaylist);
  }

  // Revert shuffle - restore original order based on playlistId
  // Then reorder to start with current playing song
  MyPlayerStateModel revertShuffle(List<String> originalOrder) {
    if (currentPlayList.isEmpty) return this;
    
    // Keep only songs that are still in current playlist
    final revertedList = originalOrder.where((songId) => currentPlayList.contains(songId)).toList();
    
    // If there's a current song, reorder to start with it
    if (currentSongId != null && revertedList.contains(currentSongId)) {
      return copyWith(currentPlayList: revertedList).reorderToStartWith(currentSongId!);
    }
    
    return copyWith(currentPlayList: revertedList);
  }

  // Reorder playlist to start with the specified song
  // Tapped song becomes first, then songs after it, then songs before it
  // If currentSongId is changing, preserve it as previousSongId
  MyPlayerStateModel reorderToStartWith(String songId) {
    if (currentPlayList.isEmpty || !currentPlayList.contains(songId)) {
      return this;
    }
    
    final currentIndex = currentPlayList.indexOf(songId);
    if (currentIndex == 0) {
      // Song is already first, no need to reorder
      return this;
    }
    
    // Create new playlist: [tappedSong, songsAfterTapped, songsBeforeTapped]
    final newPlaylist = <String>[];
    
    // Add the tapped song first (it will be the current playing song)
    newPlaylist.add(songId);
    
    // Add songs that come AFTER the tapped song (in original order)
    for (int i = currentIndex + 1; i < currentPlayList.length; i++) {
      newPlaylist.add(currentPlayList[i]);
    }
    
    // Add songs that come BEFORE the tapped song (in original order)
    for (int i = 0; i < currentIndex; i++) {
      newPlaylist.add(currentPlayList[i]);
    }
    
    // If currentSongId is changing, update previousSongId
    // Otherwise preserve existing previousSongId
    final shouldUpdatePrevious = currentSongId != null && currentSongId != songId;
    
    return copyWith(
      currentPlayList: newPlaylist,
      currentSongId: songId,
      previousSongId: shouldUpdatePrevious ? currentSongId : previousSongId,
    );
  }

  // Clear all
  MyPlayerStateModel clear() {
    return const MyPlayerStateModel();
  }

  // Cycle through repeat modes: 0 -> 1 -> 2 -> 0
  MyPlayerStateModel cycleRepeatMode() {
    final newRepeatModeIndex = (repeatModeIndex + 1) % 3;
    return copyWith(repeatModeIndex: newRepeatModeIndex);
  }

  // Filter song IDs based on current filter keyword
  List<String> getFilteredSongIds(List<String> songIds, List<Song> actualSongList) {
    if (filterKeyword.isEmpty) {
      return songIds;
    }
    
    // Create a map for quick song lookup
    final songMap = {for (var song in actualSongList) song.id: song};
    
    // Filter song IDs based on keyword
    return songIds.where((songId) {
      final song = songMap[songId];
      if (song == null) return false;
      
      final keyword = filterKeyword.toLowerCase();
      return song.title.toLowerCase().contains(keyword) ||
             song.artists.join(', ').toLowerCase().contains(keyword) ||
             song.albums.join(', ').toLowerCase().contains(keyword);
    }).toList();
  }

  @override
  String toString() {
    return 'MyPlayerStateModel(playlistId: $playlistId, currentPlayList: ${currentPlayList.length}, currentSongId: $currentSongId, repeatModeIndex: $repeatModeIndex, filterKeyword: "$filterKeyword")';
  }
}

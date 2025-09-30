import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/theme/theme_extension.dart';
import '../../utils/models/playlist_source/playlist_source_model.dart';
import '../../utils/models/song/song_model.dart';
import '../../utils/models/artist/artist_model.dart';
import '../../utils/models/album/album_model.dart';
import '../bottom_tab/screens/bloc/music_bloc.dart';

/// Common sorting utility for song lists
class SortingHelper {
  /// Shows the sorting menu with options
  static void showSortingMenu(BuildContext context) {
    final currentSortingIndex = context.read<MusicBloc>().state.sortingIndex;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: context.surfaceColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: context.onSurfaceVariantColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Sort Songs',
              style: TextStyle(
                color: context.onSurfaceColor,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...MusicBloc.sortingOptions.asMap().entries.map((entry) {
              final index = entry.key;
              final title = entry.value;
              return _buildSortOption(
                context,
                title,
                index,
                currentSortingIndex,
              );
            }),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  /// Shows sorting menu with custom callback for handling sort selection
  static void showSortingMenuWithCallback(
    BuildContext context, {
    required Function(int sortingIndex) onSortSelected,
  }) {
    final currentSortingIndex = context.read<MusicBloc>().state.sortingIndex;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: context.surfaceColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: context.onSurfaceVariantColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Sort Songs',
              style: TextStyle(
                color: context.onSurfaceColor,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...MusicBloc.sortingOptions.asMap().entries.map((entry) {
              final index = entry.key;
              final title = entry.value;
              return _buildSortOptionWithCallback(
                context,
                title,
                index,
                currentSortingIndex,
                onSortSelected,
              );
            }),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  static Widget _buildSortOption(
    BuildContext context,
    String title,
    int index,
    int currentSortingIndex,
  ) {
    final isSelected = currentSortingIndex == index;

    return ListTile(
      leading: Icon(
        _getSortIcon(index),
        color: isSelected ? context.primaryStart : context.onSurfaceVariantColor,
      ),
      title: Text(
        title,
        style: TextStyle(
          color: isSelected ? context.primaryStart : context.onSurfaceColor,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      trailing: isSelected
          ? Icon(Icons.check, color: context.primaryStart)
          : null,
      onTap: () {
        Navigator.pop(context);
        context.read<MusicBloc>().add(
          MusicEvent.changeSortingOrder(
            sortingIndex: index,
            sortingList: context.read<MusicBloc>().state.allSongs.map((s) => s.id).toList(),
            playlistSource: PlaylistSource.allSongs(),
          ),
        );
      },
    );
  }

  static Widget _buildSortOptionWithCallback(
    BuildContext context,
    String title,
    int index,
    int currentSortingIndex,
    Function(int) onSortSelected,
  ) {
    final isSelected = currentSortingIndex == index;

    return ListTile(
      leading: Icon(
        _getSortIcon(index),
        color: isSelected ? context.primaryStart : context.onSurfaceVariantColor,
      ),
      title: Text(
        title,
        style: TextStyle(
          color: isSelected ? context.primaryStart : context.onSurfaceColor,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      trailing: isSelected
          ? Icon(Icons.check, color: context.primaryStart)
          : null,
      onTap: () {
        Navigator.pop(context);
        onSortSelected(index);
      },
    );
  }

  static IconData _getSortIcon(int index) {
    switch (index) {
      case 0:
        return Icons.new_releases;
      case 1:
        return Icons.history;
      case 2:
        return Icons.sort_by_alpha;
      case 3:
        return Icons.timer;
      case 4:
        return Icons.timer_off;
      default:
        return Icons.sort;
    }
  }

  /// Applies sorting to a list of songs
  static List<Song> applySorting(List<Song> songs, int sortingIndex) {
    List<Song> result = List.from(songs);

    switch (sortingIndex) {
      case 0: // Newest First
        result.sort(
          (a, b) => (b.dateAdded ?? DateTime.now()).compareTo(
            a.dateAdded ?? DateTime.now(),
          ),
        );
        break;
      case 1: // Oldest First
        result.sort(
          (a, b) => (a.dateAdded ?? DateTime.now()).compareTo(
            b.dateAdded ?? DateTime.now(),
          ),
        );
        break;
      case 2: // Alphabetical
        result.sort(
          (a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()),
        );
        break;
      case 3: // Duration (Shortest)
        result.sort((a, b) => a.duration.compareTo(b.duration));
        break;
      case 4: // Duration (Longest)
        result.sort((a, b) => b.duration.compareTo(a.duration));
        break;
    }

    return result;
  }

  /// Applies sorting to songs by play count (descending)
  static List<Song> sortByPlayCount(List<Song> songs, {bool ascending = false}) {
    List<Song> result = List.from(songs);
    if (ascending) {
      result.sort((a, b) => (a.playCount ?? 0).compareTo(b.playCount ?? 0));
    } else {
      result.sort((a, b) => (b.playCount ?? 0).compareTo(a.playCount ?? 0));
    }
    return result;
  }

  /// Applies sorting to songs by date added (newest first by default)
  static List<Song> sortByDateAdded(List<Song> songs, {bool newestFirst = true}) {
    List<Song> result = List.from(songs);
    if (newestFirst) {
      result.sort((a, b) => (b.dateAdded ?? DateTime(1970)).compareTo(
        a.dateAdded ?? DateTime(1970),
      ));
    } else {
      result.sort((a, b) => (a.dateAdded ?? DateTime(1970)).compareTo(
        b.dateAdded ?? DateTime(1970),
      ));
    }
    return result;
  }

  /// Applies sorting to songs by title (alphabetical)
  static List<Song> sortByTitle(List<Song> songs, {bool ascending = true}) {
    List<Song> result = List.from(songs);
    if (ascending) {
      result.sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
    } else {
      result.sort((a, b) => b.title.toLowerCase().compareTo(a.title.toLowerCase()));
    }
    return result;
  }

  /// Applies sorting to songs by duration
  static List<Song> sortByDuration(List<Song> songs, {bool shortestFirst = true}) {
    List<Song> result = List.from(songs);
    if (shortestFirst) {
      result.sort((a, b) => a.duration.compareTo(b.duration));
    } else {
      result.sort((a, b) => b.duration.compareTo(a.duration));
    }
    return result;
  }

  /// Applies sorting to songs by artist name
  static List<Song> sortByArtist(List<Song> songs, {bool ascending = true}) {
    List<Song> result = List.from(songs);
    if (ascending) {
      result.sort((a, b) => a.artists.first.toLowerCase().compareTo(
        b.artists.first.toLowerCase(),
      ));
    } else {
      result.sort((a, b) => b.artists.first.toLowerCase().compareTo(
        a.artists.first.toLowerCase(),
      ));
    }
    return result;
  }

  /// Applies sorting to songs by album name
  static List<Song> sortByAlbum(List<Song> songs, {bool ascending = true}) {
    List<Song> result = List.from(songs);
    if (ascending) {
      result.sort((a, b) => a.albums.first.toLowerCase().compareTo(
        b.albums.first.toLowerCase(),
      ));
    } else {
      result.sort((a, b) => b.albums.first.toLowerCase().compareTo(
        a.albums.first.toLowerCase(),
      ));
    }
    return result;
  }

  /// Applies sorting to songs by last played date (most recent first by default)
  static List<Song> sortByLastPlayed(List<Song> songs, {bool mostRecentFirst = true}) {
    List<Song> result = List.from(songs);
    if (mostRecentFirst) {
      result.sort((a, b) => (b.lastPlayed ?? DateTime(1970)).compareTo(
        a.lastPlayed ?? DateTime(1970),
      ));
    } else {
      result.sort((a, b) => (a.lastPlayed ?? DateTime(1970)).compareTo(
        b.lastPlayed ?? DateTime(1970),
      ));
    }
    return result;
  }

  /// Applies sorting to songs by file size
  static List<Song> sortByFileSize(List<Song> songs, {bool smallestFirst = true}) {
    List<Song> result = List.from(songs);
    if (smallestFirst) {
      result.sort((a, b) => (a.fileSize ?? 0).compareTo(b.fileSize ?? 0));
    } else {
      result.sort((a, b) => (b.fileSize ?? 0).compareTo(a.fileSize ?? 0));
    }
    return result;
  }

  /// Applies sorting to songs by bitrate
  static List<Song> sortByBitrate(List<Song> songs, {bool lowestFirst = true}) {
    List<Song> result = List.from(songs);
    if (lowestFirst) {
      result.sort((a, b) => (a.bitrate ?? 0).compareTo(b.bitrate ?? 0));
    } else {
      result.sort((a, b) => (b.bitrate ?? 0).compareTo(a.bitrate ?? 0));
    }
    return result;
  }

  /// Applies sorting to songs by year
  static List<Song> sortByYear(List<Song> songs, {bool oldestFirst = true}) {
    List<Song> result = List.from(songs);
    if (oldestFirst) {
      result.sort((a, b) => (a.year ?? 0).compareTo(b.year ?? 0));
    } else {
      result.sort((a, b) => (b.year ?? 0).compareTo(a.year ?? 0));
    }
    return result;
  }

  /// Applies sorting to songs by genre
  static List<Song> sortByGenre(List<Song> songs, {bool ascending = true}) {
    List<Song> result = List.from(songs);
    if (ascending) {
      result.sort((a, b) => (a.genre ?? '').toLowerCase().compareTo(
        (b.genre ?? '').toLowerCase(),
      ));
    } else {
      result.sort((a, b) => (b.genre ?? '').toLowerCase().compareTo(
        (a.genre ?? '').toLowerCase(),
      ));
    }
    return result;
  }

  /// Applies sorting to songs by track number
  static List<Song> sortByTrackNumber(List<Song> songs, {bool ascending = true}) {
    List<Song> result = List.from(songs);
    if (ascending) {
      result.sort((a, b) => (a.trackNumber ?? 0).compareTo(b.trackNumber ?? 0));
    } else {
      result.sort((a, b) => (b.trackNumber ?? 0).compareTo(a.trackNumber ?? 0));
    }
    return result;
  }

  /// Applies sorting to songs by disc number
  static List<Song> sortByDiscNumber(List<Song> songs, {bool ascending = true}) {
    List<Song> result = List.from(songs);
    if (ascending) {
      result.sort((a, b) => (a.discNumber ?? 0).compareTo(b.discNumber ?? 0));
    } else {
      result.sort((a, b) => (b.discNumber ?? 0).compareTo(a.discNumber ?? 0));
    }
    return result;
  }

  /// Applies sorting to songs by composer
  static List<Song> sortByComposer(List<Song> songs, {bool ascending = true}) {
    List<Song> result = List.from(songs);
    if (ascending) {
      result.sort((a, b) => (a.composer ?? '').toLowerCase().compareTo(
        (b.composer ?? '').toLowerCase(),
      ));
    } else {
      result.sort((a, b) => (b.composer ?? '').toLowerCase().compareTo(
        (a.composer ?? '').toLowerCase(),
      ));
    }
    return result;
  }

  /// Applies sorting to songs by album artist
  static List<Song> sortByAlbumArtist(List<Song> songs, {bool ascending = true}) {
    List<Song> result = List.from(songs);
    if (ascending) {
      result.sort((a, b) => (a.albumArtist ?? '').toLowerCase().compareTo(
        (b.albumArtist ?? '').toLowerCase(),
      ));
    } else {
      result.sort((a, b) => (b.albumArtist ?? '').toLowerCase().compareTo(
        (a.albumArtist ?? '').toLowerCase(),
      ));
    }
    return result;
  }

  /// Applies sorting to songs by favorite status (favorites first by default)
  static List<Song> sortByFavorite(List<Song> songs, {bool favoritesFirst = true}) {
    List<Song> result = List.from(songs);
    if (favoritesFirst) {
      result.sort((a, b) => ((b.isFavorite ?? false) ? 1 : 0).compareTo((a.isFavorite ?? false) ? 1 : 0));
    } else {
      result.sort((a, b) => ((a.isFavorite ?? false) ? 1 : 0).compareTo((b.isFavorite ?? false) ? 1 : 0));
    }
    return result;
  }

  /// Applies sorting to songs by multiple criteria (primary, secondary, tertiary)
  static List<Song> sortByMultipleCriteria(
    List<Song> songs, {
    required String primarySort,
    String? secondarySort,
    String? tertiarySort,
    Map<String, bool> sortDirections = const {},
  }) {
    List<Song> result = List.from(songs);
    
    result.sort((a, b) {
      int comparison = 0;
      
      // Primary sort
      comparison = _compareByCriteria(a, b, primarySort, sortDirections[primarySort] ?? true);
      if (comparison != 0) return comparison;
      
      // Secondary sort
      if (secondarySort != null) {
        comparison = _compareByCriteria(a, b, secondarySort, sortDirections[secondarySort] ?? true);
        if (comparison != 0) return comparison;
      }
      
      // Tertiary sort
      if (tertiarySort != null) {
        comparison = _compareByCriteria(a, b, tertiarySort, sortDirections[tertiarySort] ?? true);
      }
      
      return comparison;
    });
    
    return result;
  }

  /// Applies sorting to artists by play count (descending by default)
  static List<Artist> sortArtistsByPlayCount(List<Artist> artists, {bool ascending = false}) {
    List<Artist> result = List.from(artists);
    if (ascending) {
      result.sort((a, b) => (a.playCount ?? 0).compareTo(b.playCount ?? 0));
    } else {
      result.sort((a, b) => (b.playCount ?? 0).compareTo(a.playCount ?? 0));
    }
    return result;
  }

  /// Applies sorting to albums by play count (descending by default)
  static List<Album> sortAlbumsByPlayCount(List<Album> albums, {bool ascending = false}) {
    List<Album> result = List.from(albums);
    if (ascending) {
      result.sort((a, b) => (a.playCount ?? 0).compareTo(b.playCount ?? 0));
    } else {
      result.sort((a, b) => (b.playCount ?? 0).compareTo(a.playCount ?? 0));
    }
    return result;
  }

  /// Applies sorting to artists by name (alphabetical)
  static List<Artist> sortArtistsByName(List<Artist> artists, {bool ascending = true}) {
    List<Artist> result = List.from(artists);
    if (ascending) {
      result.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    } else {
      result.sort((a, b) => b.name.toLowerCase().compareTo(a.name.toLowerCase()));
    }
    return result;
  }

  /// Applies sorting to albums by name (alphabetical)
  static List<Album> sortAlbumsByName(List<Album> albums, {bool ascending = true}) {
    List<Album> result = List.from(albums);
    if (ascending) {
      result.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    } else {
      result.sort((a, b) => b.name.toLowerCase().compareTo(a.name.toLowerCase()));
    }
    return result;
  }

  /// Applies sorting to artists by song count (descending by default)
  static List<Artist> sortArtistsBySongCount(List<Artist> artists, {bool ascending = false}) {
    List<Artist> result = List.from(artists);
    if (ascending) {
      result.sort((a, b) => a.songIds.length.compareTo(b.songIds.length));
    } else {
      result.sort((a, b) => b.songIds.length.compareTo(a.songIds.length));
    }
    return result;
  }

  /// Applies sorting to albums by song count (descending by default)
  static List<Album> sortAlbumsBySongCount(List<Album> albums, {bool ascending = false}) {
    List<Album> result = List.from(albums);
    if (ascending) {
      result.sort((a, b) => a.songIds.length.compareTo(b.songIds.length));
    } else {
      result.sort((a, b) => b.songIds.length.compareTo(a.songIds.length));
    }
    return result;
  }

  /// Helper method for multi-criteria sorting
  static int _compareByCriteria(Song a, Song b, String criteria, bool ascending) {
    switch (criteria.toLowerCase()) {
      case 'title':
        return ascending 
          ? a.title.toLowerCase().compareTo(b.title.toLowerCase())
          : b.title.toLowerCase().compareTo(a.title.toLowerCase());
      case 'artist':
        return ascending 
          ? a.artists.first.toLowerCase().compareTo(b.artists.first.toLowerCase())
          : b.artists.first.toLowerCase().compareTo(a.artists.first.toLowerCase());
      case 'album':
        return ascending 
          ? a.albums.first.toLowerCase().compareTo(b.albums.first.toLowerCase())
          : b.albums.first.toLowerCase().compareTo(a.albums.first.toLowerCase());
      case 'duration':
        return ascending 
          ? a.duration.compareTo(b.duration)
          : b.duration.compareTo(a.duration);
      case 'playcount':
        return ascending 
          ? (a.playCount ?? 0).compareTo(b.playCount ?? 0)
          : (b.playCount ?? 0).compareTo(a.playCount ?? 0);
      case 'dateadded':
        return ascending 
          ? (a.dateAdded ?? DateTime(1970)).compareTo(b.dateAdded ?? DateTime(1970))
          : (b.dateAdded ?? DateTime(1970)).compareTo(a.dateAdded ?? DateTime(1970));
      case 'lastplayed':
        return ascending 
          ? (a.lastPlayed ?? DateTime(1970)).compareTo(b.lastPlayed ?? DateTime(1970))
          : (b.lastPlayed ?? DateTime(1970)).compareTo(a.lastPlayed ?? DateTime(1970));
      case 'year':
        return ascending 
          ? (a.year ?? 0).compareTo(b.year ?? 0)
          : (b.year ?? 0).compareTo(a.year ?? 0);
      case 'filesize':
        return ascending 
          ? (a.fileSize ?? 0).compareTo(b.fileSize ?? 0)
          : (b.fileSize ?? 0).compareTo(a.fileSize ?? 0);
      case 'bitrate':
        return ascending 
          ? (a.bitrate ?? 0).compareTo(b.bitrate ?? 0)
          : (b.bitrate ?? 0).compareTo(a.bitrate ?? 0);
      case 'tracknumber':
        return ascending 
          ? (a.trackNumber ?? 0).compareTo(b.trackNumber ?? 0)
          : (b.trackNumber ?? 0).compareTo(a.trackNumber ?? 0);
      case 'discnumber':
        return ascending 
          ? (a.discNumber ?? 0).compareTo(b.discNumber ?? 0)
          : (b.discNumber ?? 0).compareTo(a.discNumber ?? 0);
      case 'genre':
        return ascending 
          ? (a.genre ?? '').toLowerCase().compareTo((b.genre ?? '').toLowerCase())
          : (b.genre ?? '').toLowerCase().compareTo((a.genre ?? '').toLowerCase());
      case 'composer':
        return ascending 
          ? (a.composer ?? '').toLowerCase().compareTo((b.composer ?? '').toLowerCase())
          : (b.composer ?? '').toLowerCase().compareTo((a.composer ?? '').toLowerCase());
      case 'albumartist':
        return ascending 
          ? (a.albumArtist ?? '').toLowerCase().compareTo((b.albumArtist ?? '').toLowerCase())
          : (b.albumArtist ?? '').toLowerCase().compareTo((a.albumArtist ?? '').toLowerCase());
      case 'favorite':
        return ascending 
          ? ((a.isFavorite ?? false) ? 1 : 0).compareTo((b.isFavorite ?? false) ? 1 : 0)
          : ((b.isFavorite ?? false) ? 1 : 0).compareTo((a.isFavorite ?? false) ? 1 : 0);
      default:
        return 0;
    }
  }
}

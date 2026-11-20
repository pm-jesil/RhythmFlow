import '../../utils/models/album/album_model.dart';
import '../../utils/models/artist/artist_model.dart';

/// Pure helpers used by the Albums / Artists tabs to derive the visible list
/// from the current bloc state on every build.
///
/// The screens previously cached the list the first time it became non-empty
/// and never refreshed it, so albums/artists added or removed by a library
/// scan did not appear until the app was restarted.
class LibraryFilterHelper {
  LibraryFilterHelper._();

  static List<Album> filterAlbums(List<Album> albums, String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return albums;
    return albums.where((a) => a.name.toLowerCase().contains(q)).toList();
  }

  static List<Artist> filterArtists(List<Artist> artists, String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return artists;
    return artists.where((a) => a.name.toLowerCase().contains(q)).toList();
  }
}

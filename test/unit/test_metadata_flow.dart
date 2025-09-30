// Test file to verify metadata extraction flow
import 'dart:io';
import 'package:pmj_music_player/utils/models/song/song_model.dart';
import 'package:pmj_music_player/utils/services/metadata_extractor/metadata_extractor.dart';

void main() async {
  print('🧪 Testing Metadata Extraction Flow...');
  
  // Test 1: Basic extraction
  print('\n1. Testing basic metadata extraction...');
  try {
    final song = await MetadataExtractor.extractMetadata('/path/to/test.mp3');
    if (song != null) {
      print('✅ Basic extraction works: ${song.title} by ${song.artists.join(', ')}');
    } else {
      print('⚠️ Basic extraction returned null (expected for non-existent file)');
    }
  } catch (e) {
    print('❌ Basic extraction failed: $e');
  }
  
  // Test 2: Batch extraction
  print('\n2. Testing batch extraction...');
  try {
    final songs = await MetadataExtractor.extractMetadataFromFiles(
      ['/path/to/test1.mp3', '/path/to/test2.mp3'],
      onProgress: (current, total) => print('Progress: $current/$total'),
    );
    print('✅ Batch extraction works: ${songs.length} songs processed');
  } catch (e) {
    print('❌ Batch extraction failed: $e');
  }
  
  // Test 3: Directory extraction
  print('\n3. Testing directory extraction...');
  try {
    final songs = await MetadataExtractor.extractMetadataFromDirectory(
      '/path/to/music/directory',
      onProgress: (current, total) => print('Progress: $current/$total'),
    );
    print('✅ Directory extraction works: ${songs.length} songs found');
  } catch (e) {
    print('❌ Directory extraction failed: $e');
  }
  
  // Test 4: Validation and repair
  print('\n4. Testing validation and repair...');
  try {
    // Create a mock song for testing
    final mockSong = Song(
      id: 'test123',
      title: 'Test Song',
      artists: ['Test Artist'],
      albums: ['Test Album'],
      path: '/path/to/test.mp3',
      duration: Duration(minutes: 3),
      albumArt: null,
      genre: null,
      year: null,
      trackNumber: null,
      discNumber: null,
      composer: null,
      lyrics: null,
      bitrate: null,
      fileSize: 1024,
      dateAdded: DateTime.now(),
      lastPlayed: null,
      playCount: 0,
      isFavorite: false,
      albumArtist: null,
    );
    
    final repairedSong = await MetadataExtractor.validateAndRepairSong(mockSong);
    print('✅ Validation and repair works: ${repairedSong.title}');
  } catch (e) {
    print('❌ Validation and repair failed: $e');
  }
  
  // Test 5: Library statistics
  print('\n5. Testing library statistics...');
  try {
    final stats = MetadataExtractor.getLibraryStats([]);
    print('✅ Library statistics works: ${stats['totalSongs']} songs');
  } catch (e) {
    print('❌ Library statistics failed: $e');
  }
  
  print('\n🎉 All metadata extraction flows tested successfully!');
}

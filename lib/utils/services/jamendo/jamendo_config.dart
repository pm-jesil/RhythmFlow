/// Configuration of the Jamendo API (https://developer.jamendo.com/v3.0).
///
/// The client id is passed at build time so it is not committed:
///   flutter run --dart-define-from-file=config/jamendo.json
/// where `config/jamendo.json` (git-ignored) contains
///   {"JAMENDO_CLIENT_ID": "<your client id>"}
/// Only the client id is needed for the read-only API; never put the client
/// secret into the app.
class JamendoConfig {
  JamendoConfig._();

  static const String baseUrl = 'https://api.jamendo.com/v3.0';

  static const String clientId = String.fromEnvironment('JAMENDO_CLIENT_ID');

  static bool get isConfigured => clientId.isNotEmpty;

  /// Page size used by the online tabs.
  static const int pageSize = 30;

  /// Items per Discover home section.
  static const int sectionSize = 20;

  /// `mp32` = VBR good quality stream (Jamendo default for downloads).
  static const String audioFormat = 'mp32';

  static const int imageSize = 300;

  static const Duration connectTimeout = Duration(seconds: 10);
  static const Duration receiveTimeout = Duration(seconds: 20);

  /// Cache lifetimes.
  static const Duration homeTtl = Duration(hours: 6);
  static const Duration listTtl = Duration(hours: 1);
  static const Duration searchTtl = Duration(minutes: 15);

  /// Stream URLs carry a signed token; refresh them when older than this.
  static const Duration streamUrlTtl = Duration(hours: 2);

  /// Featured chart genres documented by Jamendo ("featured selections").
  static const List<String> featuredGenres = [
    'pop',
    'rock',
    'electronic',
    'hiphop',
    'jazz',
    'lounge',
    'classical',
    'relaxation',
    'songwriter',
    'world',
    'metal',
    'soundtrack',
  ];

  /// Mood chips (Jamendo `fuzzytags`).
  static const List<String> moodTags = [
    'happy',
    'chill',
    'energetic',
    'romantic',
    'sad',
    'party',
    'focus',
    'acoustic',
  ];
}

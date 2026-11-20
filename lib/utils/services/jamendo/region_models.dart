import 'region_data.dart';

/// A country that has artists on Jamendo.
class MusicCountry {
  final String alpha2;
  final String alpha3;
  final String name;
  final String flag;
  final int artistCount;

  const MusicCountry({
    required this.alpha2,
    required this.alpha3,
    required this.name,
    required this.flag,
    required this.artistCount,
  });
}

/// A language for "picks in your language".
///
/// Jamendo's own `lang` filter returns nothing, so language picks are built
/// from the language [tag] (Jamendo `fuzzytags`, empty when the language has
/// no tagged tracks) and from artists located in [countries] (alpha-3).
class MusicLanguage {
  final String code;
  final String name;
  final String nativeName;
  final String tag;
  final List<String> countries;

  const MusicLanguage({
    required this.code,
    required this.name,
    required this.nativeName,
    required this.tag,
    required this.countries,
  });

  /// English is the default language of most Jamendo vocal music, which is
  /// mostly untagged, so it maps to the global catalogue.
  bool get isGlobal => code == 'en';

  String get label => nativeName == name ? name : '$name · $nativeName';
}

class MusicRegions {
  MusicRegions._();

  static List<MusicCountry> get countries => jamendoCountries;
  static List<MusicLanguage> get languages => jamendoLanguages;

  static MusicCountry? countryByAlpha2(String? code) {
    if (code == null) return null;
    final upper = code.toUpperCase();
    for (final c in jamendoCountries) {
      if (c.alpha2 == upper) return c;
    }
    return null;
  }

  static MusicLanguage? languageByCode(String? code) {
    if (code == null) return null;
    final lower = code.toLowerCase();
    for (final l in jamendoLanguages) {
      if (l.code == lower) return l;
    }
    return null;
  }

  /// Case-insensitive search on English name, native name and code.
  static List<MusicCountry> searchCountries(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return jamendoCountries;
    return jamendoCountries
        .where(
          (c) =>
              c.name.toLowerCase().contains(q) ||
              c.alpha2.toLowerCase() == q ||
              c.alpha3.toLowerCase() == q,
        )
        .toList();
  }

  static List<MusicLanguage> searchLanguages(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return jamendoLanguages;
    return jamendoLanguages
        .where(
          (l) =>
              l.name.toLowerCase().contains(q) ||
              l.nativeName.toLowerCase().contains(q) ||
              l.code == q,
        )
        .toList();
  }

  /// Best guess from the device locale (e.g. `ml_IN`), only used to
  /// pre-select values in the pickers. No network call is made.
  static ({MusicCountry? country, MusicLanguage? language}) suggestFromLocale(
    String? languageCode,
    String? countryCode,
  ) {
    return (
      country: countryByAlpha2(countryCode),
      language: languageByCode(languageCode),
    );
  }
}

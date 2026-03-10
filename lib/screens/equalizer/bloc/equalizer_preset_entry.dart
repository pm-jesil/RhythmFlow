/// Custom preset with unique id and name.
class EqualizerPresetEntry {
  final String id;
  final String name;
  final List<double> gains;

  const EqualizerPresetEntry({
    required this.id,
    required this.name,
    required this.gains,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'gains': gains,
      };

  factory EqualizerPresetEntry.fromJson(Map<String, dynamic> j) =>
      EqualizerPresetEntry(
        id: j['id'] as String? ?? '',
        name: j['name'] as String? ?? '',
        gains: (j['gains'] as List?)
                ?.map((e) => (e as num).toDouble())
                .toList() ??
            [],
      );
}

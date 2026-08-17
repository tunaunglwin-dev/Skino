import 'skin_concern.dart';

class SkinZone {
  const SkinZone({
    required this.key,
    required this.label,
    required this.concerns,
    required this.score,
    required this.oiliness,
    required this.darkSpots,
    required this.redness,
    required this.texture,
    required this.dryness,
  });

  final String key;
  final String label;
  final List<SkinConcern> concerns;
  final int score;
  final double oiliness;
  final double darkSpots;
  final double redness;
  final double texture;
  final double dryness;

  factory SkinZone.fromJson(Map<String, dynamic> json) {
    final concernItems = json['concerns'] as List<dynamic>? ?? const [];

    return SkinZone(
      key: json['key']?.toString() ?? '',
      label: json['label']?.toString() ?? 'Skin zone',
      concerns: concernItems
          .map((item) => SkinConcern.fromJson(item as Map<String, dynamic>))
          .toList(),
      score: int.parse((json['score'] ?? 0).toString()),
      oiliness: double.parse((json['oiliness'] ?? 0).toString()),
      darkSpots: double.parse((json['dark_spots'] ?? 0).toString()),
      redness: double.parse((json['redness'] ?? 0).toString()),
      texture: double.parse((json['texture'] ?? 0).toString()),
      dryness: double.parse((json['dryness'] ?? 0).toString()),
    );
  }
}

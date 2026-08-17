import 'recommended_product.dart';
import 'skin_concern.dart';
import 'skin_zone.dart';
import 'treatment_package.dart';

class SkinAnalysisResult {
  const SkinAnalysisResult({
    required this.id,
    required this.skinType,
    required this.skinTypeConfidence,
    required this.concerns,
    required this.skinZones,
    required this.acneSeverity,
    required this.skinHealthScore,
    required this.recommendedProducts,
    required this.treatmentPackage,
    required this.createdAt,
    this.scanQuality,
  });

  final int? id;
  final String skinType;
  final double skinTypeConfidence;
  final List<SkinConcern> concerns;
  final List<SkinZone> skinZones;
  final ScanQuality? scanQuality;
  final String acneSeverity;
  final int skinHealthScore;
  final List<RecommendedProduct> recommendedProducts;
  final TreatmentPackage? treatmentPackage;
  final DateTime? createdAt;

  factory SkinAnalysisResult.fromJson(Map<String, dynamic> json) {
    final concernItems = json['concerns'] as List<dynamic>? ?? const [];
    final zoneItems = json['skin_zones'] as List<dynamic>? ?? const [];
    final productItems =
        json['recommended_products'] as List<dynamic>? ?? const [];

    return SkinAnalysisResult(
      id: int.tryParse(json['id']?.toString() ?? ''),
      skinType: json['skin_type']?.toString() ?? 'unknown',
      skinTypeConfidence: double.parse(
        (json['skin_type_confidence'] ?? 0).toString(),
      ),
      concerns: concernItems
          .map((item) => SkinConcern.fromJson(item as Map<String, dynamic>))
          .toList(),
      skinZones: zoneItems
          .map((item) => SkinZone.fromJson(item as Map<String, dynamic>))
          .toList(),
      scanQuality: json['scan_quality'] is Map<String, dynamic>
          ? ScanQuality.fromJson(json['scan_quality'] as Map<String, dynamic>)
          : null,
      acneSeverity: json['acne_severity']?.toString() ?? 'none',
      skinHealthScore: int.parse((json['skin_health_score'] ?? 0).toString()),
      recommendedProducts: productItems
          .map(
            (item) => RecommendedProduct.fromJson(item as Map<String, dynamic>),
          )
          .toList(),
      treatmentPackage: json['treatment_package'] is Map<String, dynamic>
          ? TreatmentPackage.fromJson(
              json['treatment_package'] as Map<String, dynamic>,
            )
          : null,
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? ''),
    );
  }
}

class ScanQuality {
  const ScanQuality({
    required this.level,
    required this.brightness,
    required this.skinCoverage,
    required this.faceCentering,
    required this.message,
  });

  final String level;
  final double brightness;
  final double skinCoverage;
  final double faceCentering;
  final String message;

  bool get needsRetake => level == 'low' || level == 'medium';

  factory ScanQuality.fromJson(Map<String, dynamic> json) {
    return ScanQuality(
      level: json['level']?.toString() ?? 'good',
      brightness: double.tryParse(json['brightness']?.toString() ?? '') ?? 0,
      skinCoverage:
          double.tryParse(json['skin_coverage']?.toString() ?? '') ?? 0,
      faceCentering:
          double.tryParse(json['face_centering']?.toString() ?? '') ?? 1,
      message: json['message']?.toString() ?? '',
    );
  }
}

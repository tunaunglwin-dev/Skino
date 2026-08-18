import 'package:flutter/material.dart';

import '../../../../core/skino_assets.dart';
import '../../../../core/skino_image_icon.dart';
import '../../../../core/skino_text.dart';
import '../../models/skin_analysis_result.dart';
import '../../models/treatment_package.dart';

class AnalysisResultPanel extends StatelessWidget {
  const AnalysisResultPanel({
    required this.result,
    required this.text,
    super.key,
  });

  final SkinAnalysisResult result;
  final SkinoText text;

  @override
  Widget build(BuildContext context) {
    final score = result.skinHealthScore.clamp(0, 100);
    final routine = result.treatmentPackage;
    final quality = result.scanQuality;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFFFE3D1)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1A123C36),
            blurRadius: 24,
            offset: Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ResultHero(
            text: text,
            score: score,
            skinType: result.skinType,
            confidence: result.skinTypeConfidence,
            quality: quality,
          ),
          const SizedBox(height: 18),
          _SeverityBanner(severity: result.acneSeverity, text: text),
          const SizedBox(height: 12),
          _ScanQualitySummary(
            quality: quality,
            confidence: result.skinTypeConfidence,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const SkinoImageIcon.inline(
                asset: SkinoAssets.iconReport,
                size: 24,
                backgroundColor: Color(0xFFFFF3EC),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  text.detectedConcerns,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF282420),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: result.concerns.isEmpty
                ? [_ConcernChip(label: text.noStrongConcern)]
                : result.concerns
                      .take(3)
                      .map(
                        (concern) => _ConcernChip(
                          label: text.concernLabel(concern.name),
                          detail:
                              '${(concern.confidence * 100).round()}% ${text.severityLabel(concern.severity)}',
                        ),
                      )
                      .toList(),
          ),
          const SizedBox(height: 14),
          if (routine == null)
            _EmptyBeautyRoutine(text: text)
          else
            _BeautyRoutineCard(routine: routine, text: text),
        ],
      ),
    );
  }
}

class _ResultHero extends StatelessWidget {
  const _ResultHero({
    required this.text,
    required this.score,
    required this.skinType,
    required this.confidence,
    required this.quality,
  });

  final SkinoText text;
  final int score;
  final String skinType;
  final double confidence;
  final ScanQuality? quality;

  @override
  Widget build(BuildContext context) {
    final needsRetake = quality?.needsRetake ?? confidence < 0.6;
    final title = needsRetake
        ? (text.isMyanmar
              ? 'ပြန်စကင်ရင် ပိုတိကျမယ်'
              : 'Retake for a cleaner result')
        : (text.isMyanmar
              ? 'Result ဖတ်ပြီးပါပြီ'
              : 'Your scan result is ready');
    final subtitle = needsRetake
        ? (quality?.message.isNotEmpty == true
              ? quality!.message
              : (text.isMyanmar
                    ? 'အလင်း၊ focus သို့မဟုတ် မျက်နှာအနေအထားကို ပြန်စစ်ပါ။'
                    : 'Check light, focus, and face position before trusting this scan.'))
        : text.skinTypeConfidence((confidence * 100).round());

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: needsRetake ? const Color(0xFFFFF3EC) : const Color(0xFFEAF6F1),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: needsRetake
              ? const Color(0xFFFFD0B3)
              : const Color(0xFFBFE6D7),
        ),
      ),
      child: Row(
        children: [
          _ScoreRing(score: score, warn: needsRetake),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SectionKicker(text.latestScan),
                const SizedBox(height: 5),
                Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xFF282420),
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    height: 1.18,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${text.concernLabel(skinType)} skin • $subtitle',
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF625B53),
                    fontWeight: FontWeight.w600,
                    height: 1.32,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          const SkinoImageIcon.page(
            asset: SkinoAssets.resultMascot,
            size: 64,
            backgroundColor: Colors.white,
            borderRadius: 20,
          ),
        ],
      ),
    );
  }
}

class _SeverityBanner extends StatelessWidget {
  const _SeverityBanner({required this.severity, required this.text});

  final String severity;
  final SkinoText text;

  @override
  Widget build(BuildContext context) {
    final normalized = severity.toLowerCase();
    final isClear = normalized == 'none';
    final label = isClear
        ? text.noAcneDetected
        : text.acneSeverityTitle(normalized);
    final detail = switch (normalized) {
      'severe' => text.severeAcneHint,
      'moderate' => text.moderateAcneHint,
      'mild' => text.mildAcneHint,
      _ => text.clearAcneHint,
    };

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isClear ? const Color(0xFFEAF6F1) : const Color(0xFFFFF3EC),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isClear ? const Color(0xFFBFE6D7) : const Color(0xFFFFD0B3),
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: isClear
                ? const Color(0xFF0E5C56)
                : const Color(0xFFF98128),
            child: isClear
                ? const Icon(Icons.check_rounded, color: Colors.white)
                : const SkinoImageIcon(
                    asset: SkinoAssets.resultMascot,
                    size: 34,
                    padding: 2,
                    backgroundColor: Colors.white,
                    borderRadius: 14,
                  ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: Color(0xFF282420),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  detail,
                  style: const TextStyle(
                    color: Color(0xFF68625B),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ScoreRing extends StatelessWidget {
  const _ScoreRing({required this.score, this.warn = false});

  final int score;
  final bool warn;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 82,
      height: 82,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CircularProgressIndicator(
            value: score / 100,
            strokeWidth: 8,
            strokeCap: StrokeCap.round,
            backgroundColor: const Color(0xFFE8E1D7),
            color: warn ? const Color(0xFFF98128) : const Color(0xFF0E5C56),
          ),
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: warn ? const Color(0xFFF98128) : const Color(0xFF0E5C56),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '$score',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const Text(
                  'score',
                  style: TextStyle(
                    fontSize: 9,
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ScanQualitySummary extends StatelessWidget {
  const _ScanQualitySummary({required this.quality, required this.confidence});

  final ScanQuality? quality;
  final double confidence;

  @override
  Widget build(BuildContext context) {
    final confidencePercent = (confidence * 100).round();
    final qualityLevel = quality?.level ?? 'preview';
    final brightness = quality == null
        ? null
        : '${(quality!.brightness * 100).round()}% light';
    final coverage = quality == null
        ? null
        : '${(quality!.skinCoverage * 100).round()}% face';

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _ResultInfoChip(
          icon: Icons.verified_outlined,
          label: '$confidencePercent% confidence',
          tone: confidencePercent >= 70
              ? const Color(0xFF0E5C56)
              : const Color(0xFFF98128),
        ),
        _ResultInfoChip(
          icon: Icons.camera_alt_outlined,
          label: '$qualityLevel scan',
          tone: quality?.needsRetake == true
              ? const Color(0xFFF98128)
              : const Color(0xFF0E5C56),
        ),
        if (brightness != null)
          _ResultInfoChip(
            icon: Icons.light_mode_outlined,
            label: brightness,
            tone: const Color(0xFF7A8F72),
          ),
        if (coverage != null)
          _ResultInfoChip(
            icon: Icons.face_6_outlined,
            label: coverage,
            tone: const Color(0xFF7A8F72),
          ),
      ],
    );
  }
}

class _ResultInfoChip extends StatelessWidget {
  const _ResultInfoChip({
    required this.icon,
    required this.label,
    required this.tone,
  });

  final IconData icon;
  final String label;
  final Color tone;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: tone.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: tone.withValues(alpha: 0.22)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: tone),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: tone,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _BeautyRoutineCard extends StatelessWidget {
  const _BeautyRoutineCard({required this.routine, required this.text});

  final TreatmentPackage routine;
  final SkinoText text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3EC),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFFFD0B3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const CircleAvatar(
                radius: 18,
                backgroundColor: Color(0xFFF98128),
                child: SkinoImageIcon(
                  asset: SkinoAssets.iconProgress,
                  size: 30,
                  padding: 2,
                  backgroundColor: Colors.white,
                  borderRadius: 12,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      routine.name,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF282420),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      routine.reason,
                      style: const TextStyle(
                        color: Color(0xFF68625B),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              _FollowUpBadge(days: routine.followUpDays),
            ],
          ),
          const SizedBox(height: 14),
          for (final entry in routine.steps.asMap().entries)
            _PlanStep(
              index: entry.key + 1,
              label: text.routineStep(entry.value),
            ),
        ],
      ),
    );
  }
}

class _PlanStep extends StatelessWidget {
  const _PlanStep({required this.index, required this.label});

  final int index;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: Color(0xFF0E5C56),
              shape: BoxShape.circle,
            ),
            child: Text(
              '$index',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _titleCase(label),
              style: const TextStyle(
                color: Color(0xFF282420),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FollowUpBadge extends StatelessWidget {
  const _FollowUpBadge({required this.days});

  final int days;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        '${days}d\ncheck',
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: Color(0xFF0E5C56),
          fontSize: 11,
          height: 1.05,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _ConcernChip extends StatelessWidget {
  const _ConcernChip({required this.label, this.detail});

  final String label;
  final String? detail;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF6F1),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        detail == null ? label : '$label  $detail',
        style: const TextStyle(
          color: Color(0xFF123C36),
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _EmptyBeautyRoutine extends StatelessWidget {
  const _EmptyBeautyRoutine({required this.text});

  final SkinoText text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F4EF),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline_rounded, color: Color(0xFF68625B)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text.emptyBeautyRoutine,
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionKicker extends StatelessWidget {
  const _SectionKicker(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label.toUpperCase(),
      style: const TextStyle(
        color: Color(0xFFF98128),
        fontSize: 11,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

String _titleCase(String value) {
  return value
      .replaceAll('_', ' ')
      .split(' ')
      .where((part) => part.isNotEmpty)
      .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
      .join(' ');
}

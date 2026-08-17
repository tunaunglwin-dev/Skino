import 'package:flutter/material.dart';

class SkinoImageIcon extends StatelessWidget {
  const SkinoImageIcon({
    required this.asset,
    this.size = 34,
    this.padding = 5,
    this.backgroundColor = const Color(0xFFFFF3EC),
    this.borderColor,
    this.borderRadius = 14,
    this.fit = BoxFit.contain,
    this.alignment = Alignment.center,
    super.key,
  });

  const SkinoImageIcon.nav({
    required this.asset,
    this.size = 30,
    this.padding = 2,
    this.backgroundColor = Colors.transparent,
    this.borderColor,
    this.borderRadius = 12,
    this.fit = BoxFit.contain,
    this.alignment = Alignment.center,
    super.key,
  });

  const SkinoImageIcon.page({
    required this.asset,
    this.size = 44,
    this.padding = 3,
    this.backgroundColor = const Color(0xFFFFF3EC),
    this.borderColor,
    this.borderRadius = 16,
    this.fit = BoxFit.contain,
    this.alignment = Alignment.center,
    super.key,
  });

  const SkinoImageIcon.inline({
    required this.asset,
    this.size = 22,
    this.padding = 1,
    this.backgroundColor = Colors.transparent,
    this.borderColor,
    this.borderRadius = 8,
    this.fit = BoxFit.contain,
    this.alignment = Alignment.center,
    super.key,
  });

  final String asset;
  final double size;
  final double padding;
  final Color backgroundColor;
  final Color? borderColor;
  final double borderRadius;
  final BoxFit fit;
  final AlignmentGeometry alignment;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(borderRadius),
        border: borderColor == null ? null : Border.all(color: borderColor!),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(
          (borderRadius - padding).clamp(0, borderRadius).toDouble(),
        ),
        child: Image.asset(asset, fit: fit, alignment: alignment),
      ),
    );
  }
}

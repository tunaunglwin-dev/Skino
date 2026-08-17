import 'package:flutter/material.dart';

import '../../../../core/skino_assets.dart';

class LensHeader extends StatelessWidget {
  const LensHeader({required this.userName, required this.onLogout, super.key});

  final String? userName;
  final VoidCallback? onLogout;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Image.asset(
            SkinoAssets.logo,
            width: 58,
            height: 58,
            fit: BoxFit.cover,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                userName == null ? 'SKINO' : 'Hello, $userName',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF282420),
                ),
              ),
              const SizedBox(height: 3),
              Text(
                'AI skin coach in your pocket',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: const Color(0xFF68625B),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        if (onLogout != null)
          IconButton.filledTonal(
            onPressed: onLogout,
            icon: const Icon(Icons.logout_rounded),
          ),
      ],
    );
  }
}

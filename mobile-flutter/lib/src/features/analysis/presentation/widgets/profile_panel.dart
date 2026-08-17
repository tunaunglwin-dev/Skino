import 'package:flutter/material.dart';

import '../../../auth/models/auth_user.dart';

class ProfilePanel extends StatelessWidget {
  const ProfilePanel({required this.user, super.key});

  final AuthUser user;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.8)),
      ),
      child: Row(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFF98128), Color(0xFF0E5C56)],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Center(child: _Avatar(user: user)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF123C36),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  user.email,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF60726E),
                    fontWeight: FontWeight.w500,
                    fontSize: 13,
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

class _Avatar extends StatelessWidget {
  const _Avatar({required this.user});

  final AuthUser user;

  @override
  Widget build(BuildContext context) {
    final avatarUrl = user.avatarUrl;

    if (avatarUrl != null && avatarUrl.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Image.network(
          avatarUrl,
          width: 54,
          height: 54,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return _Initial(name: user.name);
          },
        ),
      );
    }

    return _Initial(name: user.name);
  }
}

class _Initial extends StatelessWidget {
  const _Initial({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    return Text(
      name.trim().isEmpty ? 'U' : name.trim().substring(0, 1).toUpperCase(),
      style: const TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.w500,
        fontSize: 22,
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../../../../core/skino_assets.dart';

class AuthCard extends StatefulWidget {
  const AuthCard({
    required this.baseUrlController,
    required this.isLoading,
    required this.error,
    required this.onLogin,
    required this.onGoogleLogin,
    super.key,
  });

  final TextEditingController baseUrlController;
  final bool isLoading;
  final String? error;
  final Future<void> Function(String email, String password) onLogin;
  final Future<void> Function() onGoogleLogin;

  @override
  State<AuthCard> createState() => _AuthCardState();
}

class _AuthCardState extends State<AuthCard> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 650),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 18 * (1 - value)),
            child: child,
          ),
        );
      },
      child: _Panel(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const _BrandLockup(),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: widget.isLoading ? null : widget.onGoogleLogin,
              icon: const Icon(Icons.g_mobiledata_rounded, size: 30),
              label: Text(
                widget.isLoading ? 'Connecting...' : 'Continue with Google',
              ),
            ),
            const SizedBox(height: 12),
            const _ConnectionHint(),
            if (widget.error != null) ...[
              const SizedBox(height: 12),
              _Message(text: widget.error!),
            ],
            const SizedBox(height: 10),
            ExpansionTile(
              tilePadding: EdgeInsets.zero,
              childrenPadding: EdgeInsets.zero,
              shape: const Border(),
              collapsedShape: const Border(),
              leading: const Icon(Icons.tune_rounded, color: Color(0xFF0E5C56)),
              title: const Text(
                'Email login',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              children: [
                const SizedBox(height: 4),
                TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    prefixIcon: Icon(Icons.mail_outline_rounded),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Password',
                    prefixIcon: Icon(Icons.lock_outline_rounded),
                  ),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: widget.isLoading ? null : _submit,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF0E5C56),
                    side: const BorderSide(color: Color(0xFF0E5C56)),
                  ),
                  icon: const Icon(Icons.login_rounded),
                  label: Text(
                    widget.isLoading ? 'Connecting...' : 'Login with email',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() {
    return widget.onLogin(
      _emailController.text.trim(),
      _passwordController.text,
    );
  }
}

class _BrandLockup extends StatelessWidget {
  const _BrandLockup();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Image.asset(
            SkinoAssets.logo,
            width: 66,
            height: 66,
            fit: BoxFit.cover,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Continue to Skino',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: const Color(0xFF282420),
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Your scans, profile, and progress stay connected.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Color(0xFF68625B),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _ConnectionHint extends StatelessWidget {
  const _ConnectionHint();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7F1),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFFFD8BF)),
      ),
      child: const Row(
        children: [
          Icon(Icons.info_outline_rounded, color: Color(0xFFF98128)),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Set API URL in Settings. You can still scan as guest without login.',
              style: TextStyle(
                color: Color(0xFF625B53),
                fontWeight: FontWeight.w600,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Panel extends StatelessWidget {
  const _Panel({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.88),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.white.withValues(alpha: 0.8)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1F123C36),
            blurRadius: 32,
            offset: Offset(0, 18),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final displayText = _friendlyText(text);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFECEC),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        displayText,
        style: const TextStyle(
          color: Color(0xFF9E2732),
          fontWeight: FontWeight.w500,
          height: 1.35,
        ),
      ),
    );
  }

  String _friendlyText(String value) {
    if (value.contains('Laravel API did not respond') ||
        value.contains('Could not reach Laravel API')) {
      return 'API server is not reachable yet. Start Laravel and Python AI on the laptop, keep the phone on the same Wi-Fi, then check the API URL in Settings.';
    }

    return value;
  }
}

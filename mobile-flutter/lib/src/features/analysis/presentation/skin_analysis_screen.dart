import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../../core/api_config.dart';
import '../../../core/api_exception.dart';
import '../../../core/google_auth_config.dart';
import '../../../core/skino_assets.dart';
import '../../auth/data/auth_api.dart';
import '../../auth/data/session_store.dart';
import '../../auth/models/auth_session.dart';
import '../../privacy/data/privacy_consent_api.dart';
import '../data/appointment_request_api.dart';
import '../data/routine_api.dart';
import '../data/routine_reminder_service.dart';
import '../data/skin_analysis_api.dart';
import '../models/active_routine.dart';
import '../models/appointment_request.dart';
import '../models/skin_analysis_result.dart';
import 'skino_app_shell.dart';

class SkinAnalysisScreen extends StatefulWidget {
  const SkinAnalysisScreen({super.key});

  @override
  State<SkinAnalysisScreen> createState() => _SkinAnalysisScreenState();
}

class _SkinAnalysisScreenState extends State<SkinAnalysisScreen> {
  final AuthApi _authApi = const AuthApi();
  final SessionStore _sessionStore = const SessionStore();
  final SkinAnalysisApi _analysisApi = const SkinAnalysisApi();
  final AppointmentRequestApi _appointmentRequestApi =
      const AppointmentRequestApi();
  final RoutineApi _routineApi = const RoutineApi();
  final RoutineReminderService _routineReminderService =
      const RoutineReminderService();
  final PrivacyConsentApi _privacyConsentApi = const PrivacyConsentApi();
  final TextEditingController _baseUrlController = TextEditingController(
    text: ApiConfig.defaultBaseUrl,
  );
  Future<void>? _googleSignInInit;
  bool _googleSignInInitialized = false;

  AuthSession? _session;
  File? _image;
  SkinAnalysisResult? _result;
  ActiveRoutine? _activeRoutine;
  final List<SkinAnalysisResult> _scanHistory = [];
  bool _isLoading = false;
  bool _allowModelTraining = false;
  bool _privacySettingsLoaded = false;
  bool _isBooting = true;
  bool _showOnboarding = false;
  bool _showWelcomeBack = false;
  String? _error;
  String? _appointmentRequestMessage;

  @override
  void initState() {
    super.initState();
    _restoreAppState();
  }

  @override
  void dispose() {
    _baseUrlController.dispose();
    super.dispose();
  }

  Future<void> _login(String email, String password) async {
    await _runRequest(() async {
      _session = await _authApi.login(
        baseUrl: _baseUrlController.text.trim(),
        email: email,
        password: password,
      );
      await _sessionStore.saveBaseUrl(_baseUrlController.text.trim());
      await _sessionStore.saveSession(_session!);
      await _refreshPrivacyConsent();
      await _refreshScanHistory();
      await _refreshActiveRoutine();
    });
  }

  Future<void> _loginWithGoogle() async {
    await _runRequest(() async {
      await _authApi.checkHealth(baseUrl: _baseUrlController.text.trim());
      await _ensureGoogleSignInInitialized();

      if (!GoogleSignIn.instance.supportsAuthenticate()) {
        throw const ApiException('Google Sign-In is not available here.');
      }

      final GoogleSignInAccount googleUser;

      try {
        googleUser = await GoogleSignIn.instance.authenticate();
      } catch (error) {
        throw ApiException(
          'Google Sign-In could not start. Check the Android OAuth client package/SHA-1 in Google Cloud, then try again. Details: $error',
        );
      }
      final idToken = googleUser.authentication.idToken;

      if (idToken == null) {
        throw const ApiException(
          'Google did not return a sign-in token. The web client ID or Android OAuth setup is not matching this app.',
        );
      }

      _session = await _authApi.loginWithGoogle(
        baseUrl: _baseUrlController.text.trim(),
        idToken: idToken,
      );
      await _sessionStore.saveBaseUrl(_baseUrlController.text.trim());
      await _sessionStore.saveSession(_session!);
      await _refreshPrivacyConsent();
      await _refreshScanHistory();
      await _refreshActiveRoutine();
    });
  }

  Future<void> _restoreAppState() async {
    final baseUrl = await _sessionStore.readBaseUrl();
    final completedOnboarding = await _sessionStore.hasCompletedOnboarding();
    final session = await _sessionStore.readSession();

    if (!mounted) {
      return;
    }

    setState(() {
      _baseUrlController.text = baseUrl;
      _session = session;
      _showOnboarding = !completedOnboarding;
      _isBooting = false;
    });

    if (session != null) {
      setState(() => _showWelcomeBack = true);
      Future<void>.delayed(const Duration(seconds: 3), () {
        if (mounted) {
          setState(() => _showWelcomeBack = false);
        }
      });
      await _runRequest(() async {
        await _refreshPrivacyConsent();
        await _refreshScanHistory();
        await _refreshActiveRoutine();
      });
    }
  }

  Future<void> _finishOnboarding() async {
    await _sessionStore.completeOnboarding();
    if (!mounted) {
      return;
    }
    setState(() => _showOnboarding = false);
  }

  Future<void> _refreshPrivacyConsent() async {
    final session = _session;

    if (session == null) {
      return;
    }

    final consent = await _privacyConsentApi.fetchModelTrainingConsent(
      baseUrl: _baseUrlController.text.trim(),
      token: session.token,
    );
    _allowModelTraining = consent.granted;
    _privacySettingsLoaded = true;
  }

  Future<void> _updateModelTrainingConsent(bool granted) async {
    final session = _session;

    if (session == null) {
      return;
    }

    await _runRequest(() async {
      final consent = await _privacyConsentApi.updateModelTrainingConsent(
        baseUrl: _baseUrlController.text.trim(),
        token: session.token,
        granted: granted,
      );
      _allowModelTraining = consent.granted;
      _privacySettingsLoaded = true;
    });
  }

  Future<void> _saveApiBaseUrl() async {
    await _sessionStore.saveBaseUrl(_baseUrlController.text.trim());
    _baseUrlController.text = ApiConfig.normalizeBaseUrl(
      _baseUrlController.text,
    );
  }

  Future<void> _ensureGoogleSignInInitialized() {
    return _googleSignInInit ??= GoogleSignIn.instance
        .initialize(serverClientId: GoogleAuthConfig.webClientId)
        .then((_) => _googleSignInInitialized = true);
  }

  void _useScanFrame(File image) {
    setState(() {
      _image = image;
      _result = null;
      _error = null;
      _appointmentRequestMessage = null;
    });
  }

  Future<void> _analyze() async {
    final image = _image;

    if (image == null) {
      return;
    }

    await _runRequest(() async {
      await _sessionStore.saveBaseUrl(_baseUrlController.text.trim());
      final result = await _analysisApi.analyze(
        baseUrl: _baseUrlController.text.trim(),
        token: _session?.token,
        image: image,
        allowModelTraining: _allowModelTraining,
      );
      _result = result;
      _rememberScanResult(result);
      if (_session != null) {
        await _refreshScanHistory();
      }
      _appointmentRequestMessage = null;
    });
  }

  void _rememberScanResult(SkinAnalysisResult result) {
    _scanHistory
      ..removeWhere((item) => identical(item, result))
      ..insert(0, result);

    if (_scanHistory.length > 12) {
      _scanHistory.removeRange(12, _scanHistory.length);
    }
  }

  Future<void> _refreshScanHistory() async {
    final session = _session;

    if (session == null) {
      return;
    }

    final history = await _analysisApi.fetchHistory(
      baseUrl: _baseUrlController.text.trim(),
      token: session.token,
    );

    _scanHistory
      ..clear()
      ..addAll(history);

    _result ??= _scanHistory.isEmpty ? null : _scanHistory.first;
  }

  Future<void> _refreshActiveRoutine() async {
    final session = _session;

    if (session == null) {
      return;
    }

    _activeRoutine = await _routineApi.fetchActive(
      baseUrl: _baseUrlController.text.trim(),
      token: session.token,
    );
  }

  Future<void> _startRoutinePlan(SkinAnalysisResult result) async {
    final session = _session;
    final analysisId = result.id;

    if (session == null ||
        result.treatmentPackage == null ||
        analysisId == null) {
      return;
    }

    await _runRequest(() async {
      _activeRoutine = await _routineApi.start(
        baseUrl: _baseUrlController.text.trim(),
        token: session.token,
        skinAnalysisId: analysisId,
      );
      await _routineReminderService.scheduleFollowUpScan(
        startedAt: _activeRoutine?.startedAt,
        followUpDays: _activeRoutine?.routine.followUpDays ?? 14,
      );
    });
  }

  Future<void> _updateRoutineToday({
    String? checkDate,
    bool? morningDone,
    bool? nightDone,
  }) async {
    final session = _session;

    if (session == null || _activeRoutine == null) {
      return;
    }

    await _runRequest(() async {
      _activeRoutine = await _routineApi.updateToday(
        baseUrl: _baseUrlController.text.trim(),
        token: session.token,
        checkDate: checkDate,
        morningDone: morningDone,
        nightDone: nightDone,
      );
    });
  }

  Future<void> _stopRoutinePlan() async {
    final session = _session;

    if (session == null || _activeRoutine == null) {
      return;
    }

    await _runRequest(() async {
      await _routineApi.stop(
        baseUrl: _baseUrlController.text.trim(),
        token: session.token,
      );
      _activeRoutine = null;
    });
  }

  Future<void> _requestAppointment(AppointmentRequestDraft draft) async {
    await _runRequest(() async {
      await _appointmentRequestApi.create(
        baseUrl: _baseUrlController.text.trim(),
        token: _session?.token,
        draft: draft,
      );
      _appointmentRequestMessage =
          'Appointment request sent. The Skino team can now follow up from CRM.';
    });
  }

  Future<void> _deleteScanHistoryItem(SkinAnalysisResult result) async {
    final session = _session;
    final analysisId = result.id;

    if (session == null || analysisId == null) {
      setState(() {
        _scanHistory.remove(result);
        if (identical(_result, result)) {
          _result = _scanHistory.isEmpty ? null : _scanHistory.first;
        }
      });
      return;
    }

    await _runRequest(() async {
      await _analysisApi.deleteAnalysis(
        baseUrl: _baseUrlController.text.trim(),
        token: session.token,
        analysisId: analysisId,
      );

      _scanHistory.removeWhere((item) => item.id == analysisId);
      if (_result?.id == analysisId) {
        _result = _scanHistory.isEmpty ? null : _scanHistory.first;
      }
      if (_activeRoutine?.skinAnalysisId == analysisId) {
        await _refreshActiveRoutine();
      }
    });
  }

  void _clearScanResult() {
    setState(() {
      _image = null;
      _result = null;
      _appointmentRequestMessage = null;
      _error = null;
    });
  }

  Future<void> _runRequest(Future<void> Function() request) async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      await request();
    } on ApiException catch (error) {
      _error = error.message;
    } catch (error) {
      _error = 'Unexpected mobile app error: $error';
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _logout() {
    if (_googleSignInInitialized) {
      GoogleSignIn.instance.signOut();
    }

    _sessionStore.clearSession();

    setState(() {
      _session = null;
      _image = null;
      _result = null;
      _activeRoutine = null;
      _scanHistory.clear();
      _allowModelTraining = false;
      _privacySettingsLoaded = false;
      _error = null;
      _appointmentRequestMessage = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isBooting) {
      return const _SkinoBootView();
    }

    if (_showOnboarding) {
      return _SkinoOnboarding(onFinish: _finishOnboarding);
    }

    return Stack(
      children: [
        SkinoAppShell(
          session: _session,
          apiBaseUrl: _baseUrlController.text.trim(),
          baseUrlController: _baseUrlController,
          image: _image,
          result: _result,
          activeRoutine: _activeRoutine,
          scanHistory: List.unmodifiable(_scanHistory),
          isLoading: _isLoading,
          error: _error,
          appointmentRequestMessage: _appointmentRequestMessage,
          onCapture: _useScanFrame,
          onAnalyze: _image == null ? null : _analyze,
          onClearScanResult: _clearScanResult,
          onRequestAppointment: _requestAppointment,
          onStartRoutine: _startRoutinePlan,
          onStopRoutine: _stopRoutinePlan,
          onUpdateRoutineToday: _updateRoutineToday,
          onDeleteScanHistoryItem: _deleteScanHistoryItem,
          allowModelTraining: _allowModelTraining,
          onAllowModelTrainingChanged: (value) {
            setState(() => _allowModelTraining = value);
          },
          privacySettingsLoaded: _privacySettingsLoaded,
          onModelTrainingConsentChanged: _updateModelTrainingConsent,
          onSaveApiBaseUrl: _saveApiBaseUrl,
          onLogin: _login,
          onGoogleLogin: _loginWithGoogle,
          onLogout: _logout,
        ),
        if (_showWelcomeBack && _session != null)
          _WelcomeBackBanner(userName: _session!.user.name),
        if (_isLoading) const _SkinoLoadingOverlay(),
      ],
    );
  }
}

class _WelcomeBackBanner extends StatelessWidget {
  const _WelcomeBackBanner({required this.userName});

  final String userName;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Align(
        alignment: Alignment.topCenter,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 10, 18, 0),
          child: Material(
            color: Colors.transparent,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.98),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFFFFE3D1)),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x1FF98128),
                    blurRadius: 18,
                    offset: Offset(0, 10),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.verified_user_outlined,
                    color: Color(0xFFF98128),
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      'Welcome back, $userName',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF282420),
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SkinoBootView extends StatefulWidget {
  const _SkinoBootView();

  @override
  State<_SkinoBootView> createState() => _SkinoBootViewState();
}

class _SkinoBootViewState extends State<_SkinoBootView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFBF9F4),
      body: Center(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Transform.scale(
              scale: 0.98 + (_controller.value * 0.03),
              child: child,
            );
          },
          child: const _LoadingCompanion(
            title: 'Skino',
            subtitle: 'Preparing your beauty and wellbeing workspace',
          ),
        ),
      ),
    );
  }
}

class _SkinoLoadingOverlay extends StatelessWidget {
  const _SkinoLoadingOverlay();

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: AbsorbPointer(
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.22),
          ),
          child: const Center(
            child: _LoadingCompanion(
              title: 'Working on it',
              subtitle: 'Connecting to Skino API and AI analysis',
            ),
          ),
        ),
      ),
    );
  }
}

class _LoadingCompanion extends StatelessWidget {
  const _LoadingCompanion({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        width: 292,
        padding: const EdgeInsets.fromLTRB(22, 24, 22, 24),
        decoration: BoxDecoration(
          color: const Color(0xFFFFFDF9),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFFFFE3D1)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x1FF98128),
              blurRadius: 28,
              offset: Offset(0, 18),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 68,
              height: 68,
              decoration: BoxDecoration(
                color: const Color(0xFFFFE3D1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.asset(SkinoAssets.logo, fit: BoxFit.cover),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Health + Beauty',
              style: TextStyle(
                color: Color(0xFFF98128),
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 14),
            const SizedBox(
              width: 34,
              height: 34,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                color: Color(0xFFF98128),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF282420),
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              softWrap: true,
              style: const TextStyle(
                color: Color(0xFF68625B),
                fontSize: 13,
                fontWeight: FontWeight.w600,
                height: 1.35,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SkinoOnboarding extends StatefulWidget {
  const _SkinoOnboarding({required this.onFinish});

  final Future<void> Function() onFinish;

  @override
  State<_SkinoOnboarding> createState() => _SkinoOnboardingState();
}

class _SkinoOnboardingState extends State<_SkinoOnboarding> {
  final PageController _controller = PageController();
  int _page = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _next() {
    if (_page == 2) {
      widget.onFinish();
      return;
    }

    _controller.nextPage(
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final pages = const [
      _OnboardingStep(
        icon: Icons.center_focus_strong_rounded,
        title: 'Scan first',
        body: 'Take a clear face scan and get a focused skin summary.',
      ),
      _OnboardingStep(
        icon: Icons.spa_outlined,
        title: 'Read your routine',
        body: 'Review skin score, concerns, and a simple care plan.',
      ),
      _OnboardingStep(
        icon: Icons.local_hospital_outlined,
        title: 'Ask a specialist',
        body: 'Choose a specialist profile and send the scan to admin CRM.',
      ),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFFBF9F4),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 28),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFE3D1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.water_drop_outlined,
                      color: Color(0xFFF98128),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Skino',
                    style: TextStyle(
                      color: Color(0xFF282420),
                      fontSize: 28,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: widget.onFinish,
                    child: const Text('Skip'),
                  ),
                ],
              ),
              Expanded(
                child: PageView(
                  controller: _controller,
                  onPageChanged: (value) => setState(() => _page = value),
                  children: pages,
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (var index = 0; index < pages.length; index++)
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      width: _page == index ? 26 : 8,
                      height: 8,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        color: _page == index
                            ? const Color(0xFFF98128)
                            : const Color(0xFFFFD0B3),
                        borderRadius: BorderRadius.circular(99),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 22),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _next,
                  child: Text(_page == 2 ? 'Start Skino' : 'Next'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OnboardingStep extends StatelessWidget {
  const _OnboardingStep({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 148,
          height: 148,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(32),
            boxShadow: const [
              BoxShadow(
                color: Color(0x14123C36),
                blurRadius: 24,
                offset: Offset(0, 14),
              ),
            ],
          ),
          child: Icon(icon, color: const Color(0xFFF98128), size: 68),
        ),
        const SizedBox(height: 34),
        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Color(0xFF282420),
            fontSize: 30,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          body,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Color(0xFF625B53),
            fontSize: 17,
            height: 1.45,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

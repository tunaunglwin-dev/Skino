import 'dart:math' as math;
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/api_exception.dart';
import '../../../core/api_config.dart';
import '../../../core/app_language.dart';
import '../../../core/skino_assets.dart';
import '../../../core/skino_image_icon.dart';
import '../../../core/skino_text.dart';
import '../../auth/models/auth_session.dart';
import '../data/buddy_chat_api.dart';
import '../models/active_routine.dart';
import '../models/appointment_request.dart';
import '../models/skin_analysis_result.dart';
import '../models/skin_concern.dart';
import '../models/skin_zone.dart';
import '../data/routine_reminder_service.dart';
import 'widgets/analysis_result_panel.dart';
import 'widgets/auth_card.dart';
import 'widgets/image_capture_panel.dart';
import 'widgets/profile_panel.dart';

class SkinoAppShell extends StatefulWidget {
  const SkinoAppShell({
    required this.session,
    required this.apiBaseUrl,
    required this.baseUrlController,
    required this.image,
    required this.result,
    required this.activeRoutine,
    required this.scanHistory,
    required this.isLoading,
    required this.error,
    required this.appointmentRequestMessage,
    required this.onCapture,
    required this.onAnalyze,
    required this.onClearScanResult,
    required this.onRequestAppointment,
    required this.onStartRoutine,
    required this.onStopRoutine,
    required this.onUpdateRoutineToday,
    required this.onDeleteScanHistoryItem,
    required this.allowModelTraining,
    required this.onAllowModelTrainingChanged,
    required this.privacySettingsLoaded,
    required this.onModelTrainingConsentChanged,
    required this.onSaveApiBaseUrl,
    required this.onLogin,
    required this.onGoogleLogin,
    required this.onLogout,
    super.key,
  });

  final AuthSession? session;
  final String apiBaseUrl;
  final TextEditingController baseUrlController;
  final File? image;
  final SkinAnalysisResult? result;
  final ActiveRoutine? activeRoutine;
  final List<SkinAnalysisResult> scanHistory;
  final bool isLoading;
  final String? error;
  final String? appointmentRequestMessage;
  final ValueChanged<File> onCapture;
  final VoidCallback? onAnalyze;
  final VoidCallback onClearScanResult;
  final Future<void> Function(AppointmentRequestDraft draft)
  onRequestAppointment;
  final Future<void> Function(SkinAnalysisResult result) onStartRoutine;
  final Future<void> Function() onStopRoutine;
  final Future<void> Function({
    String? checkDate,
    bool? morningDone,
    bool? nightDone,
  })
  onUpdateRoutineToday;
  final Future<void> Function(SkinAnalysisResult result)
  onDeleteScanHistoryItem;
  final bool allowModelTraining;
  final ValueChanged<bool> onAllowModelTrainingChanged;
  final bool privacySettingsLoaded;
  final Future<void> Function(bool granted) onModelTrainingConsentChanged;
  final Future<void> Function() onSaveApiBaseUrl;
  final Future<void> Function(String email, String password) onLogin;
  final Future<void> Function() onGoogleLogin;
  final VoidCallback onLogout;

  @override
  State<SkinoAppShell> createState() => _SkinoAppShellState();
}

class _SkinoAppShellState extends State<SkinoAppShell> {
  final PageController _pageController = PageController();
  AppLanguage _language = AppLanguage.myanmar;
  int _selectedIndex = 0;
  bool _scanToolOpen = false;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _selectPage(int index) {
    setState(() {
      _selectedIndex = index;
      if (index != 1) {
        _scanToolOpen = false;
      }
      if (index == 1 && widget.image == null && widget.result == null) {
        _scanToolOpen = false;
      }
    });
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
    );
  }

  void _openScanPageFromPushedPage(BuildContext context) {
    Navigator.of(context).pop();
    _selectPage(1);
  }

  void _openHomeFromPushedPage(BuildContext context) {
    Navigator.of(context).pop();
    _selectPage(0);
  }

  void _openSettingsFromPushedPage(BuildContext context) {
    Navigator.of(context).pop();
    _selectPage(3);
  }

  void _openPlansPage(BuildContext context, SkinoText text) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => _PlansPage(text: text)));
  }

  SkinAnalysisResult? get _currentUsableScan =>
      widget.result ??
      (widget.scanHistory.isEmpty ? null : widget.scanHistory.first);

  SkinAnalysisResult? get _latestSavedOrCurrentScan =>
      widget.scanHistory.isEmpty ? widget.result : widget.scanHistory.first;

  void _openSpecialistDirectory(BuildContext context, SkinoText text) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _SpecialistDirectoryPage(
          text: text,
          result: _currentUsableScan,
          activeRoutine: widget.activeRoutine,
          isGuest: widget.session == null,
          session: widget.session,
          isLoading: widget.isLoading,
          message: widget.appointmentRequestMessage,
          onSubmit: widget.onRequestAppointment,
          onOpenHome: () => _openHomeFromPushedPage(context),
          onOpenScan: () => _openScanPageFromPushedPage(context),
          onOpenSettings: () => _openSettingsFromPushedPage(context),
          onOpenCare: () => _openCarePage(context, text),
          onOpenScanHistory: () => _openScanHistory(context, text),
          onOpenHelpSafety: () => _openHelpSafetyPage(context, text),
          onLogout: widget.onLogout,
        ),
      ),
    );
  }

  void _openCarePage(BuildContext context, SkinoText text) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _CarePage(
          text: text,
          result: _currentUsableScan,
          activeRoutine: widget.activeRoutine,
          latestScan: _latestSavedOrCurrentScan,
          session: widget.session,
          isGuest: widget.session == null,
          onStartRoutine: widget.onStartRoutine,
          onStopRoutine: widget.onStopRoutine,
          onUpdateRoutineToday: widget.onUpdateRoutineToday,
          onOpenHome: () => _openHomeFromPushedPage(context),
          onStartScan: () => _openScanPageFromPushedPage(context),
          onOpenSettings: () => _openSettingsFromPushedPage(context),
          onOpenSpecialist: () => _openSpecialistDirectory(context, text),
          onOpenScanHistory: () => _openScanHistory(context, text),
          onOpenHelpSafety: () => _openHelpSafetyPage(context, text),
          onLogout: widget.onLogout,
        ),
      ),
    );
  }

  void _openHelpSafetyPage(BuildContext context, SkinoText text) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _HelpSafetyPage(
          text: text,
          session: widget.session,
          onOpenHome: () => _openHomeFromPushedPage(context),
          onOpenScan: () => _openScanPageFromPushedPage(context),
          onOpenSettings: () => _openSettingsFromPushedPage(context),
          onOpenSpecialist: () => _openSpecialistDirectory(context, text),
          onOpenCare: () => _openCarePage(context, text),
          onOpenScanHistory: () => _openScanHistory(context, text),
          onLogout: widget.onLogout,
        ),
      ),
    );
  }

  void _openScanHistory(BuildContext context, SkinoText text) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _ScanHistoryPage(
          text: text,
          scanHistory: widget.scanHistory,
          latestResult: _currentUsableScan,
          activeRoutine: widget.activeRoutine,
          isSavedHistory: widget.session != null,
          isGuest: widget.session == null,
          session: widget.session,
          isLoading: widget.isLoading,
          appointmentRequestMessage: widget.appointmentRequestMessage,
          onRequestAppointment: widget.onRequestAppointment,
          onStartRoutine: widget.onStartRoutine,
          onOpenHome: () => _openHomeFromPushedPage(context),
          onOpenScan: () => _openScanPageFromPushedPage(context),
          onOpenSettings: () => _openSettingsFromPushedPage(context),
          onOpenSpecialist: () => _openSpecialistDirectory(context, text),
          onOpenCare: () => _openCarePage(context, text),
          onOpenHelpSafety: () => _openHelpSafetyPage(context, text),
          onStartScan: () => _openScanPageFromPushedPage(context),
          onNewScan: widget.onClearScanResult,
          onDeleteScan: widget.onDeleteScanHistoryItem,
          onLogout: widget.onLogout,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final text = SkinoText(_language);
    final pages = [
      _HomePage(
        text: text,
        session: widget.session,
        result: _currentUsableScan,
        onStartScan: () => _selectPage(1),
        onOpenCare: () => _openCarePage(context, text),
        onOpenScanHistory: () => _openScanHistory(context, text),
        onOpenSpecialist: () => _openSpecialistDirectory(context, text),
        onOpenHelpSafety: () => _openHelpSafetyPage(context, text),
        onOpenPlans: () => _openPlansPage(context, text),
        onOpenLatestResult: _currentUsableScan == null
            ? null
            : () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => _ResultPage(
                    text: text,
                    result: _currentUsableScan!,
                    isGuest: widget.session == null,
                    session: widget.session,
                    isLoading: widget.isLoading,
                    appointmentRequestMessage: widget.appointmentRequestMessage,
                    onRequestAppointment: widget.onRequestAppointment,
                    onStartRoutine: widget.onStartRoutine,
                    onOpenCare: () => _openCarePage(context, text),
                    activeRoutine: widget.activeRoutine,
                    routineIsActive:
                        widget.activeRoutine?.skinAnalysisId ==
                        _currentUsableScan!.id,
                    onNewScan: () {
                      widget.onClearScanResult();
                      _selectPage(1);
                    },
                  ),
                ),
              ),
        activeRoutine: widget.activeRoutine,
      ),
      _ScanPage(
        text: text,
        image: widget.image,
        result: widget.result,
        latestScan: _latestSavedOrCurrentScan,
        isLoading: widget.isLoading,
        error: widget.error,
        appointmentRequestMessage: widget.appointmentRequestMessage,
        showLiveScan: _scanToolOpen || widget.image != null,
        onOpenLiveScan: () => setState(() => _scanToolOpen = true),
        onCapture: (image) {
          setState(() => _scanToolOpen = true);
          widget.onCapture(image);
        },
        onAnalyze: widget.onAnalyze,
        onClearScanResult: () {
          setState(() => _scanToolOpen = true);
          widget.onClearScanResult();
        },
        onRequestAppointment: widget.onRequestAppointment,
        onStartRoutine: widget.onStartRoutine,
        onOpenCare: () => _openCarePage(context, text),
        activeRoutine: widget.activeRoutine,
        routineIsActive:
            widget.activeRoutine?.skinAnalysisId != null &&
            widget.activeRoutine?.skinAnalysisId == widget.result?.id,
        isGuest: widget.session == null,
        session: widget.session,
        allowModelTraining: widget.allowModelTraining,
        onAllowModelTrainingChanged: widget.onAllowModelTrainingChanged,
        onOpenScanHistory: () => _openScanHistory(context, text),
      ),
      _BuddyPage(
        text: text,
        apiBaseUrl: widget.apiBaseUrl,
        session: widget.session,
        result: _currentUsableScan,
        activeRoutine: widget.activeRoutine,
        onStartScan: () => _selectPage(1),
        onOpenCare: () => _openCarePage(context, text),
      ),
      _SettingsPage(
        text: text,
        language: _language,
        onLanguageChanged: (language) => setState(() => _language = language),
        session: widget.session,
        baseUrlController: widget.baseUrlController,
        isLoading: widget.isLoading,
        error: widget.error,
        allowModelTraining: widget.allowModelTraining,
        privacySettingsLoaded: widget.privacySettingsLoaded,
        onModelTrainingConsentChanged: widget.onModelTrainingConsentChanged,
        onSaveApiBaseUrl: widget.onSaveApiBaseUrl,
        onLogin: widget.onLogin,
        onGoogleLogin: widget.onGoogleLogin,
        onLogout: widget.onLogout,
      ),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFFBF9F4),
      drawer: _SkinoDrawer(
        text: text,
        session: widget.session,
        result: _currentUsableScan,
        activeRoutine: widget.activeRoutine,
        isLoading: widget.isLoading,
        appointmentRequestMessage: widget.appointmentRequestMessage,
        onRequestAppointment: widget.onRequestAppointment,
        onOpenHome: () {
          Navigator.of(context).pop();
          _selectPage(0);
        },
        onOpenScan: () {
          Navigator.of(context).pop();
          _selectPage(1);
        },
        onOpenSettings: () {
          Navigator.of(context).pop();
          _selectPage(3);
        },
        onOpenCare: () {
          Navigator.of(context).pop();
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              _openCarePage(context, text);
            }
          });
        },
        onOpenScanHistory: () {
          Navigator.of(context).pop();
          _openScanHistory(context, text);
        },
        onOpenPlans: () {
          Navigator.of(context).pop();
          _openPlansPage(context, text);
        },
        onOpenHelpSafety: () {
          Navigator.of(context).pop();
          _openHelpSafetyPage(context, text);
        },
        onLogout: widget.onLogout,
      ),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFBF9F4),
        elevation: 0,
        scrolledUnderElevation: 0,
        titleSpacing: 0,
        title: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.asset(
                SkinoAssets.logo,
                width: 34,
                height: 34,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 10),
            Flexible(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Skino',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Color(0xFF282420),
                      fontWeight: FontWeight.w600,
                      height: 1.0,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    text.isMyanmar
                        ? 'သင့်အသားအရေ AI assistant'
                        : 'Your AI skin care assistant',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF7A7169),
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      height: 1.0,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        iconTheme: const IconThemeData(color: Color(0xFF282420)),
        actions: [
          IconButton(
            tooltip: text.isMyanmar ? 'အသိပေးချက်များ' : 'Notifications',
            onPressed: () => _showNotificationsComingSoon(context, text),
            icon: const SkinoImageIcon(
              asset: SkinoAssets.iconReminder,
              size: 30,
              padding: 2,
              backgroundColor: Colors.transparent,
              borderRadius: 12,
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        top: false,
        child: PageView(
          controller: _pageController,
          onPageChanged: (index) => setState(() => _selectedIndex = index),
          children: pages,
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: _selectPage,
        backgroundColor: Colors.white,
        indicatorColor: const Color(0xFFFFEFE5),
        destinations: [
          NavigationDestination(
            icon: const SkinoImageIcon.nav(
              asset: SkinoAssets.navHome,
              size: 28,
              borderRadius: 10,
            ),
            selectedIcon: const SkinoImageIcon.nav(
              asset: SkinoAssets.navHome,
              size: 32,
              backgroundColor: Color(0xFFFFE3D1),
              borderRadius: 12,
            ),
            label: text.home,
          ),
          NavigationDestination(
            icon: const SkinoImageIcon.nav(
              asset: SkinoAssets.iconScan,
              size: 28,
              borderRadius: 10,
            ),
            selectedIcon: const SkinoImageIcon.nav(
              asset: SkinoAssets.iconScan,
              size: 32,
              backgroundColor: Color(0xFFFFE3D1),
              borderRadius: 12,
            ),
            label: text.scan,
          ),
          NavigationDestination(
            icon: const SkinoImageIcon.nav(
              asset: SkinoAssets.navChat,
              size: 28,
              borderRadius: 10,
            ),
            selectedIcon: const SkinoImageIcon.nav(
              asset: SkinoAssets.navChat,
              size: 32,
              backgroundColor: Color(0xFFFFE3D1),
              borderRadius: 12,
            ),
            label: 'Buddy',
          ),
          NavigationDestination(
            icon: const SkinoImageIcon.nav(
              asset: SkinoAssets.navSettings,
              size: 28,
              borderRadius: 10,
            ),
            selectedIcon: const SkinoImageIcon.nav(
              asset: SkinoAssets.navSettings,
              size: 32,
              backgroundColor: Color(0xFFFFE3D1),
              borderRadius: 12,
            ),
            label: text.settings,
          ),
        ],
      ),
    );
  }
}

class _SkinoDrawer extends StatelessWidget {
  const _SkinoDrawer({
    required this.text,
    required this.session,
    required this.result,
    required this.activeRoutine,
    required this.isLoading,
    required this.appointmentRequestMessage,
    required this.onRequestAppointment,
    required this.onOpenHome,
    required this.onOpenScan,
    required this.onOpenSettings,
    required this.onOpenCare,
    required this.onOpenScanHistory,
    required this.onOpenPlans,
    required this.onOpenHelpSafety,
    required this.onLogout,
  });

  final SkinoText text;
  final AuthSession? session;
  final SkinAnalysisResult? result;
  final ActiveRoutine? activeRoutine;
  final bool isLoading;
  final String? appointmentRequestMessage;
  final Future<void> Function(AppointmentRequestDraft draft)
  onRequestAppointment;
  final VoidCallback onOpenHome;
  final VoidCallback onOpenScan;
  final VoidCallback onOpenSettings;
  final VoidCallback onOpenCare;
  final VoidCallback onOpenScanHistory;
  final VoidCallback onOpenPlans;
  final VoidCallback onOpenHelpSafety;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    final drawerWidth = math.min(
      MediaQuery.sizeOf(context).width * 0.78,
      320.0,
    );

    return Drawer(
      width: drawerWidth,
      backgroundColor: const Color(0xFFFFF9F5),
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 22),
          children: [
            if (session == null)
              _GuestDrawerHeader(text: text)
            else
              ProfilePanel(user: session!.user),
            const SizedBox(height: 16),
            _DrawerSectionTitle('Main'),
            _DrawerItem(
              icon: Icons.home_outlined,
              assetIcon: SkinoAssets.navHome,
              title: text.home,
              subtitle: text.isMyanmar
                  ? 'Dashboard ကိုပြန်သွားမယ်'
                  : 'Back to the dashboard',
              onTap: onOpenHome,
            ),
            _DrawerItem(
              icon: Icons.center_focus_strong_outlined,
              assetIcon: SkinoAssets.iconScan,
              title: text.scan,
              subtitle: text.startLiveScanSubtitle,
              onTap: onOpenScan,
            ),
            _DrawerItem(
              icon: Icons.settings_outlined,
              assetIcon: SkinoAssets.navSettings,
              title: text.settings,
              subtitle: text.isMyanmar
                  ? 'Login, language နှင့် privacy'
                  : 'Login, language, and privacy',
              onTap: onOpenSettings,
            ),
            const SizedBox(height: 8),
            _DrawerSectionTitle(text.beautyWorkspace),
            _DrawerItem(
              icon: Icons.local_hospital_outlined,
              assetIcon: SkinoAssets.iconSpecialist,
              title: text.specialistAppointment,
              subtitle: text.specialistAppointmentSubtitle,
              onTap: () {
                Navigator.of(context).pop();
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => _SpecialistDirectoryPage(
                      text: text,
                      result: result,
                      activeRoutine: activeRoutine,
                      isGuest: session == null,
                      session: session,
                      isLoading: isLoading,
                      message: appointmentRequestMessage,
                      onSubmit: onRequestAppointment,
                      onOpenHome: onOpenHome,
                      onOpenScan: onOpenScan,
                      onOpenSettings: onOpenSettings,
                      onOpenCare: onOpenCare,
                      onOpenScanHistory: onOpenScanHistory,
                      onOpenHelpSafety: onOpenHelpSafety,
                      onLogout: onLogout,
                    ),
                  ),
                );
              },
            ),
            _DrawerItem(
              icon: Icons.spa_outlined,
              assetIcon: SkinoAssets.iconRoutine,
              title: text.care,
              subtitle: text.careSubtitle,
              onTap: onOpenCare,
            ),
            _DrawerItem(
              icon: Icons.history_rounded,
              assetIcon: SkinoAssets.iconHistory,
              title: text.analysisHistory,
              subtitle: text.analysisHistorySubtitle,
              onTap: onOpenScanHistory,
            ),
            _DrawerItem(
              icon: Icons.workspace_premium_outlined,
              title: text.isMyanmar ? 'Plans' : 'Plans',
              subtitle: text.isMyanmar
                  ? 'Scan package demo pricing'
                  : 'Demo pricing for scan packages',
              onTap: onOpenPlans,
            ),
            _DrawerItem(
              icon: Icons.health_and_safety_outlined,
              title: text.helpSafety,
              subtitle: text.helpSafetySubtitle,
              onTap: onOpenHelpSafety,
            ),
            const SizedBox(height: 10),
            if (session != null)
              OutlinedButton.icon(
                onPressed: onLogout,
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF9E2732),
                  side: const BorderSide(color: Color(0xFFFFC9C9)),
                ),
                icon: const Icon(Icons.logout_rounded),
                label: Text(text.logout),
              ),
          ],
        ),
      ),
    );
  }
}

class _GuestDrawerHeader extends StatelessWidget {
  const _GuestDrawerHeader({required this.text});

  final SkinoText text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF282420),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const CircleAvatar(
            backgroundColor: Color(0xFFFFE3D1),
            child: Icon(
              Icons.face_retouching_natural,
              color: Color(0xFFF98128),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            text.guestBeautyCheck,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 17,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            text.guestBeautySubtitle,
            style: const TextStyle(
              color: Color(0xFFE8E2DD),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _PageNavigationDrawer extends StatelessWidget {
  const _PageNavigationDrawer({
    required this.text,
    required this.session,
    required this.onOpenHome,
    required this.onOpenScan,
    required this.onOpenSettings,
    required this.onOpenSpecialist,
    required this.onOpenCare,
    required this.onOpenScanHistory,
    required this.onOpenHelpSafety,
    required this.onLogout,
  });

  final SkinoText text;
  final AuthSession? session;
  final VoidCallback onOpenHome;
  final VoidCallback onOpenScan;
  final VoidCallback onOpenSettings;
  final VoidCallback onOpenSpecialist;
  final VoidCallback? onOpenCare;
  final VoidCallback? onOpenScanHistory;
  final VoidCallback onOpenHelpSafety;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    final drawerWidth = math.min(
      MediaQuery.sizeOf(context).width * 0.78,
      320.0,
    );

    return Drawer(
      width: drawerWidth,
      backgroundColor: const Color(0xFFFFF9F5),
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 22),
          children: [
            if (session == null)
              _GuestDrawerHeader(text: text)
            else
              ProfilePanel(user: session!.user),
            const SizedBox(height: 16),
            _DrawerSectionTitle('Main'),
            _DrawerItem(
              icon: Icons.home_outlined,
              assetIcon: SkinoAssets.navHome,
              title: text.home,
              subtitle: text.isMyanmar
                  ? 'Dashboard ကိုပြန်သွားမယ်'
                  : 'Back to the dashboard',
              onTap: () => _closeThen(context, onOpenHome),
            ),
            _DrawerItem(
              icon: Icons.center_focus_strong_outlined,
              assetIcon: SkinoAssets.iconScan,
              title: text.scan,
              subtitle: text.startLiveScanSubtitle,
              onTap: () => _closeThen(context, onOpenScan),
            ),
            _DrawerItem(
              icon: Icons.settings_outlined,
              assetIcon: SkinoAssets.navSettings,
              title: text.settings,
              subtitle: text.isMyanmar
                  ? 'Login, language နှင့် privacy'
                  : 'Login, language, and privacy',
              onTap: () => _closeThen(context, onOpenSettings),
            ),
            const SizedBox(height: 8),
            _DrawerSectionTitle(text.beautyWorkspace),
            _DrawerItem(
              icon: Icons.local_hospital_outlined,
              assetIcon: SkinoAssets.iconSpecialist,
              title: text.specialistAppointment,
              subtitle: text.specialistAppointmentSubtitle,
              onTap: () => _closeThen(context, onOpenSpecialist),
            ),
            _DrawerItem(
              icon: Icons.spa_outlined,
              assetIcon: SkinoAssets.iconRoutine,
              title: text.care,
              subtitle: text.careSubtitle,
              onTap: onOpenCare == null
                  ? null
                  : () => _closeThen(context, onOpenCare!),
            ),
            _DrawerItem(
              icon: Icons.history_rounded,
              assetIcon: SkinoAssets.iconHistory,
              title: text.analysisHistory,
              subtitle: text.analysisHistorySubtitle,
              onTap: onOpenScanHistory == null
                  ? null
                  : () => _closeThen(context, onOpenScanHistory!),
            ),
            _DrawerItem(
              icon: Icons.health_and_safety_outlined,
              title: text.helpSafety,
              subtitle: text.helpSafetySubtitle,
              onTap: () => _closeThen(context, onOpenHelpSafety),
            ),
            const SizedBox(height: 10),
            if (session != null)
              OutlinedButton.icon(
                onPressed: () => _closeThen(context, onLogout),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF9E2732),
                  side: const BorderSide(color: Color(0xFFFFC9C9)),
                ),
                icon: const Icon(Icons.logout_rounded),
                label: Text(text.logout),
              ),
          ],
        ),
      ),
    );
  }

  void _closeThen(BuildContext context, VoidCallback action) {
    Navigator.of(context).pop();
    WidgetsBinding.instance.addPostFrameCallback((_) => action());
  }
}

class _HomePage extends StatelessWidget {
  const _HomePage({
    required this.text,
    required this.session,
    required this.result,
    required this.onStartScan,
    required this.onOpenCare,
    required this.onOpenScanHistory,
    required this.onOpenSpecialist,
    required this.onOpenHelpSafety,
    required this.onOpenPlans,
    required this.onOpenLatestResult,
    required this.activeRoutine,
  });

  final SkinoText text;
  final AuthSession? session;
  final SkinAnalysisResult? result;
  final VoidCallback onStartScan;
  final VoidCallback onOpenCare;
  final VoidCallback onOpenScanHistory;
  final VoidCallback onOpenSpecialist;
  final VoidCallback onOpenHelpSafety;
  final VoidCallback onOpenPlans;
  final VoidCallback? onOpenLatestResult;
  final ActiveRoutine? activeRoutine;

  @override
  Widget build(BuildContext context) {
    return _PageScaffold(
      children: [
        _HomeCarousel(text: text, result: result),
        const SizedBox(height: 14),
        _HomeQuickActionsCard(
          text: text,
          onOpenCare: onOpenCare,
          onOpenScanHistory: onOpenScanHistory,
          onOpenSpecialist: onOpenSpecialist,
          onOpenHelpSafety: onOpenHelpSafety,
        ),
        const SizedBox(height: 14),
        _PlanPreviewCard(text: text, onOpenPlans: onOpenPlans),
        if (result != null || activeRoutine != null) ...[
          const SizedBox(height: 14),
          _HomeTodayCareCard(
            text: text,
            activeRoutine: activeRoutine,
            hasScan: result != null,
            onOpenCare: onOpenCare,
          ),
        ],
        const SizedBox(height: 14),
        _HomeLatestScoreCard(
          text: text,
          result: result,
          onStartScan: onStartScan,
          onOpenResult: onOpenLatestResult,
        ),
      ],
    );
  }
}

class _PlanPreviewCard extends StatelessWidget {
  const _PlanPreviewCard({required this.text, required this.onOpenPlans});

  final SkinoText text;
  final VoidCallback onOpenPlans;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFF0E4), Color(0xFFFFFBF7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFFFD8BA)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x10F98128),
            blurRadius: 18,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          const SkinoImageIcon(
            asset: SkinoAssets.littleGuyFlying,
            size: 76,
            padding: 0,
            backgroundColor: Colors.transparent,
            borderRadius: 22,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  text.isMyanmar ? 'Choose Your Plan' : 'Choose Your Plan',
                  style: const TextStyle(
                    color: Color(0xFF2D1E16),
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  text.isMyanmar
                      ? 'Trial, scan packs, premium care'
                      : 'Trial, scan packs, premium care',
                  style: const TextStyle(
                    color: Color(0xFF75685E),
                    fontWeight: FontWeight.w700,
                    height: 1.25,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 74,
            child: FilledButton(
              onPressed: onOpenPlans,
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFF98128),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 10),
              ),
              child: const Text('View'),
            ),
          ),
        ],
      ),
    );
  }
}

class _PlansPage extends StatelessWidget {
  const _PlansPage({required this.text});

  final SkinoText text;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFBF7),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFFBF7),
        elevation: 0,
        scrolledUnderElevation: 0,
        foregroundColor: const Color(0xFF2D1E16),
        title: Text(
          text.isMyanmar ? 'Choose Your Plan' : 'Choose Your Plan',
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
      body: _PageScaffold(
        children: [
          _PlansHero(text: text),
          const SizedBox(height: 12),
          _PlanStoryStrip(text: text),
          const SizedBox(height: 18),
          _TrialPlanCard(text: text),
          const SizedBox(height: 20),
          _PlanSectionTitle(
            number: '2',
            title: text.isMyanmar
                ? 'Pay As You Go Plans'
                : 'Pay As You Go Plans',
            color: const Color(0xFF3D8B38),
          ),
          const SizedBox(height: 12),
          _PlanCard(
            name: 'Basic',
            scans: '5 scans',
            price: '3,000 MMK',
            color: const Color(0xFF4FA23C),
            icon: Icons.shield_rounded,
            mascotAsset: SkinoAssets.littleGuyCare,
            features: const [
              '5 face scans',
              'Valid for 7 days',
              'For personal use',
            ],
            buttonLabel: 'Choose Basic',
            onChoose: () => _showDemoPlanNotice(context, text),
          ),
          const SizedBox(height: 12),
          _PlanCard(
            name: 'Standard',
            badge: 'MOST POPULAR',
            scans: '12 scans',
            price: '8,000 MMK',
            color: const Color(0xFFF98128),
            icon: Icons.local_fire_department_rounded,
            mascotAsset: SkinoAssets.littleGuyOk,
            features: const [
              '12 face scans',
              'Valid for 14 days',
              'For regular care',
            ],
            buttonLabel: 'Choose Standard',
            onChoose: () => _showDemoPlanNotice(context, text),
          ),
          const SizedBox(height: 12),
          _PlanCard(
            name: 'Premium',
            scans: 'Unlimited scans',
            price: '10,000 MMK',
            color: const Color(0xFF8B3FD1),
            icon: Icons.workspace_premium_rounded,
            mascotAsset: SkinoAssets.littleGuyFlying,
            features: const [
              'Unlimited face scans',
              'Valid for 30 days',
              'Priority access to new features',
              'AI chatbot memory demo',
              'Future booking discounts',
            ],
            buttonLabel: 'Choose Premium',
            onChoose: () => _showDemoPlanNotice(context, text),
          ),
          const SizedBox(height: 20),
          _PlanSectionTitle(
            number: '3',
            title: text.isMyanmar ? 'For Premium Lovers' : 'For Premium Lovers',
            color: const Color(0xFF2F7ECB),
          ),
          const SizedBox(height: 12),
          _PremiumLoversCard(text: text),
          const SizedBox(height: 12),
          _PlanPrivacyNote(text: text),
        ],
      ),
    );
  }
}

void _showDemoPlanNotice(BuildContext context, SkinoText text) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(
        text.isMyanmar
            ? 'Demo UI only: payment/backend ကိုနောက်မှချိတ်ပါမယ်။'
            : 'Demo UI only: payment and backend will be connected later.',
      ),
    ),
  );
}

class _PlansHero extends StatelessWidget {
  const _PlansHero({required this.text});

  final SkinoText text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 12, 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFEFE3), Color(0xFFFFFAF4), Color(0xFFEAF7F1)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0xFFFFD8BA)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x18F98128),
            blurRadius: 26,
            offset: Offset(0, 16),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  text.isMyanmar ? 'Choose Your Plan' : 'Choose Your Plan',
                  style: const TextStyle(
                    color: Color(0xFF2D1E16),
                    fontSize: 29,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  text.isMyanmar
                      ? 'Pick the plan that fits your skin journey'
                      : 'Pick the plan that fits your skin journey',
                  style: const TextStyle(
                    color: Color(0xFF75685E),
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: const [
                    _PlanFeatureChip(
                      label: 'Demo pricing',
                      color: Color(0xFFF98128),
                    ),
                    _PlanFeatureChip(
                      label: 'Scan credits',
                      color: Color(0xFF3B8F65),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          const SkinoImageIcon(
            asset: SkinoAssets.littleGuyWave,
            size: 112,
            padding: 0,
            backgroundColor: Colors.transparent,
            borderRadius: 32,
          ),
        ],
      ),
    );
  }
}

class _PlanStoryStrip extends StatelessWidget {
  const _PlanStoryStrip({required this.text});

  final SkinoText text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _PlanStoryPill(
            asset: SkinoAssets.iconScan,
            title: 'Scan',
            caption: text.isMyanmar ? 'Face analysis' : 'Face analysis',
            color: const Color(0xFFF98128),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _PlanStoryPill(
            asset: SkinoAssets.iconRoutine,
            title: 'Care',
            caption: text.isMyanmar ? 'Routine guide' : 'Routine guide',
            color: const Color(0xFF3B8F65),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _PlanStoryPill(
            asset: SkinoAssets.iconChat,
            title: 'Buddy',
            caption: text.isMyanmar ? 'AI support' : 'AI support',
            color: const Color(0xFF8B3FD1),
          ),
        ),
      ],
    );
  }
}

class _PlanStoryPill extends StatelessWidget {
  const _PlanStoryPill({
    required this.asset,
    required this.title,
    required this.caption,
    required this.color,
  });

  final String asset;
  final String title;
  final String caption;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withValues(alpha: 0.2)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D4B2F1F),
            blurRadius: 14,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          SkinoImageIcon(
            asset: asset,
            size: 34,
            padding: 3,
            backgroundColor: color.withValues(alpha: 0.1),
            borderRadius: 12,
          ),
          const SizedBox(height: 7),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            caption,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFF7B7067),
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _PlanSectionTitle extends StatelessWidget {
  const _PlanSectionTitle({
    required this.number,
    required this.title,
    required this.color,
  });

  final String number;
  final String title;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        CircleAvatar(
          radius: 18,
          backgroundColor: color,
          child: Text(
            number,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              color: Color(0xFF2D1E16),
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ],
    );
  }
}

class _TrialPlanCard extends StatelessWidget {
  const _TrialPlanCard({required this.text});

  final SkinoText text;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _PlanSectionTitle(
          number: '1',
          title: text.isMyanmar ? 'Free Plan (Trial)' : 'Free Plan (Trial)',
          color: const Color(0xFFF98128),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFFFFD8BA)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x10F98128),
                blurRadius: 20,
                offset: Offset(0, 12),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                children: [
                  const SkinoImageIcon(
                    asset: SkinoAssets.littleGuyMagnifier,
                    size: 96,
                    padding: 0,
                    backgroundColor: Colors.transparent,
                    borderRadius: 28,
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Free 1 Face Scan',
                          style: TextStyle(
                            color: Color(0xFFF05A13),
                            fontSize: 23,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        SizedBox(height: 5),
                        Text(
                          'Create an account and get 1 free scan.',
                          style: TextStyle(
                            color: Color(0xFF43352D),
                            fontWeight: FontWeight.w700,
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFEFE3),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFFFD6B8)),
                    ),
                    child: const Text(
                      '0\nMMK',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Color(0xFFF05A13),
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        height: 1.02,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: const [
                  _PlanFeatureChip(
                    label: '1 face scan',
                    color: Color(0xFF5FAE41),
                  ),
                  _PlanFeatureChip(
                    label: 'Valid for 1 day',
                    color: Color(0xFFF98128),
                  ),
                  _PlanFeatureChip(
                    label: 'Create account',
                    color: Color(0xFF5FAE41),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => _showDemoPlanNotice(context, text),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFFF98128),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 13),
                  ),
                  child: const Text('Get Started'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({
    required this.name,
    required this.scans,
    required this.price,
    required this.color,
    required this.icon,
    required this.mascotAsset,
    required this.features,
    required this.buttonLabel,
    required this.onChoose,
    this.badge,
  });

  final String name;
  final String scans;
  final String price;
  final Color color;
  final IconData icon;
  final String mascotAsset;
  final List<String> features;
  final String buttonLabel;
  final VoidCallback onChoose;
  final String? badge;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.white, color.withValues(alpha: 0.055)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: color.withValues(alpha: 0.28), width: 1.4),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F4B2F1F),
            blurRadius: 18,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (badge != null) ...[
            Align(
              alignment: Alignment.center,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  badge!,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: color.withValues(alpha: 0.16)),
                ),
                child: Icon(icon, color: color, size: 30),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: TextStyle(
                        color: color,
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      name == 'Premium'
                          ? 'For your full Skino journey'
                          : name == 'Standard'
                          ? 'Best demo value for judging'
                          : 'Simple start for first users',
                      style: const TextStyle(
                        color: Color(0xFF74685F),
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        height: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
              SkinoImageIcon(
                asset: mascotAsset,
                size: 62,
                padding: 0,
                backgroundColor: Colors.transparent,
                borderRadius: 18,
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.09),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: color.withValues(alpha: 0.2)),
            ),
            child: Column(
              children: [
                Text(
                  price,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: color,
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  scans,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xFF5D5149),
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          for (final feature in features)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _PlanCheckRow(label: feature, color: color),
            ),
          const SizedBox(height: 8),
          FilledButton(
            onPressed: onChoose,
            style: FilledButton.styleFrom(
              backgroundColor: color,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 13),
            ),
            child: Text(buttonLabel),
          ),
        ],
      ),
    );
  }
}

class _PremiumLoversCard extends StatelessWidget {
  const _PremiumLoversCard({required this.text});

  final SkinoText text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFD7E4F7)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D2F7ECB),
            blurRadius: 18,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              const SkinoImageIcon(
                asset: SkinoAssets.littleGuyLaptop,
                size: 82,
                padding: 0,
                backgroundColor: Colors.transparent,
                borderRadius: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  text.isMyanmar
                      ? 'More scans, stronger care, better demo story for premium users.'
                      : 'More scans, stronger care, better demo story for premium users.',
                  style: const TextStyle(
                    color: Color(0xFF263B57),
                    fontWeight: FontWeight.w800,
                    height: 1.35,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Row(
            children: [
              Expanded(
                child: _PlanMiniBenefit(
                  icon: Icons.card_giftcard_rounded,
                  label: 'Best value',
                  color: Color(0xFFF98128),
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                child: _PlanMiniBenefit(
                  icon: Icons.lock_outline_rounded,
                  label: 'Private data',
                  color: Color(0xFF3B8F65),
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                child: _PlanMiniBenefit(
                  icon: Icons.workspace_premium_rounded,
                  label: 'Premium care',
                  color: Color(0xFF8B3FD1),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PlanPrivacyNote extends StatelessWidget {
  const _PlanPrivacyNote({required this.text});

  final SkinoText text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3E8),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFFFDCC4)),
      ),
      child: Row(
        children: [
          const Icon(Icons.verified_user_rounded, color: Color(0xFF5FAE41)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text.isMyanmar
                  ? 'Your skin, your data. Demo screen only, no payment is processed.'
                  : 'Your skin, your data. Demo screen only, no payment is processed.',
              style: const TextStyle(
                color: Color(0xFF5C4D44),
                fontWeight: FontWeight.w800,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PlanFeatureChip extends StatelessWidget {
  const _PlanFeatureChip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.24)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.check_circle_rounded, color: color, size: 17),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF4C4038),
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _PlanCheckRow extends StatelessWidget {
  const _PlanCheckRow({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(Icons.check_circle_rounded, color: color, size: 19),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              color: Color(0xFF4C4038),
              fontWeight: FontWeight.w700,
              height: 1.25,
            ),
          ),
        ),
      ],
    );
  }
}

class _PlanMiniBenefit extends StatelessWidget {
  const _PlanMiniBenefit({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 5),
          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFF4C4038),
              fontSize: 11,
              fontWeight: FontWeight.w800,
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}

void _showNotificationsComingSoon(BuildContext context, SkinoText text) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(
        text.isMyanmar
            ? 'Routine reminder နှင့် next scan notification ကို နောက်တစ်ဆင့်မှာ ဒီနေရာကနေကြည့်မယ်။'
            : 'Routine reminders and next scan notifications will appear here next.',
      ),
    ),
  );
}

class _BuddyPage extends StatefulWidget {
  const _BuddyPage({
    required this.text,
    required this.apiBaseUrl,
    required this.session,
    required this.result,
    required this.activeRoutine,
    required this.onStartScan,
    required this.onOpenCare,
  });

  final SkinoText text;
  final String apiBaseUrl;
  final AuthSession? session;
  final SkinAnalysisResult? result;
  final ActiveRoutine? activeRoutine;
  final VoidCallback onStartScan;
  final VoidCallback onOpenCare;

  @override
  State<_BuddyPage> createState() => _BuddyPageState();
}

class _BuddyPageState extends State<_BuddyPage> {
  final BuddyChatApi _api = const BuddyChatApi();
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<_BuddyMessage> _messages = [];
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    _messages.add(_BuddyMessage.assistant(_welcomeMessage));
  }

  @override
  void didUpdateWidget(covariant _BuddyPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.result?.id != widget.result?.id ||
        oldWidget.activeRoutine?.id != widget.activeRoutine?.id ||
        oldWidget.text.isMyanmar != widget.text.isMyanmar) {
      setState(() {
        _messages
          ..clear()
          ..add(_BuddyMessage.assistant(_welcomeMessage));
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  String get _welcomeMessage {
    if (widget.session == null) {
      return widget.text.isMyanmar
          ? 'Buddy chat သုံးဖို့ login လုပ်ပါ။ Gemini key ကို phone ထဲမထားဘဲ backend ကနေ လုံခြုံစွာ ခေါ်ပါမယ်။'
          : 'Log in to use Buddy chat. The Gemini key stays on the backend, not inside the phone app.';
    }

    if (widget.result == null) {
      return widget.text.isMyanmar
          ? 'Scan တစ်ခုလုပ်ပြီးရင် သင့် result နဲ့ routine အပေါ်မူတည်ပြီး မေးခွန်းတွေ ဖြေကူမယ်။'
          : 'Start with a scan, then I can answer using your result and routine context.';
    }

    if (widget.activeRoutine != null) {
      return widget.text.isMyanmar
          ? 'သင့် scan နဲ့ active routine ကိုမြင်ထားပါတယ်။ ဒီနေ့ဘာလုပ်ရမလဲ၊ result ဘာဆိုလိုလဲ မေးနိုင်ပါတယ်။'
          : 'I can see your latest scan and active routine. Ask what to do today, what the result means, or when to rescan.';
    }

    return widget.text.isMyanmar
        ? 'သင့် latest scan ကိုမြင်ထားပါတယ်။ Routine စဖို့မတိုင်ခင် result ကိုရှင်းပြပေးနိုင်ပါတယ်။'
        : 'I can see your latest scan. Ask me to explain it before you start a routine.';
  }

  Future<void> _send([String? quickPrompt]) async {
    final message = (quickPrompt ?? _controller.text).trim();
    final session = widget.session;

    if (message.isEmpty || _isSending || session == null) {
      return;
    }

    _controller.clear();
    setState(() {
      _messages.add(_BuddyMessage.user(message));
      _isSending = true;
    });
    _scrollToLatest();

    try {
      final reply = await _api.ask(
        baseUrl: widget.apiBaseUrl,
        session: session,
        message: message,
        result: widget.result,
        activeRoutine: widget.activeRoutine,
      );

      if (!mounted) return;
      setState(() => _messages.add(_BuddyMessage.assistant(reply)));
      _scrollToLatest();
    } on ApiException catch (exception) {
      if (!mounted) return;
      setState(() => _messages.add(_BuddyMessage.assistant(exception.message)));
      _scrollToLatest();
    } catch (_) {
      if (!mounted) return;
      setState(
        () => _messages.add(
          _BuddyMessage.assistant(
            widget.text.isMyanmar
                ? 'Buddy ခဏအလုပ်မလုပ်နိုင်သေးပါ။ နောက်တစ်ကြိမ်ပြန်စမ်းပါ။'
                : 'Buddy could not answer right now. Try again soon.',
          ),
        ),
      );
      _scrollToLatest();
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
      }
    }
  }

  void _scrollToLatest() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) {
        return;
      }

      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 240),
        curve: Curves.easeOutCubic,
      );
    });
  }

  void _showChatHistory() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.58,
          minChildSize: 0.34,
          maxChildSize: 0.88,
          builder: (context, controller) {
            return Container(
              decoration: const BoxDecoration(
                color: Color(0xFFFFFBF7),
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 10),
                  Container(
                    width: 42,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE4D6CA),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 10),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.history_rounded,
                          color: Color(0xFFF98128),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.text.isMyanmar
                                    ? 'Chat history'
                                    : 'Chat history',
                                style: const TextStyle(
                                  color: Color(0xFF282420),
                                  fontSize: 20,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                widget.text.isMyanmar
                                    ? 'This session only. Backend memory is future premium work.'
                                    : 'This session only. Backend memory is future premium work.',
                                style: const TextStyle(
                                  color: Color(0xFF75685E),
                                  fontWeight: FontWeight.w700,
                                  height: 1.25,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: ListView.separated(
                      controller: controller,
                      padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                      itemBuilder: (context, index) {
                        final message = _messages[index];
                        return _BuddyHistoryTile(message: message);
                      },
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
                      itemCount: _messages.length,
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasRoutine = widget.activeRoutine != null;
    final hasScan = widget.result != null;
    final canChat = widget.session != null;
    final quickPrompts = widget.text.isMyanmar
        ? ['ဒီည ဘာလုပ်ရမလဲ?', 'Result ကိုရှင်းပြပါ', 'ဘယ်နေ့ rescan လုပ်ရမလဲ?']
        : [
            'What should I do tonight?',
            'Explain my result',
            'When should I rescan?',
          ];

    return _PageScaffold(
      children: [
        _PageTitle(
          title: 'Little Guy',
          subtitle: widget.text.isMyanmar
              ? 'Scan နဲ့ routine context ပေါ်မူတည်ပြီးသာ ဖြေကူတဲ့ Gemini Buddy ပါ။'
              : 'A Gemini Buddy that only answers from your scan and routine context.',
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.96),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFFFFE3D1)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x12F98128),
                blurRadius: 22,
                offset: Offset(0, 12),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _BuddyHeader(
                text: widget.text,
                hasScan: hasScan,
                hasRoutine: hasRoutine,
                canChat: canChat,
                messageCount: _messages.length,
                onOpenHistory: _showChatHistory,
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: quickPrompts
                    .map(
                      (prompt) => ActionChip(
                        onPressed: canChat && hasScan && !_isSending
                            ? () => _send(prompt)
                            : null,
                        avatar: const Icon(
                          Icons.auto_awesome_rounded,
                          size: 16,
                        ),
                        backgroundColor: Colors.white,
                        disabledColor: const Color(0xFFF4ECE6),
                        side: const BorderSide(color: Color(0xFFFFDCC4)),
                        labelStyle: const TextStyle(
                          color: Color(0xFF6E4B32),
                          fontWeight: FontWeight.w800,
                        ),
                        label: Text(prompt),
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 14),
              Container(
                height: 292,
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF9F4),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: const Color(0xFFFFE7D6)),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x0AF98128),
                      blurRadius: 18,
                      offset: Offset(0, 10),
                    ),
                  ],
                ),
                child: ListView(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  children: [
                    for (final message in _messages)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _BuddyBubble(message: message),
                      ),
                    if (_isSending) const _BuddyTypingBubble(),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              if (!canChat)
                _BuddyNotice(
                  text: widget.text.isMyanmar
                      ? 'Gemini chat သုံးရန် account login လိုအပ်ပါတယ်။'
                      : 'Log in to use Gemini chat safely through the backend.',
                )
              else if (!hasScan)
                _BuddyNotice(
                  text: widget.text.isMyanmar
                      ? 'Buddy ကို context ပေးဖို့ scan တစ်ခုအရင်လုပ်ပါ။'
                      : 'Run a scan first so Buddy has useful context.',
                )
              else
                _BuddyComposer(
                  controller: _controller,
                  enabled: !_isSending,
                  hint: widget.text.isMyanmar
                      ? 'Routine သို့ result မေးပါ...'
                      : 'Ask about your routine or result...',
                  onSend: () => _send(),
                ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: widget.onStartScan,
                      icon: const SkinoImageIcon(
                        asset: SkinoAssets.iconScan,
                        size: 22,
                        padding: 1,
                        backgroundColor: Colors.transparent,
                        borderRadius: 8,
                      ),
                      label: Text(widget.text.startScan),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: hasRoutine ? widget.onOpenCare : null,
                      icon: const SkinoImageIcon(
                        asset: SkinoAssets.iconRoutine,
                        size: 22,
                        padding: 1,
                        backgroundColor: Colors.transparent,
                        borderRadius: 8,
                      ),
                      label: Text(widget.text.care),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _BuddyMessage {
  const _BuddyMessage({required this.content, required this.isUser});

  factory _BuddyMessage.user(String content) {
    return _BuddyMessage(content: content, isUser: true);
  }

  factory _BuddyMessage.assistant(String content) {
    return _BuddyMessage(content: content, isUser: false);
  }

  final String content;
  final bool isUser;
}

class _BuddyHeader extends StatelessWidget {
  const _BuddyHeader({
    required this.text,
    required this.hasScan,
    required this.hasRoutine,
    required this.canChat,
    required this.messageCount,
    required this.onOpenHistory,
  });

  final SkinoText text;
  final bool hasScan;
  final bool hasRoutine;
  final bool canChat;
  final int messageCount;
  final VoidCallback onOpenHistory;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          colors: [Color(0xFFFFF5EC), Color(0xFFEAF7F1)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: const Color(0xFFFFDCC5)),
      ),
      child: Row(
        children: [
          Container(
            width: 86,
            height: 86,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.8),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: Colors.white),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x1AF98128),
                  blurRadius: 18,
                  offset: Offset(0, 10),
                ),
              ],
            ),
            child: const SkinoImageIcon(
              asset: SkinoAssets.navChat,
              size: 78,
              padding: 0,
              backgroundColor: Colors.transparent,
              borderRadius: 26,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Skino Little Guy',
                  style: const TextStyle(
                    color: Color(0xFF282420),
                    fontSize: 21,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  text.isMyanmar
                      ? 'သင့် scan နဲ့ routine အတွက်ပဲ ဖြေကူမယ်'
                      : 'Focused on your scan and routine',
                  style: const TextStyle(
                    color: Color(0xFF655C55),
                    fontWeight: FontWeight.w700,
                    height: 1.25,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    _BuddyStatusPill(
                      label: canChat
                          ? (text.isMyanmar ? 'Login OK' : 'Logged in')
                          : (text.isMyanmar ? 'Login လို' : 'Login needed'),
                      active: canChat,
                    ),
                    _BuddyStatusPill(
                      label: hasScan
                          ? (text.isMyanmar ? 'Scan ရှိ' : 'Scan ready')
                          : (text.isMyanmar ? 'Scan လို' : 'Need scan'),
                      active: hasScan,
                    ),
                    _BuddyStatusPill(
                      label: hasRoutine
                          ? (text.isMyanmar ? 'Routine on' : 'Routine on')
                          : (text.isMyanmar ? 'No routine' : 'No routine'),
                      active: hasRoutine,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          IconButton.filledTonal(
            tooltip: text.isMyanmar ? 'Chat history' : 'Chat history',
            onPressed: onOpenHistory,
            style: IconButton.styleFrom(
              backgroundColor: Colors.white.withValues(alpha: 0.78),
              foregroundColor: const Color(0xFFF98128),
            ),
            icon: Badge.count(
              count: messageCount,
              isLabelVisible: messageCount > 1,
              child: const Icon(Icons.history_rounded),
            ),
          ),
        ],
      ),
    );
  }
}

class _BuddyHistoryTile extends StatelessWidget {
  const _BuddyHistoryTile({required this.message});

  final _BuddyMessage message;

  @override
  Widget build(BuildContext context) {
    final color = message.isUser
        ? const Color(0xFFF98128)
        : const Color(0xFF3B8F65);
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: color.withValues(alpha: 0.12),
            child: Icon(
              message.isUser
                  ? Icons.person_rounded
                  : Icons.auto_awesome_rounded,
              color: color,
              size: 18,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  message.isUser ? 'You' : 'Skino Buddy',
                  style: TextStyle(
                    color: color,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  message.content,
                  style: const TextStyle(
                    color: Color(0xFF4E4741),
                    fontWeight: FontWeight.w700,
                    height: 1.35,
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

class _BuddyStatusPill extends StatelessWidget {
  const _BuddyStatusPill({required this.label, required this.active});

  final String label;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: active ? const Color(0xFFE7F6EE) : const Color(0xFFFFEEE4),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(
          color: active ? const Color(0xFFBFE7D0) : const Color(0xFFFFD1B8),
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: active ? const Color(0xFF287050) : const Color(0xFF9A4D28),
          fontSize: 11,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _BuddyBubble extends StatelessWidget {
  const _BuddyBubble({required this.message});

  final _BuddyMessage message;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: message.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 314),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (!message.isUser) ...[
              const SkinoImageIcon(
                asset: SkinoAssets.navChat,
                size: 30,
                padding: 0,
                backgroundColor: Color(0xFFFFF1E8),
                borderRadius: 10,
              ),
              const SizedBox(width: 7),
            ],
            Flexible(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 11,
                ),
                decoration: BoxDecoration(
                  color: message.isUser
                      ? const Color(0xFFF98128)
                      : Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(18),
                    topRight: const Radius.circular(18),
                    bottomLeft: Radius.circular(message.isUser ? 18 : 6),
                    bottomRight: Radius.circular(message.isUser ? 6 : 18),
                  ),
                  border: Border.all(
                    color: message.isUser
                        ? const Color(0xFFF98128)
                        : const Color(0xFFFFE1CF),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: message.isUser
                          ? const Color(0x1AF98128)
                          : const Color(0x0F4B2F1F),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Text(
                  message.content,
                  style: TextStyle(
                    color: message.isUser
                        ? Colors.white
                        : const Color(0xFF4E4741),
                    fontWeight: FontWeight.w600,
                    height: 1.38,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BuddyTypingBubble extends StatelessWidget {
  const _BuddyTypingBubble();

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFFFE1CF)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0F4B2F1F),
              blurRadius: 12,
              offset: Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            SizedBox(
              width: 17,
              height: 17,
              child: CircularProgressIndicator(strokeWidth: 2.2),
            ),
            SizedBox(width: 9),
            Text(
              'Thinking',
              style: TextStyle(
                color: Color(0xFF7C6555),
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BuddyNotice extends StatelessWidget {
  const _BuddyNotice({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3EC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFFDEC7)),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Color(0xFF7C4D2D),
          fontWeight: FontWeight.w700,
          height: 1.3,
        ),
      ),
    );
  }
}

class _BuddyComposer extends StatelessWidget {
  const _BuddyComposer({
    required this.controller,
    required this.enabled,
    required this.hint,
    required this.onSend,
  });

  final TextEditingController controller;
  final bool enabled;
  final String hint;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFFFDEC7)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0FF98128),
            blurRadius: 16,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              enabled: enabled,
              minLines: 1,
              maxLines: 3,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => onSend(),
              decoration: InputDecoration(
                hintText: hint,
                filled: true,
                fillColor: const Color(0xFFFFF8F3),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(
                    color: Color(0xFFF98128),
                    width: 1.4,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 48,
            height: 48,
            child: IconButton.filled(
              onPressed: enabled ? onSend : null,
              style: IconButton.styleFrom(
                backgroundColor: const Color(0xFFF98128),
                disabledBackgroundColor: const Color(0xFFFFD9C1),
                foregroundColor: Colors.white,
              ),
              icon: const Icon(Icons.send_rounded),
            ),
          ),
        ],
      ),
    );
  }
}

class _HomeCarousel extends StatelessWidget {
  const _HomeCarousel({required this.text, required this.result});

  final SkinoText text;
  final SkinAnalysisResult? result;

  @override
  Widget build(BuildContext context) {
    final cards = [
      _PromoCard(
        icon: Icons.center_focus_strong_rounded,
        assetIcon: SkinoAssets.iconScan,
        title: text.isMyanmar ? 'မျက်နှာအလှစကင်' : 'AI skin scan',
        subtitle: result == null
            ? text.faceBeautyScanSubtitle
            : text.latestSeverity(result!.acneSeverity),
        backgroundColor: const Color(0xFF0E5C56),
        backgroundImage: 'assets/home/ai_skin_scan.jpg',
      ),
      _PromoCard(
        icon: Icons.spa_rounded,
        assetIcon: SkinoAssets.iconRoutine,
        title: text.isMyanmar ? 'နေ့စဉ် progress' : 'Daily progress',
        subtitle: text.isMyanmar
            ? 'မနက်/ည care ကို နေ့တိုင်း rhythm အဖြစ် ဆက်လုပ်ပါ။'
            : 'Keep morning and night care moving as a daily rhythm.',
        backgroundColor: const Color(0xFFF98128),
        backgroundImage: 'assets/home/daily_routine.jpg',
      ),
      _PromoCard(
        icon: Icons.local_hospital_outlined,
        assetIcon: SkinoAssets.iconSpecialist,
        title: text.isMyanmar ? 'Specialist help' : 'Specialist help',
        subtitle: result == null
            ? (text.isMyanmar
                  ? 'လိုအပ်ရင် specialist appointment ကို scan result နဲ့ ချိတ်နိုင်ပါတယ်။'
                  : 'Use your scan result when specialist care is needed.')
            : (text.isMyanmar
                  ? '${text.latestScore(result!.skinHealthScore)} • လိုအပ်ရင် specialist ကိုပြပါ။'
                  : '${text.latestScore(result!.skinHealthScore)} • Ask a specialist when needed.'),
        backgroundColor: const Color(0xFF7A8F72),
        backgroundImage: 'assets/home/specialist_help.jpg',
      ),
    ];

    return SizedBox(
      height: 156,
      child: PageView.builder(
        itemCount: cards.length,
        controller: PageController(viewportFraction: 0.94),
        itemBuilder: (context, index) => cards[index],
      ),
    );
  }
}

class _HomeTodayCareCard extends StatelessWidget {
  const _HomeTodayCareCard({
    required this.text,
    required this.activeRoutine,
    required this.hasScan,
    required this.onOpenCare,
  });

  final SkinoText text;
  final ActiveRoutine? activeRoutine;
  final bool hasScan;
  final VoidCallback onOpenCare;

  @override
  Widget build(BuildContext context) {
    final active = activeRoutine;
    final morningDone = active?.today.morningDone ?? false;
    final nightDone = active?.today.nightDone ?? false;
    final completedCount = [
      morningDone,
      nightDone,
    ].where((done) => done).length;
    final routineName = active?.routine.name;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFFFE3D1)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0FF98128),
            blurRadius: 16,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                alignment: Alignment.center,
                child: const SkinoImageIcon(
                  asset: SkinoAssets.iconProgress,
                  size: 52,
                  padding: 5,
                  backgroundColor: Color(0xFFEAF6F1),
                  borderRadius: 17,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      text.isMyanmar
                          ? 'ဒီနေ့ care rhythm'
                          : 'Today care rhythm',
                      style: const TextStyle(
                        color: Color(0xFF282420),
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      routineName ??
                          (text.isMyanmar
                              ? 'Routine စထားမှ ဒီနေရာမှာ progress ပြပါမယ်။'
                              : 'Start from your scan to track morning and night care.'),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF68625B),
                        fontWeight: FontWeight.w500,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              _StatusPill(
                label: '$completedCount/2',
                color: completedCount == 2
                    ? const Color(0xFF0E5C56)
                    : const Color(0xFFF47C22),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _HomeRoutineStatusDot(label: text.morningCare, done: morningDone),
              const SizedBox(width: 12),
              _HomeRoutineStatusDot(label: text.nightCare, done: nightDone),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: hasScan || active != null ? onOpenCare : null,
              icon: const SkinoImageIcon(
                asset: SkinoAssets.iconRoutine,
                size: 22,
                padding: 1,
                backgroundColor: Colors.transparent,
                borderRadius: 8,
              ),
              label: Text(text.isMyanmar ? 'Care ကိုဖွင့်မယ်' : 'Open Care'),
              style: FilledButton.styleFrom(
                backgroundColor: active == null && !hasScan
                    ? const Color(0xFFE7E2DC)
                    : const Color(0xFFF47C22),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HomeLatestScoreCard extends StatelessWidget {
  const _HomeLatestScoreCard({
    required this.text,
    required this.result,
    required this.onStartScan,
    required this.onOpenResult,
  });

  final SkinoText text;
  final SkinAnalysisResult? result;
  final VoidCallback onStartScan;
  final VoidCallback? onOpenResult;

  @override
  Widget build(BuildContext context) {
    final scan = result;
    final topConcern = scan == null
        ? text.noStrongConcern
        : scan.concerns.isEmpty
        ? text.noStrongConcern
        : text.concernLabel(scan.concerns.first.name);
    final scanTime = scan?.createdAt == null
        ? (text.isMyanmar ? 'အခုလေးတင်' : 'Just now')
        : _formatScanTimestamp(scan!.createdAt);

    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFFFE3D1)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFF98128).withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _HomeScoreBadge(score: scan?.skinHealthScore),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            scan == null
                                ? (text.isMyanmar
                                      ? 'နောက်ဆုံး report မရှိသေးပါ'
                                      : 'No latest report yet')
                                : (text.isMyanmar
                                      ? 'နောက်ဆုံး Scan Result'
                                      : 'Latest skin report'),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Color(0xFF282420),
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        if (scan != null)
                          _StatusPill(
                            label: scan.id == null
                                ? 'Local'
                                : 'Scan #${scan.id}',
                            color: const Color(0xFFF47C22),
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      scan == null
                          ? (text.isMyanmar
                                ? 'ပထမဆုံး scan လုပ်ပြီး skin score နဲ့ report ကို သိနိုင်ပါတယ်။'
                                : 'Run your first scan to see your skin score and report.')
                          : '${text.concernLabel(scan.skinType)} • $topConcern',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF68625B),
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        height: 1.35,
                      ),
                    ),
                    if (scan != null) ...[
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 7,
                        runSpacing: 7,
                        children: [
                          _HomeReportChip(
                            icon: Icons.auto_awesome_rounded,
                            label: text.concernLabel(scan.skinType),
                          ),
                          _HomeReportChip(
                            icon: Icons.flag_rounded,
                            label: topConcern,
                          ),
                          _HomeReportChip(
                            icon: Icons.schedule_rounded,
                            label: scanTime,
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 13),
          FilledButton.icon(
            onPressed: scan == null ? onStartScan : onOpenResult,
            icon: scan == null
                ? const SkinoImageIcon(
                    asset: SkinoAssets.iconScan,
                    size: 22,
                    padding: 1,
                    backgroundColor: Colors.transparent,
                    borderRadius: 8,
                  )
                : const Icon(Icons.insert_chart_outlined_rounded, size: 18),
            label: Text(
              scan == null
                  ? (text.isMyanmar ? 'ပထမဆုံး Scan စမယ်' : 'Start first scan')
                  : (text.isMyanmar ? 'Result ကြည့်မယ်' : 'View result'),
            ),
            style: FilledButton.styleFrom(
              backgroundColor: scan == null
                  ? const Color(0xFFF47C22)
                  : const Color(0xFFFFF3EC),
              foregroundColor: scan == null
                  ? Colors.white
                  : const Color(0xFFF47C22),
              minimumSize: const Size(0, 46),
              padding: const EdgeInsets.symmetric(horizontal: 14),
            ),
          ),
        ],
      ),
    );
  }
}

class _HomeReportChip extends StatelessWidget {
  const _HomeReportChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7F1),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFFFE3D1)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: const Color(0xFFF47C22), size: 14),
          const SizedBox(width: 5),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 150),
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFF625B53),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HomeQuickActionsCard extends StatelessWidget {
  const _HomeQuickActionsCard({
    required this.text,
    required this.onOpenCare,
    required this.onOpenScanHistory,
    required this.onOpenSpecialist,
    required this.onOpenHelpSafety,
  });

  final SkinoText text;
  final VoidCallback onOpenCare;
  final VoidCallback onOpenScanHistory;
  final VoidCallback onOpenSpecialist;
  final VoidCallback onOpenHelpSafety;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFFFE3D1)),
      ),
      child: Row(
        children: [
          _HomeMiniAction(
            icon: Icons.eco_rounded,
            assetIcon: SkinoAssets.iconProgress,
            label: text.isMyanmar ? 'Routine' : 'Routine',
            accent: const Color(0xFF63A762),
            onTap: onOpenCare,
          ),
          _HomeActionDivider(),
          _HomeMiniAction(
            icon: Icons.description_rounded,
            assetIcon: SkinoAssets.iconReport,
            label: text.isMyanmar ? 'Report' : 'Report',
            accent: const Color(0xFFF47C22),
            onTap: onOpenScanHistory,
          ),
          _HomeActionDivider(),
          _HomeMiniAction(
            icon: Icons.local_hospital_rounded,
            assetIcon: SkinoAssets.iconSpecialist,
            label: text.isMyanmar ? 'Doctor' : 'Doctor',
            accent: const Color(0xFFF47C22),
            onTap: onOpenSpecialist,
          ),
          _HomeActionDivider(),
          _HomeMiniAction(
            icon: Icons.help_outline_rounded,
            label: text.isMyanmar ? 'Help' : 'Help',
            accent: const Color(0xFFF47C22),
            onTap: onOpenHelpSafety,
          ),
        ],
      ),
    );
  }
}

class _HomeScoreBadge extends StatelessWidget {
  const _HomeScoreBadge({required this.score});

  final int? score;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 54,
      height: 54,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: score == null
            ? const Color(0xFFFFE3D1)
            : const Color(0xFF0E5C56),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Text(
        score?.toString() ?? '--',
        style: TextStyle(
          color: score == null ? const Color(0xFFF98128) : Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _HomeRoutineStatusDot extends StatelessWidget {
  const _HomeRoutineStatusDot({required this.label, required this.done});

  final String label;
  final bool done;

  @override
  Widget build(BuildContext context) {
    return Flexible(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            done ? Icons.check_circle_rounded : Icons.circle_outlined,
            size: 16,
            color: done ? const Color(0xFF0E5C56) : const Color(0xFFB8B0A7),
          ),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFF625B53),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HomeMiniAction extends StatelessWidget {
  const _HomeMiniAction({
    required this.icon,
    required this.label,
    required this.accent,
    this.assetIcon,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final Color accent;
  final String? assetIcon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (assetIcon == null)
                Icon(icon, color: accent, size: 29)
              else
                SkinoImageIcon(
                  asset: assetIcon!,
                  size: 32,
                  padding: 3,
                  backgroundColor: accent.withValues(alpha: 0.1),
                  borderRadius: 12,
                ),
              const SizedBox(height: 8),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFF282420),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HomeActionDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(width: 1, height: 42, color: const Color(0xFFEDE7E1));
  }
}

class _PromoCard extends StatelessWidget {
  const _PromoCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.backgroundColor,
    required this.backgroundImage,
    this.assetIcon,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color backgroundColor;
  final String backgroundImage;
  final String? assetIcon;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 10),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
              backgroundImage,
              fit: BoxFit.cover,
              alignment: Alignment.centerRight,
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    Colors.black.withValues(alpha: 0.72),
                    backgroundColor.withValues(alpha: 0.42),
                    Colors.black.withValues(alpha: 0.08),
                  ],
                  stops: const [0, 0.56, 1],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(18),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: Colors.white.withValues(alpha: 0.2),
                    child: assetIcon == null
                        ? Icon(icon, color: Colors.white)
                        : SkinoImageIcon(
                            asset: assetIcon!,
                            size: 30,
                            padding: 2,
                            backgroundColor: Colors.white,
                            borderRadius: 12,
                          ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 230),
                          child: Text(
                            title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                              fontSize: 19,
                              height: 1.1,
                            ),
                          ),
                        ),
                        const SizedBox(height: 7),
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 250),
                          child: Text(
                            subtitle,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Color(0xFFF8F5EF),
                              fontWeight: FontWeight.w600,
                              height: 1.3,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ScanPage extends StatelessWidget {
  const _ScanPage({
    required this.text,
    required this.image,
    required this.result,
    required this.latestScan,
    required this.isLoading,
    required this.error,
    required this.appointmentRequestMessage,
    required this.showLiveScan,
    required this.onOpenLiveScan,
    required this.onCapture,
    required this.onAnalyze,
    required this.onClearScanResult,
    required this.onRequestAppointment,
    required this.onStartRoutine,
    required this.onOpenCare,
    required this.activeRoutine,
    required this.routineIsActive,
    required this.isGuest,
    required this.session,
    required this.allowModelTraining,
    required this.onAllowModelTrainingChanged,
    required this.onOpenScanHistory,
  });

  final SkinoText text;
  final File? image;
  final SkinAnalysisResult? result;
  final SkinAnalysisResult? latestScan;
  final bool isLoading;
  final String? error;
  final String? appointmentRequestMessage;
  final bool showLiveScan;
  final VoidCallback onOpenLiveScan;
  final ValueChanged<File> onCapture;
  final VoidCallback? onAnalyze;
  final VoidCallback onClearScanResult;
  final Future<void> Function(AppointmentRequestDraft draft)
  onRequestAppointment;
  final Future<void> Function(SkinAnalysisResult result) onStartRoutine;
  final VoidCallback onOpenCare;
  final ActiveRoutine? activeRoutine;
  final bool routineIsActive;
  final bool isGuest;
  final AuthSession? session;
  final bool allowModelTraining;
  final ValueChanged<bool> onAllowModelTrainingChanged;
  final VoidCallback onOpenScanHistory;

  @override
  Widget build(BuildContext context) {
    return _PageScaffold(
      children: [
        _PageTitle(
          title: text.skinScanTitle,
          subtitle: result == null
              ? text.scanEmptySubtitle
              : text.scanReadySubtitle,
        ),
        const SizedBox(height: 14),
        if (result == null && !showLiveScan)
          _ScanStartPanel(
            text: text,
            activeRoutine: activeRoutine,
            latestScan: latestScan,
            onOpenLiveScan: onOpenLiveScan,
            onOpenCare: onOpenCare,
            onOpenScanHistory: onOpenScanHistory,
            onOpenLatestScan: latestScan == null
                ? null
                : () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => _ResultPage(
                        text: text,
                        result: latestScan!,
                        isGuest: isGuest,
                        session: session,
                        isLoading: isLoading,
                        appointmentRequestMessage: appointmentRequestMessage,
                        onRequestAppointment: onRequestAppointment,
                        onStartRoutine: onStartRoutine,
                        onOpenCare: onOpenCare,
                        activeRoutine: activeRoutine,
                        routineIsActive:
                            activeRoutine?.skinAnalysisId == latestScan!.id,
                        onNewScan: onClearScanResult,
                      ),
                    ),
                  ),
          )
        else if (result == null)
          ImageCapturePanel(
            image: image,
            isLoading: isLoading,
            error: error,
            onCapture: onCapture,
            onResetScanFrame: onClearScanResult,
            onAnalyze: onAnalyze,
            canShareForTraining: !isGuest,
            allowModelTraining: allowModelTraining,
            onAllowModelTrainingChanged: onAllowModelTrainingChanged,
          )
        else if (showLiveScan)
          _ScanCompleteCard(
            text: text,
            result: result!,
            activeRoutine: activeRoutine,
            isGuest: isGuest,
            onViewResult: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => _ResultPage(
                  text: text,
                  result: result!,
                  isGuest: isGuest,
                  session: session,
                  isLoading: isLoading,
                  appointmentRequestMessage: appointmentRequestMessage,
                  onRequestAppointment: onRequestAppointment,
                  onStartRoutine: onStartRoutine,
                  onOpenCare: onOpenCare,
                  activeRoutine: activeRoutine,
                  routineIsActive: routineIsActive,
                  onNewScan: onClearScanResult,
                ),
              ),
            ),
            onNewScan: onClearScanResult,
            onOpenCare: onOpenCare,
          )
        else
          _ScanStartPanel(
            text: text,
            activeRoutine: activeRoutine,
            latestScan: latestScan,
            onOpenLiveScan: onOpenLiveScan,
            onOpenCare: onOpenCare,
            onOpenScanHistory: onOpenScanHistory,
            onOpenLatestScan: latestScan == null
                ? null
                : () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => _ResultPage(
                        text: text,
                        result: latestScan!,
                        isGuest: isGuest,
                        session: session,
                        isLoading: isLoading,
                        appointmentRequestMessage: appointmentRequestMessage,
                        onRequestAppointment: onRequestAppointment,
                        onStartRoutine: onStartRoutine,
                        onOpenCare: onOpenCare,
                        activeRoutine: activeRoutine,
                        routineIsActive:
                            activeRoutine?.skinAnalysisId == latestScan!.id,
                        onNewScan: onClearScanResult,
                      ),
                    ),
                  ),
          ),
      ],
    );
  }
}

class _ScanStartPanel extends StatelessWidget {
  const _ScanStartPanel({
    required this.text,
    required this.activeRoutine,
    required this.latestScan,
    required this.onOpenLiveScan,
    required this.onOpenCare,
    required this.onOpenScanHistory,
    required this.onOpenLatestScan,
  });

  final SkinoText text;
  final ActiveRoutine? activeRoutine;
  final SkinAnalysisResult? latestScan;
  final VoidCallback onOpenLiveScan;
  final VoidCallback onOpenCare;
  final VoidCallback onOpenScanHistory;
  final VoidCallback? onOpenLatestScan;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.96),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFFFFE3D1)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x14123C36),
                blurRadius: 20,
                offset: Offset(0, 12),
              ),
            ],
          ),
          child: Column(
            children: [
              if (latestScan != null) ...[
                _ScanContextStrip(
                  text: text,
                  latestScan: latestScan!,
                  activeRoutine: activeRoutine,
                  onOpenCare: onOpenCare,
                  onOpenLatestScan: onOpenLatestScan,
                ),
                const SizedBox(height: 12),
              ],
              _ScanActionTile(
                icon: Icons.center_focus_strong_rounded,
                assetIcon: SkinoAssets.iconScan,
                title: text.startLiveScan,
                subtitle: text.startLiveScanSubtitle,
                accent: const Color(0xFFF98128),
                onTap: onOpenLiveScan,
              ),
              const SizedBox(height: 12),
              _ScanActionTile(
                icon: Icons.manage_search_rounded,
                assetIcon: SkinoAssets.iconHistory,
                title: text.viewScanHistory,
                subtitle: text.viewScanHistorySubtitle,
                accent: const Color(0xFF7A8F72),
                onTap: onOpenScanHistory,
              ),
              const SizedBox(height: 12),
              _ScanActionTile(
                icon: Icons.trending_up_rounded,
                assetIcon: SkinoAssets.iconProgress,
                title: text.trackProgress,
                subtitle: activeRoutine == null
                    ? text.trackProgressSubtitle
                    : (text.isMyanmar
                          ? 'Active routine progress ကို Care page မှာ ဆက်ကြည့်ပါ။'
                          : 'Continue your active routine progress in Care.'),
                accent: const Color(0xFF7A8F72),
                onTap: activeRoutine == null ? null : onOpenCare,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ScanActionTile extends StatelessWidget {
  const _ScanActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.accent,
    this.assetIcon,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color accent;
  final String? assetIcon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Ink(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: accent.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: accent.withValues(alpha: 0.16)),
        ),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: accent,
              child: assetIcon == null
                  ? Icon(icon, color: Colors.white)
                  : SkinoImageIcon(
                      asset: assetIcon!,
                      size: 34,
                      padding: 2,
                      backgroundColor: Colors.white,
                      borderRadius: 14,
                    ),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Color(0xFF282420),
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: Color(0xFF625B53),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              onTap == null
                  ? Icons.lock_clock_outlined
                  : Icons.chevron_right_rounded,
              color: accent,
            ),
          ],
        ),
      ),
    );
  }
}

class _ScanContextStrip extends StatelessWidget {
  const _ScanContextStrip({
    required this.text,
    required this.latestScan,
    required this.activeRoutine,
    required this.onOpenCare,
    required this.onOpenLatestScan,
  });

  final SkinoText text;
  final SkinAnalysisResult latestScan;
  final ActiveRoutine? activeRoutine;
  final VoidCallback onOpenCare;
  final VoidCallback? onOpenLatestScan;

  @override
  Widget build(BuildContext context) {
    final routine = activeRoutine;
    final followUpText = routine == null
        ? (text.isMyanmar ? 'Routine မစသေးပါ' : 'No active routine')
        : _followUpDueLabel(routine);

    final scanLabel = latestScan.id == null
        ? (text.isMyanmar ? 'ယခင် guest scan' : 'Previous guest scan')
        : (text.isMyanmar
              ? 'ယခင် Scan #${latestScan.id}'
              : 'Previous Scan #${latestScan.id}');

    return InkWell(
      onTap: onOpenLatestScan,
      borderRadius: BorderRadius.circular(20),
      child: Ink(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF7F1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFFFD0B3)),
        ),
        child: Row(
          children: [
            _ScoreBubble(score: latestScan.skinHealthScore),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    scanLabel,
                    style: const TextStyle(
                      color: Color(0xFF282420),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    text.isMyanmar
                        ? '${latestScan.skinType} • score ${latestScan.skinHealthScore} • $followUpText'
                        : '${latestScan.skinType} • score ${latestScan.skinHealthScore} • $followUpText',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF68625B),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _StatusPill(
                  label: text.isMyanmar ? 'Result' : 'Result',
                  color: const Color(0xFFF98128),
                ),
                if (routine != null) ...[
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: onOpenCare,
                    child: Text(
                      text.isMyanmar ? 'Care' : 'Care',
                      style: const TextStyle(
                        color: Color(0xFF0E5C56),
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            const Icon(Icons.chevron_right_rounded, color: Color(0xFFF98128)),
          ],
        ),
      ),
    );
  }
}

class _ScanCompleteCard extends StatelessWidget {
  const _ScanCompleteCard({
    required this.text,
    required this.result,
    required this.activeRoutine,
    required this.isGuest,
    required this.onViewResult,
    required this.onNewScan,
    required this.onOpenCare,
  });

  final SkinoText text;
  final SkinAnalysisResult result;
  final ActiveRoutine? activeRoutine;
  final bool isGuest;
  final VoidCallback onViewResult;
  final VoidCallback onNewScan;
  final VoidCallback onOpenCare;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFFFE3D1)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14123C36),
            blurRadius: 20,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const SkinoImageIcon.page(
                asset: SkinoAssets.resultMascot,
                size: 54,
                backgroundColor: Color(0xFFEAF6F1),
                borderRadius: 18,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      text.scanCompleteTitle,
                      style: const TextStyle(
                        color: Color(0xFF282420),
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      text.scanCompleteSubtitle(result.skinHealthScore),
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
          const SizedBox(height: 16),
          _CompactResultSummary(text: text, result: result),
          const SizedBox(height: 12),
          _ResultNextStepStrip(
            text: text,
            result: result,
            activeRoutine: activeRoutine,
            isGuest: isGuest,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: onViewResult,
                  icon: const SkinoImageIcon(
                    asset: SkinoAssets.iconReport,
                    size: 22,
                    padding: 1,
                    backgroundColor: Colors.transparent,
                    borderRadius: 8,
                  ),
                  label: Text(text.viewResult),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFFF98128),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton.tonalIcon(
                  onPressed: onNewScan,
                  icon: const Icon(Icons.refresh_rounded),
                  label: Text(text.newScan),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFFEAF6F1),
                    foregroundColor: const Color(0xFF123C36),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ResultNextStepStrip extends StatelessWidget {
  const _ResultNextStepStrip({
    required this.text,
    required this.result,
    required this.activeRoutine,
    required this.isGuest,
  });

  final SkinoText text;
  final SkinAnalysisResult result;
  final ActiveRoutine? activeRoutine;
  final bool isGuest;

  @override
  Widget build(BuildContext context) {
    final needsRetake = result.scanQuality?.needsRetake ?? false;
    final routineReady = result.treatmentPackage != null && !isGuest;
    final label = needsRetake
        ? (text.isMyanmar ? 'ပြန်စကင်ရန် အကြံပြု' : 'Retake recommended')
        : routineReady
        ? (activeRoutine == null
              ? (text.isMyanmar ? 'Routine စတင်နိုင်ပါပြီ' : 'Routine ready')
              : (text.isMyanmar ? 'Progress ဆက်ကြည့်ပါ' : 'Progress ready'))
        : (text.isMyanmar ? 'Result သိမ်းရန် Login ဝင်ပါ' : 'Login to save');
    final asset = needsRetake
        ? SkinoAssets.iconScan
        : routineReady
        ? SkinoAssets.iconProgress
        : SkinoAssets.iconReport;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: needsRetake ? const Color(0xFFFFF3EC) : const Color(0xFFEAF6F1),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: needsRetake
              ? const Color(0xFFFFD0B3)
              : const Color(0xFFBFE6D7),
        ),
      ),
      child: Row(
        children: [
          SkinoImageIcon.inline(
            asset: asset,
            size: 28,
            backgroundColor: Colors.white,
            borderRadius: 10,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: Color(0xFF123C36),
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CompactResultSummary extends StatelessWidget {
  const _CompactResultSummary({required this.text, required this.result});

  final SkinoText text;
  final SkinAnalysisResult result;

  @override
  Widget build(BuildContext context) {
    final topConcern = result.concerns.isEmpty
        ? text.noStrongConcern
        : text.concernLabel(result.concerns.first.name);
    final quality = result.scanQuality;
    final qualityLabel = quality?.needsRetake == true
        ? (text.isMyanmar ? 'အလင်းပြန်စစ်ရန်' : 'Retake lighting')
        : (text.isMyanmar ? 'အလင်း OK' : 'Lighting OK');

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3EC),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFFFD0B3)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              _ScoreBubble(score: result.skinHealthScore),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      text.concernLabel(result.skinType),
                      style: const TextStyle(
                        color: Color(0xFF282420),
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      text.isMyanmar
                          ? 'အဓိက focus: $topConcern'
                          : 'Main focus: $topConcern',
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
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _DarkInfoChip(
                icon: Icons.spa_outlined,
                assetIcon: SkinoAssets.iconRoutine,
                label: result.treatmentPackage?.name ?? text.calmRoutine,
              ),
              _DarkInfoChip(
                icon: Icons.light_mode_outlined,
                label: qualityLabel,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DarkInfoChip extends StatelessWidget {
  const _DarkInfoChip({
    required this.icon,
    required this.label,
    this.assetIcon,
  });

  final IconData icon;
  final String label;
  final String? assetIcon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: const Color(0xFFFFD0B3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (assetIcon == null)
            Icon(icon, size: 16, color: const Color(0xFFF98128))
          else
            SkinoImageIcon(
              asset: assetIcon!,
              size: 18,
              padding: 1,
              backgroundColor: Colors.transparent,
              borderRadius: 7,
            ),
          const SizedBox(width: 6),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 180),
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFF282420),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ResultPage extends StatelessWidget {
  const _ResultPage({
    required this.text,
    required this.result,
    required this.isGuest,
    required this.session,
    required this.isLoading,
    required this.appointmentRequestMessage,
    required this.onRequestAppointment,
    required this.onStartRoutine,
    required this.onOpenCare,
    required this.activeRoutine,
    required this.routineIsActive,
    required this.onNewScan,
  });

  final SkinoText text;
  final SkinAnalysisResult result;
  final bool isGuest;
  final AuthSession? session;
  final bool isLoading;
  final String? appointmentRequestMessage;
  final Future<void> Function(AppointmentRequestDraft draft)
  onRequestAppointment;
  final Future<void> Function(SkinAnalysisResult result) onStartRoutine;
  final VoidCallback onOpenCare;
  final ActiveRoutine? activeRoutine;
  final bool routineIsActive;
  final VoidCallback onNewScan;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFBF9F4),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFBF9F4),
        foregroundColor: const Color(0xFF282420),
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        toolbarHeight: 68,
        title: Text(
          text.scanResultTitle,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        actions: [
          TextButton.icon(
            onPressed: () {
              onNewScan();
              Navigator.of(context).pop();
            },
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: Text(text.newScan),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _PageScaffold(
        children: [
          AnalysisResultPanel(result: result, text: text),
          const SizedBox(height: 12),
          _SkinMapEntryCard(text: text, result: result),
          const SizedBox(height: 12),
          _StartRoutineCard(
            text: text,
            result: result,
            activeRoutine: activeRoutine,
            isGuest: isGuest,
            isActive: routineIsActive,
            onStartRoutine: onStartRoutine,
            onOpenCare: onOpenCare,
          ),
          const SizedBox(height: 12),
          _ScanQualityCard(text: text, result: result),
          if (activeRoutine != null &&
              activeRoutine!.skinAnalysisId != result.id) ...[
            const SizedBox(height: 12),
            _ResultChangeExplanationCard(
              text: text,
              before: activeRoutine!.skinAnalysis,
              after: result,
            ),
          ],
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => _AppointmentPage(
                    text: text,
                    result: result,
                    isGuest: isGuest,
                    session: session,
                    isLoading: isLoading,
                    message: appointmentRequestMessage,
                    selectedSpecialist: null,
                    activeRoutine: activeRoutine,
                    onSubmit: onRequestAppointment,
                  ),
                ),
              ),
              icon: const Icon(Icons.calendar_month_rounded),
              label: Text(text.requestAppointment),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFFF98128),
                side: const BorderSide(color: Color(0xFFFFB783)),
                padding: const EdgeInsets.symmetric(vertical: 13),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ScanQualityCard extends StatelessWidget {
  const _ScanQualityCard({required this.text, required this.result});

  final SkinoText text;
  final SkinAnalysisResult result;

  @override
  Widget build(BuildContext context) {
    final quality = result.scanQuality;
    final needsRetake = quality?.needsRetake ?? result.skinTypeConfidence < 0.6;
    final title = needsRetake
        ? (text.isMyanmar ? 'ပြန်စကင်ရန် အကြံပြုသည်' : 'Retake recommended')
        : (text.isMyanmar ? 'Scan quality ကောင်းသည်' : 'Good scan quality');
    final subtitle = needsRetake
        ? (quality?.message.isNotEmpty == true
              ? quality!.message
              : (text.isMyanmar
                    ? 'အလင်း၊ မျက်နှာအနေအထား သို့မဟုတ် frame မကောင်းလျှင် result မတည်ငြိမ်နိုင်ပါ။ ပြန်စကင်ပါ။'
                    : 'Lighting, face angle, or framing can make the result unstable. Retake before trusting this scan.'))
        : (text.isMyanmar
              ? 'ဒီ result ကို routine guidance အတွက် အသုံးပြုနိုင်ပါတယ်။'
              : 'This result is clear enough for routine guidance.');
    final color = needsRetake
        ? const Color(0xFFF98128)
        : const Color(0xFF0E5C56);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: needsRetake ? const Color(0xFFFFF3EC) : const Color(0xFFEAF6F1),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withValues(alpha: 0.22)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: color.withValues(alpha: 0.14),
            child: Icon(
              needsRetake ? Icons.light_mode_outlined : Icons.check_rounded,
              color: color,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xFF282420),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: Color(0xFF68625B),
                    fontWeight: FontWeight.w500,
                    height: 1.35,
                  ),
                ),
                if (quality != null) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _SmallInfoChip(
                        label: 'Light ${(quality.brightness * 100).round()}%',
                      ),
                      _SmallInfoChip(
                        label: 'Face ${(quality.skinCoverage * 100).round()}%',
                      ),
                      _SmallInfoChip(
                        label:
                            'Center ${(quality.faceCentering * 100).round()}%',
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ResultChangeExplanationCard extends StatelessWidget {
  const _ResultChangeExplanationCard({
    required this.text,
    required this.before,
    required this.after,
  });

  final SkinoText text;
  final SkinAnalysisResult before;
  final SkinAnalysisResult after;

  @override
  Widget build(BuildContext context) {
    final scoreDelta = after.skinHealthScore - before.skinHealthScore;
    final beforeQuality = before.scanQuality;
    final afterQuality = after.scanQuality;
    final beforeLight = beforeQuality == null
        ? null
        : (beforeQuality.brightness * 100).round();
    final afterLight = afterQuality == null
        ? null
        : (afterQuality.brightness * 100).round();
    final confidenceDelta =
        ((after.skinTypeConfidence - before.skinTypeConfidence) * 100).round();

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7F1),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFFFD0B3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.lightbulb_outline_rounded,
                color: Color(0xFFF98128),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  text.isMyanmar
                      ? 'Result ဘာကြောင့်ပြောင်းနိုင်လဲ?'
                      : 'Why this result may have changed',
                  style: const TextStyle(
                    color: Color(0xFF282420),
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            text.isMyanmar
                ? 'Score ${scoreDelta >= 0 ? '+' : ''}$scoreDelta။ အလင်း၊ မျက်နှာထောင့်၊ camera အကွာအဝေးနဲ့ face coverage က oil, spots, texture signal တွေကို ပြောင်းနိုင်ပါတယ်။'
                : 'Score ${scoreDelta >= 0 ? '+' : ''}$scoreDelta. Lighting, face angle, camera distance, and skin coverage can shift visible oil, spots, and texture signals between scans.',
            style: const TextStyle(
              color: Color(0xFF625B53),
              fontWeight: FontWeight.w600,
              height: 1.38,
            ),
          ),
          const SizedBox(height: 10),
          if (beforeQuality != null && afterQuality != null) ...[
            _QualityShiftBars(before: before, after: after),
            const SizedBox(height: 10),
          ],
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (beforeLight != null && afterLight != null)
                _SmallInfoChip(label: 'Light $beforeLight% -> $afterLight%'),
              _SmallInfoChip(
                label:
                    'Confidence ${confidenceDelta >= 0 ? '+' : ''}$confidenceDelta%',
              ),
              if (afterQuality?.needsRetake == true)
                const _SmallInfoChip(label: 'Retake recommended'),
              const _SmallInfoChip(label: 'Use same place/light for follow-up'),
            ],
          ),
        ],
      ),
    );
  }
}

class _QualityShiftBars extends StatelessWidget {
  const _QualityShiftBars({required this.before, required this.after});

  final SkinAnalysisResult before;
  final SkinAnalysisResult after;

  @override
  Widget build(BuildContext context) {
    final beforeQuality = before.scanQuality!;
    final afterQuality = after.scanQuality!;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.82),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFFE3D1)),
      ),
      child: Column(
        children: [
          _QualityShiftRow(
            label: 'Light',
            before: beforeQuality.brightness,
            after: afterQuality.brightness,
          ),
          const SizedBox(height: 9),
          _QualityShiftRow(
            label: 'Face',
            before: beforeQuality.skinCoverage,
            after: afterQuality.skinCoverage,
          ),
          const SizedBox(height: 9),
          _QualityShiftRow(
            label: 'Center',
            before: beforeQuality.faceCentering,
            after: afterQuality.faceCentering,
          ),
        ],
      ),
    );
  }
}

class _QualityShiftRow extends StatelessWidget {
  const _QualityShiftRow({
    required this.label,
    required this.before,
    required this.after,
  });

  final String label;
  final double before;
  final double after;

  @override
  Widget build(BuildContext context) {
    final delta = ((after - before) * 100).round();

    return Row(
      children: [
        SizedBox(
          width: 52,
          child: Text(
            label,
            style: const TextStyle(
              color: Color(0xFF68625B),
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: after.clamp(0, 1),
              minHeight: 9,
              backgroundColor: const Color(0xFFF1ECE5),
              color: const Color(0xFFF98128),
            ),
          ),
        ),
        const SizedBox(width: 9),
        SizedBox(
          width: 42,
          child: Text(
            '${delta >= 0 ? '+' : ''}$delta%',
            textAlign: TextAlign.end,
            style: TextStyle(
              color: delta >= 0
                  ? const Color(0xFF0E5C56)
                  : const Color(0xFF9E2732),
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ],
    );
  }
}

class _SkinMapEntryCard extends StatelessWidget {
  const _SkinMapEntryCard({required this.text, required this.result});

  final SkinoText text;
  final SkinAnalysisResult result;

  @override
  Widget build(BuildContext context) {
    final areas = _skinMapAreas(result).toList()
      ..sort((left, right) => left.score.compareTo(right.score));
    final priorityAreas = areas.take(3).toList();

    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFFFE3D1)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF123C36).withValues(alpha: 0.04),
            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              const CircleAvatar(
                backgroundColor: Color(0xFFFFF3EC),
                child: SkinoImageIcon(
                  asset: SkinoAssets.iconReport,
                  size: 34,
                  padding: 2,
                  backgroundColor: Colors.transparent,
                  borderRadius: 12,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      text.isMyanmar ? 'မျက်နှာ skin map' : 'Face skin map',
                      style: const TextStyle(
                        color: Color(0xFF282420),
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      text.isMyanmar
                          ? 'ဘယ်နေရာမှာ ဘာ concern ပိုမြင်ရလဲ အမြန်ကြည့်ပါ။'
                          : 'See which face areas need the most attention.',
                      style: const TextStyle(
                        color: Color(0xFF68625B),
                        fontWeight: FontWeight.w500,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              TextButton.icon(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => _SkinMapPage(text: text, result: result),
                  ),
                ),
                icon: const Icon(Icons.chevron_right_rounded),
                label: Text(text.isMyanmar ? 'အသေးစိတ်' : 'Details'),
              ),
            ],
          ),
          if (priorityAreas.isNotEmpty) ...[
            const SizedBox(height: 12),
            for (final area in priorityAreas) ...[
              _SkinMapMiniRow(text: text, area: area),
              if (area != priorityAreas.last)
                const Divider(height: 13, color: Color(0xFFFFE3D1)),
            ],
          ],
        ],
      ),
    );
  }
}

class _SkinMapMiniRow extends StatelessWidget {
  const _SkinMapMiniRow({required this.text, required this.area});

  final SkinoText text;
  final _SkinMapArea area;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: area.color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Text(
            '${area.score}',
            style: TextStyle(
              color: area.color,
              fontSize: 13,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _skinMapAreaName(text, area.name),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFF282420),
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                _skinMapAreaDetail(text, area),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFF68625B),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          width: 70,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: area.value.clamp(0, 1),
              minHeight: 7,
              backgroundColor: const Color(0xFFF1ECE5),
              color: area.color,
            ),
          ),
        ),
      ],
    );
  }
}

class _SkinMapPage extends StatelessWidget {
  const _SkinMapPage({required this.text, required this.result});

  final SkinoText text;
  final SkinAnalysisResult result;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFBF9F4),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFBF9F4),
        foregroundColor: const Color(0xFF282420),
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        title: Text(text.isMyanmar ? 'Skin map details' : 'Skin map details'),
      ),
      body: _PageScaffold(
        children: [
          _SkinWellbeingMapCard(text: text, result: result),
          const SizedBox(height: 12),
          _ScanQualityCard(text: text, result: result),
        ],
      ),
    );
  }
}

class _SkinWellbeingMapCard extends StatelessWidget {
  const _SkinWellbeingMapCard({required this.text, required this.result});

  final SkinoText text;
  final SkinAnalysisResult result;

  @override
  Widget build(BuildContext context) {
    final areas = _skinMapAreas(result);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFFFE3D1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const CircleAvatar(
                backgroundColor: Color(0xFFEAF6F1),
                child: SkinoImageIcon(
                  asset: SkinoAssets.iconReport,
                  size: 34,
                  padding: 2,
                  backgroundColor: Colors.transparent,
                  borderRadius: 12,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      text.isMyanmar ? 'Skin map အသေးစိတ်' : 'Skin map details',
                      style: const TextStyle(
                        color: Color(0xFF282420),
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      text.isMyanmar
                          ? 'ဒီစကင်မှ မျက်နှာ zone အလိုက် health နှင့် beauty အချက်အလက်'
                          : 'Health and beauty zones from this scan',
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
          const SizedBox(height: 14),
          _SkinMapFacePreview(text: text, result: result, areas: areas),
          const SizedBox(height: 14),
          for (final area in areas) ...[
            _SkinMapAreaRow(
              text: text,
              area: area,
              onTap: () => _showZoneDetailSheet(context, text, area),
            ),
            const SizedBox(height: 10),
          ],
          const SizedBox(height: 2),
          Text(
            text.isMyanmar
                ? 'Zone အသေးစိတ်များသည် AI မြင်နိုင်သော signal များအပေါ်အခြေခံပြီး routine ရွေးချယ်ရာတွင် ကူညီရန်ဖြစ်သည်။'
                : 'Zone details are based on visible AI scan signals and help guide routine choices.',
            style: const TextStyle(
              color: Color(0xFF68625B),
              fontSize: 12,
              fontWeight: FontWeight.w500,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}

class _SkinMapFacePreview extends StatelessWidget {
  const _SkinMapFacePreview({
    required this.text,
    required this.result,
    required this.areas,
  });

  final SkinoText text;
  final SkinAnalysisResult result;
  final List<_SkinMapArea> areas;

  @override
  Widget build(BuildContext context) {
    final hasAcne = areas.any((area) => area.acneSignal >= 0.45);
    final hasSpots = areas.any((area) => area.darkSpotSignal >= 0.45);
    final hasOil = areas.any((area) => area.oilSignal >= 0.45);

    return Container(
      height: 230,
      decoration: BoxDecoration(
        color: const Color(0xFF102421),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 5,
            child: CustomPaint(
              painter: _FaceZonePainter(
                hasAcne: hasAcne,
                hasSpots: hasSpots,
                hasOil: hasOil,
              ),
              child: const SizedBox.expand(),
            ),
          ),
          Expanded(
            flex: 4,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(4, 18, 16, 18),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _MapLegendItem(
                    label: _zoneSignalLabel(text, 'oil'),
                    active: hasOil,
                    color: const Color(0xFFF98128),
                  ),
                  const SizedBox(height: 12),
                  _MapLegendItem(
                    label: _zoneSignalLabel(text, 'spots'),
                    active: hasSpots,
                    color: const Color(0xFF8E6DEB),
                  ),
                  const SizedBox(height: 12),
                  _MapLegendItem(
                    label: _zoneSignalLabel(text, 'acne'),
                    active: hasAcne,
                    color: const Color(0xFFE95D48),
                  ),
                  const SizedBox(height: 12),
                  _MapLegendItem(
                    label: text.isMyanmar ? 'routine နေရာ' : 'Routine zone',
                    active: true,
                    color: const Color(0xFF7EF1CF),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MapLegendItem extends StatelessWidget {
  const _MapLegendItem({
    required this.label,
    required this.active,
    required this.color,
  });

  final String label;
  final bool active;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 9,
          height: 9,
          decoration: BoxDecoration(
            color: active ? color : Colors.white.withValues(alpha: 0.22),
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: active
                  ? Colors.white
                  : Colors.white.withValues(alpha: 0.52),
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

class _FaceZonePainter extends CustomPainter {
  const _FaceZonePainter({
    required this.hasAcne,
    required this.hasSpots,
    required this.hasOil,
  });

  final bool hasAcne;
  final bool hasSpots;
  final bool hasOil;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width * 0.5, size.height * 0.5);
    final outlinePaint = Paint()
      ..color = const Color(0xFF7EF1CF).withValues(alpha: 0.72)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4;
    final softPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.08)
      ..style = PaintingStyle.fill;

    final faceRect = Rect.fromCenter(
      center: center,
      width: size.width * 0.54,
      height: size.height * 0.74,
    );
    canvas.drawOval(faceRect, softPaint);
    canvas.drawOval(faceRect, outlinePaint);

    _drawZone(
      canvas,
      Rect.fromCenter(
        center: Offset(center.dx, size.height * 0.28),
        width: size.width * 0.42,
        height: size.height * 0.13,
      ),
      hasOil ? const Color(0xFFF98128) : const Color(0xFF7EF1CF),
      'F',
    );
    _drawZone(
      canvas,
      Rect.fromCenter(
        center: Offset(size.width * 0.36, size.height * 0.48),
        width: size.width * 0.22,
        height: size.height * 0.16,
      ),
      hasSpots ? const Color(0xFF8E6DEB) : const Color(0xFF7EF1CF),
      'L',
    );
    _drawZone(
      canvas,
      Rect.fromCenter(
        center: Offset(size.width * 0.64, size.height * 0.48),
        width: size.width * 0.22,
        height: size.height * 0.16,
      ),
      hasSpots ? const Color(0xFF8E6DEB) : const Color(0xFF7EF1CF),
      'R',
    );
    _drawZone(
      canvas,
      Rect.fromCenter(
        center: Offset(center.dx, size.height * 0.50),
        width: size.width * 0.12,
        height: size.height * 0.24,
      ),
      hasOil ? const Color(0xFFF98128) : const Color(0xFF7EF1CF),
      'N',
    );
    _drawZone(
      canvas,
      Rect.fromCenter(
        center: Offset(center.dx, size.height * 0.70),
        width: size.width * 0.28,
        height: size.height * 0.12,
      ),
      hasAcne ? const Color(0xFFE95D48) : const Color(0xFF7EF1CF),
      'C',
    );

    final eyePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.54)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(size.width * 0.34, size.height * 0.38),
      Offset(size.width * 0.43, size.height * 0.38),
      eyePaint,
    );
    canvas.drawLine(
      Offset(size.width * 0.57, size.height * 0.38),
      Offset(size.width * 0.66, size.height * 0.38),
      eyePaint,
    );
  }

  void _drawZone(Canvas canvas, Rect rect, Color color, String label) {
    final fill = Paint()
      ..color = color.withValues(alpha: 0.22)
      ..style = PaintingStyle.fill;
    final border = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6;

    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(22)),
      fill,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(22)),
      border,
    );

    final textPainter = TextPainter(
      text: TextSpan(
        text: label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    textPainter.paint(
      canvas,
      Offset(
        rect.center.dx - textPainter.width / 2,
        rect.center.dy - textPainter.height / 2,
      ),
    );
  }

  @override
  bool shouldRepaint(covariant _FaceZonePainter oldDelegate) {
    return oldDelegate.hasAcne != hasAcne ||
        oldDelegate.hasSpots != hasSpots ||
        oldDelegate.hasOil != hasOil;
  }
}

class _SkinMapArea {
  const _SkinMapArea({
    required this.name,
    required this.detail,
    required this.value,
    required this.color,
    required this.score,
    required this.concerns,
    required this.oilSignal,
    required this.darkSpotSignal,
    required this.acneSignal,
    required this.textureSignal,
    required this.drynessSignal,
  });

  final String name;
  final String detail;
  final double value;
  final Color color;
  final int score;
  final List<SkinConcern> concerns;
  final double oilSignal;
  final double darkSpotSignal;
  final double acneSignal;
  final double textureSignal;
  final double drynessSignal;
}

class _SkinMapAreaRow extends StatelessWidget {
  const _SkinMapAreaRow({
    required this.text,
    required this.area,
    required this.onTap,
  });

  final SkinoText text;
  final _SkinMapArea area;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Ink(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: const Color(0xFFFFFCF8),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFF1E4D7)),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 76,
              child: Text(
                _skinMapAreaName(text, area.name),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFF282420),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: LinearProgressIndicator(
                      value: area.value,
                      minHeight: 8,
                      backgroundColor: const Color(0xFFF1ECE5),
                      color: area.color,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _skinMapAreaDetail(text, area),
                    style: const TextStyle(
                      color: Color(0xFF68625B),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              children: [
                Text(
                  '${area.score}',
                  style: TextStyle(
                    color: area.color,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const Text(
                  'score',
                  style: TextStyle(
                    color: Color(0xFF68625B),
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(width: 6),
            const Icon(Icons.expand_more_rounded, color: Color(0xFFB8B0A7)),
          ],
        ),
      ),
    );
  }
}

void _showZoneDetailSheet(
  BuildContext context,
  SkinoText text,
  _SkinMapArea area,
) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => _ZoneDetailSheet(text: text, area: area),
  );
}

class _ZoneDetailSheet extends StatelessWidget {
  const _ZoneDetailSheet({required this.text, required this.area});

  final SkinoText text;
  final _SkinMapArea area;

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.72,
      minChildSize: 0.48,
      maxChildSize: 0.92,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Color(0xFFFBF9F4),
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: ListView(
            controller: scrollController,
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
            children: [
              Center(
                child: Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFD7CEC4),
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              _ZoneDetailHeader(text: text, area: area),
              const SizedBox(height: 14),
              _ZoneSignalsCard(text: text, area: area),
              const SizedBox(height: 14),
              _ZoneConcernCard(text: text, area: area),
              const SizedBox(height: 14),
              _ZoneRoutineAdviceCard(text: text, area: area),
            ],
          ),
        );
      },
    );
  }
}

class _ZoneDetailHeader extends StatelessWidget {
  const _ZoneDetailHeader({required this.text, required this.area});

  final SkinoText text;
  final _SkinMapArea area;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF123C36),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          Container(
            width: 72,
            height: 72,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: area.color.withValues(alpha: 0.18),
              shape: BoxShape.circle,
              border: Border.all(color: area.color, width: 2),
            ),
            child: Text(
              '${area.score}',
              style: TextStyle(
                color: area.color,
                fontSize: 24,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _skinMapAreaName(text, area.name),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  _skinMapAreaDetail(text, area),
                  style: const TextStyle(
                    color: Color(0xFFEAF6F1),
                    fontWeight: FontWeight.w500,
                    height: 1.35,
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

class _ZoneSignalsCard extends StatelessWidget {
  const _ZoneSignalsCard({required this.text, required this.area});

  final SkinoText text;
  final _SkinMapArea area;

  @override
  Widget build(BuildContext context) {
    final signals = [
      _ZoneSignal('oil', area.oilSignal, const Color(0xFFF98128)),
      _ZoneSignal('spots', area.darkSpotSignal, const Color(0xFF8E6DEB)),
      _ZoneSignal('acne', area.acneSignal, const Color(0xFFE95D48)),
      _ZoneSignal('texture', area.textureSignal, const Color(0xFF0E5C56)),
      _ZoneSignal('dryness', area.drynessSignal, const Color(0xFF7A8F72)),
    ];

    return _ZoneSheetCard(
      title: text.isMyanmar ? 'Zone signal များ' : 'Zone signals',
      icon: Icons.monitor_heart_outlined,
      child: Column(
        children: [
          for (final signal in signals) ...[
            _ZoneSignalRow(text: text, signal: signal),
            if (signal != signals.last) const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }
}

class _ZoneSignalRow extends StatelessWidget {
  const _ZoneSignalRow({required this.text, required this.signal});

  final SkinoText text;
  final _ZoneSignal signal;

  @override
  Widget build(BuildContext context) {
    final percent = (signal.value * 100).round();

    return Row(
      children: [
        SizedBox(
          width: 92,
          child: Text(
            _zoneSignalLabel(text, signal.name),
            style: const TextStyle(
              color: Color(0xFF282420),
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: signal.value.clamp(0, 1),
              minHeight: 9,
              backgroundColor: const Color(0xFFF1ECE5),
              color: signal.color,
            ),
          ),
        ),
        const SizedBox(width: 10),
        SizedBox(
          width: 38,
          child: Text(
            '$percent%',
            textAlign: TextAlign.end,
            style: TextStyle(color: signal.color, fontWeight: FontWeight.w800),
          ),
        ),
      ],
    );
  }
}

class _ZoneConcernCard extends StatelessWidget {
  const _ZoneConcernCard({required this.text, required this.area});

  final SkinoText text;
  final _SkinMapArea area;

  @override
  Widget build(BuildContext context) {
    return _ZoneSheetCard(
      title: text.isMyanmar ? 'မြင်ရသော concern' : 'Visible concerns',
      icon: Icons.fact_check_outlined,
      child: area.concerns.isEmpty
          ? Text(
              text.isMyanmar
                  ? 'ဒီနေရာမှာ အရေးကြီး concern မတွေ့ပါ။'
                  : 'No strong concern detected in this zone.',
              style: const TextStyle(
                color: Color(0xFF68625B),
                fontWeight: FontWeight.w500,
              ),
            )
          : Wrap(
              spacing: 8,
              runSpacing: 8,
              children: area.concerns
                  .map(
                    (concern) => _SmallInfoChip(
                      label:
                          '${text.concernLabel(concern.name)} ${(concern.confidence * 100).round()}% ${text.severityLabel(concern.severity)}',
                    ),
                  )
                  .toList(),
            ),
    );
  }
}

class _ZoneRoutineAdviceCard extends StatelessWidget {
  const _ZoneRoutineAdviceCard({required this.text, required this.area});

  final SkinoText text;
  final _SkinMapArea area;

  @override
  Widget build(BuildContext context) {
    return _ZoneSheetCard(
      title: text.isMyanmar ? 'Routine အကြံပြုချက်' : 'Routine advice',
      icon: Icons.spa_outlined,
      child: Text(
        _zoneRoutineAdvice(text, area),
        style: const TextStyle(
          color: Color(0xFF625B53),
          fontWeight: FontWeight.w500,
          height: 1.45,
        ),
      ),
    );
  }
}

class _ZoneSheetCard extends StatelessWidget {
  const _ZoneSheetCard({
    required this.title,
    required this.icon,
    required this.child,
  });

  final String title;
  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFFFE3D1)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF123C36).withValues(alpha: 0.035),
            blurRadius: 14,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: const Color(0xFFEAF6F1),
                child: Icon(icon, color: const Color(0xFF0E5C56)),
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: const TextStyle(
                  color: Color(0xFF282420),
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

List<_SkinMapArea> _skinMapAreas(SkinAnalysisResult result) {
  if (result.skinZones.isNotEmpty) {
    return result.skinZones.map(_skinMapAreaFromZone).toList(growable: false);
  }

  final concernNames = result.concerns.map((item) => item.name).toSet();
  final hasAcne =
      concernNames.contains('acne') || result.acneSeverity != 'none';
  final hasSpots = concernNames.contains('dark_spots');
  final hasOil = concernNames.contains('oiliness') || result.skinType == 'oily';
  final hasDry = concernNames.contains('dryness') || result.skinType == 'dry';

  return [
    _SkinMapArea(
      name: 'Forehead',
      detail: hasOil ? 'Oil balance focus' : 'Stable zone',
      value: hasOil ? 0.78 : 0.38,
      color: const Color(0xFFF98128),
      score: hasOil ? 72 : 88,
      concerns: const [],
      oilSignal: hasOil ? 0.78 : 0.18,
      darkSpotSignal: 0.12,
      acneSignal: 0.12,
      textureSignal: 0.24,
      drynessSignal: 0.18,
    ),
    _SkinMapArea(
      name: 'Cheeks',
      detail: hasSpots ? 'Dark spot watch' : 'Tone check',
      value: hasSpots ? 0.72 : 0.34,
      color: const Color(0xFF8E6DEB),
      score: hasSpots ? 74 : 88,
      concerns: const [],
      oilSignal: 0.18,
      darkSpotSignal: hasSpots ? 0.72 : 0.18,
      acneSignal: 0.18,
      textureSignal: 0.26,
      drynessSignal: 0.18,
    ),
    _SkinMapArea(
      name: 'Nose',
      detail: hasOil ? 'Pore and shine area' : 'Texture check',
      value: hasOil ? 0.82 : 0.42,
      color: const Color(0xFF0E5C56),
      score: hasOil ? 70 : 84,
      concerns: const [],
      oilSignal: hasOil ? 0.82 : 0.22,
      darkSpotSignal: 0.14,
      acneSignal: 0.16,
      textureSignal: hasOil ? 0.46 : 0.32,
      drynessSignal: 0.16,
    ),
    _SkinMapArea(
      name: 'Chin',
      detail: hasAcne
          ? 'Acne care focus'
          : hasDry
          ? 'Hydration focus'
          : 'Clear',
      value: hasAcne
          ? 0.76
          : hasDry
          ? 0.64
          : 0.28,
      color: hasAcne ? const Color(0xFFE95D48) : const Color(0xFF7A8F72),
      score: hasAcne
          ? 68
          : hasDry
          ? 76
          : 90,
      concerns: const [],
      oilSignal: 0.12,
      darkSpotSignal: 0.12,
      acneSignal: hasAcne ? 0.76 : 0.16,
      textureSignal: 0.28,
      drynessSignal: hasDry ? 0.64 : 0.18,
    ),
  ];
}

_SkinMapArea _skinMapAreaFromZone(SkinZone zone) {
  final strongestSignal = _strongestZoneSignal(zone);

  return _SkinMapArea(
    name: zone.label,
    detail: _zoneDetail(zone, strongestSignal.name),
    value: strongestSignal.value,
    color: strongestSignal.color,
    score: zone.score,
    concerns: zone.concerns,
    oilSignal: zone.oiliness,
    darkSpotSignal: zone.darkSpots,
    acneSignal: zone.redness,
    textureSignal: zone.texture,
    drynessSignal: zone.dryness,
  );
}

_ZoneSignal _strongestZoneSignal(SkinZone zone) {
  final signals = [
    _ZoneSignal('oil', zone.oiliness, const Color(0xFFF98128)),
    _ZoneSignal('spots', zone.darkSpots, const Color(0xFF8E6DEB)),
    _ZoneSignal('acne', zone.redness, const Color(0xFFE95D48)),
    _ZoneSignal('texture', zone.texture, const Color(0xFF0E5C56)),
    _ZoneSignal('dryness', zone.dryness, const Color(0xFF7A8F72)),
  ];

  return signals.reduce((best, item) => item.value > best.value ? item : best);
}

String _zoneDetail(SkinZone zone, String signalName) {
  if (zone.concerns.isNotEmpty) {
    final concern = zone.concerns.first;
    return '${_titleCase(concern.name)} ${(concern.confidence * 100).round()}% ${concern.severity}';
  }

  if (zone.score >= 82) {
    return 'Stable zone, score ${zone.score}';
  }

  return '$signalName focus, score ${zone.score}';
}

class _ZoneSignal {
  const _ZoneSignal(this.name, this.value, this.color);

  final String name;
  final double value;
  final Color color;
}

String _skinMapAreaName(SkinoText text, String name) {
  if (!text.isMyanmar) {
    return name;
  }

  final value = name.toLowerCase();
  if (value.contains('forehead')) {
    return 'နဖူး';
  }
  if (value.contains('left') && value.contains('cheek')) {
    return 'ဘယ်ပါး';
  }
  if (value.contains('right') && value.contains('cheek')) {
    return 'ညာပါး';
  }
  if (value.contains('cheek')) {
    return 'ပါး';
  }
  if (value.contains('nose')) {
    return 'နှာခေါင်း';
  }
  if (value.contains('chin')) {
    return 'မေးစေ့';
  }
  return name;
}

String _zoneSignalLabel(SkinoText text, String name) {
  final value = name.toLowerCase();
  if (!text.isMyanmar) {
    return switch (value) {
      'oil' => 'Oil balance',
      'spots' => 'Dark spots',
      'acne' => 'Acne/redness',
      'texture' => 'Texture',
      'dryness' => 'Dryness',
      _ => name,
    };
  }

  return switch (value) {
    'oil' => 'အဆီပြန်မှု',
    'spots' => 'အမည်းစက်',
    'acne' => 'ဝက်ခြံ/နီခြင်း',
    'texture' => 'အသားအရေ texture',
    'dryness' => 'ခြောက်သွေ့မှု',
    _ => name,
  };
}

String _skinMapAreaDetail(SkinoText text, _SkinMapArea area) {
  if (area.concerns.isNotEmpty) {
    final concern = area.concerns.first;
    return text.isMyanmar
        ? '${text.concernLabel(concern.name)} ${(concern.confidence * 100).round()}% • ${text.severityLabel(concern.severity)}'
        : '${text.concernLabel(concern.name)} ${(concern.confidence * 100).round()}% • ${text.severityLabel(concern.severity)}';
  }

  if (area.score >= 82) {
    return text.isMyanmar
        ? 'တည်ငြိမ်သော zone • score ${area.score}'
        : 'Stable zone • score ${area.score}';
  }

  final strongest = _strongestAreaSignal(area);
  return text.isMyanmar
      ? '${_zoneSignalLabel(text, strongest.name)} သတိထားရန် • score ${area.score}'
      : '${_zoneSignalLabel(text, strongest.name)} focus • score ${area.score}';
}

_ZoneSignal _strongestAreaSignal(_SkinMapArea area) {
  return [
    _ZoneSignal('oil', area.oilSignal, const Color(0xFFF98128)),
    _ZoneSignal('spots', area.darkSpotSignal, const Color(0xFF8E6DEB)),
    _ZoneSignal('acne', area.acneSignal, const Color(0xFFE95D48)),
    _ZoneSignal('texture', area.textureSignal, const Color(0xFF0E5C56)),
    _ZoneSignal('dryness', area.drynessSignal, const Color(0xFF7A8F72)),
  ].reduce((best, item) => item.value > best.value ? item : best);
}

String _zoneRoutineAdvice(SkinoText text, _SkinMapArea area) {
  final strongest = [
    _ZoneSignal('oil', area.oilSignal, const Color(0xFFF98128)),
    _ZoneSignal('spots', area.darkSpotSignal, const Color(0xFF8E6DEB)),
    _ZoneSignal('acne', area.acneSignal, const Color(0xFFE95D48)),
    _ZoneSignal('texture', area.textureSignal, const Color(0xFF0E5C56)),
    _ZoneSignal('dryness', area.drynessSignal, const Color(0xFF7A8F72)),
  ].reduce((best, item) => item.value > best.value ? item : best);

  if (strongest.value < 0.35) {
    return text.isMyanmar
        ? 'ဒီ zone က တည်ငြိမ်ပါတယ်။ နူးညံ့စွာဆေးကြောခြင်း၊ moisturizer နှင့် sunscreen ကို ပုံမှန်ဆက်လုပ်ပါ။'
        : 'This zone looks stable. Keep gentle cleansing, moisturizer, and sunscreen consistent.';
  }

  return switch (strongest.name) {
    'oil' =>
      text.isMyanmar
          ? 'ဒီနေရာမှာ ပေါ့ပါးတဲ့ product များကိုသုံးပါ။ အဆီပြန်စေတဲ့ heavy product များကို လျှော့ပါ။'
          : 'Focus on light layers here. Use gentle cleansing and avoid heavy oily products on this zone.',
    'spots' =>
      text.isMyanmar
          ? 'ဒီနေရာအတွက် sunscreen ကို မပျက်မကွက်သုံးပါ။ မညှစ်မကိုင်ဘဲ brightening care ကို နူးညံ့စွာဆက်လုပ်ပါ။'
          : 'Keep sunscreen strict for this zone and avoid picking. Brightening care should be gentle and consistent.',
    'acne' =>
      text.isMyanmar
          ? 'ဒီနေရာကို ညှစ်ခြင်းရှောင်ပါ။ သန့်ရှင်းစွာထားပြီး နာကျင်/ပြန့်လာလျှင် specialist ကိုပြပါ။'
          : 'Use calm acne care here. Avoid squeezing, keep the zone clean, and consider specialist help if it is painful or spreading.',
    'texture' =>
      text.isMyanmar
          ? 'အသားအရေ barrier ကို နူးညံ့စွာထိန်းပါ။ ကြမ်းတမ်းစွာ scrub မလုပ်ဘဲ routine ပြီးမှ ပြန်စကင်ပါ။'
          : 'Keep the barrier calm. Avoid aggressive scrubbing and track this zone again after the routine cycle.',
    'dryness' =>
      text.isMyanmar
          ? 'ဒီနေရာကို moisturizer ဖြင့် hydration ထောက်ပံ့ပါ။ Harsh cleanser များကို လျှော့ပါ။'
          : 'Support hydration here with moisturizer and avoid harsh cleansing around this zone.',
    _ =>
      text.isMyanmar
          ? 'Routine ကို နူးညံ့စွာဆက်လုပ်ပြီး နောက်စကင်တွင် ဒီ zone ကို ပြန်စစ်ပါ။'
          : 'Keep routine gentle and track this zone again in the next scan.',
  };
}

class _StartRoutineCard extends StatelessWidget {
  const _StartRoutineCard({
    required this.text,
    required this.result,
    required this.activeRoutine,
    required this.isGuest,
    required this.isActive,
    required this.onStartRoutine,
    required this.onOpenCare,
  });

  final SkinoText text;
  final SkinAnalysisResult result;
  final bool isGuest;
  final bool isActive;
  final ActiveRoutine? activeRoutine;
  final Future<void> Function(SkinAnalysisResult result) onStartRoutine;
  final VoidCallback onOpenCare;

  @override
  Widget build(BuildContext context) {
    final routine = result.treatmentPackage;
    final needsRetake = result.scanQuality?.needsRetake ?? false;
    final hasOtherActiveRoutine =
        activeRoutine != null && activeRoutine!.skinAnalysisId != result.id;
    final canStart = !isGuest && routine != null && !isActive && !needsRetake;
    final title = isActive
        ? 'Routine plan is active'
        : isGuest
        ? 'Login to start routine'
        : needsRetake
        ? 'Retake before routine'
        : hasOtherActiveRoutine
        ? 'Replace routine with this scan'
        : 'Start routine plan';
    final subtitle = isActive
        ? 'Open Care from the drawer to follow morning and night steps.'
        : isGuest
        ? 'Your result is ready. Login first so Skino can save routine progress.'
        : needsRetake
        ? 'This scan may be unstable. Retake with better light and a centered face before starting a care plan.'
        : routine == null
        ? text.emptyBeautyRoutine
        : hasOtherActiveRoutine
        ? 'This will stop ${activeRoutine!.routine.name} and start ${routine.name}.'
        : '${routine.name} can become your daily Care plan.';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFFFE3D1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: canStart
                    ? const Color(0xFFFFE3D1)
                    : const Color(0xFFEAF6F1),
                child: isGuest
                    ? Icon(
                        Icons.lock_outline_rounded,
                        color: canStart
                            ? const Color(0xFFF98128)
                            : const Color(0xFF0E5C56),
                      )
                    : const SkinoImageIcon(
                        asset: SkinoAssets.iconRoutine,
                        size: 34,
                        padding: 2,
                        backgroundColor: Colors.transparent,
                        borderRadius: 12,
                      ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Color(0xFF282420),
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
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
          if (canStart) ...[
            const SizedBox(height: 14),
            FilledButton.icon(
              onPressed: () => _startOrReplace(context, routine.name),
              icon: const Icon(Icons.playlist_add_check_rounded),
              label: Text(
                hasOtherActiveRoutine
                    ? 'Replace Routine'
                    : 'Start Routine Plan',
              ),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFF98128),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 15),
                textStyle: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _startOrReplace(BuildContext context, String routineName) async {
    if (activeRoutine != null && activeRoutine!.skinAnalysisId != result.id) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(
            text.isMyanmar ? 'Routine ပြောင်းမလား?' : 'Replace routine?',
          ),
          content: Text(
            text.isMyanmar
                ? 'လက်ရှိ ${activeRoutine!.routine.name} ကို ရပ်ပြီး $routineName ကို active routine အသစ်အဖြစ် စမယ်။'
                : 'This will stop ${activeRoutine!.routine.name} and start $routineName as your new active routine.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(text.isMyanmar ? 'မပြောင်းသေးပါ' : 'Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFF98128),
                foregroundColor: Colors.white,
              ),
              child: Text(text.isMyanmar ? 'ပြောင်းမယ်' : 'Replace'),
            ),
          ],
        ),
      );
      if (confirmed != true) {
        return;
      }
    }

    await onStartRoutine(result);
    if (!context.mounted) {
      return;
    }
    Navigator.of(context).pop();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      onOpenCare();
    });
  }
}

class _CarePage extends StatelessWidget {
  const _CarePage({
    required this.text,
    required this.result,
    required this.activeRoutine,
    required this.latestScan,
    required this.session,
    required this.isGuest,
    required this.onStartRoutine,
    required this.onStopRoutine,
    required this.onUpdateRoutineToday,
    required this.onOpenHome,
    required this.onStartScan,
    required this.onOpenSettings,
    required this.onOpenSpecialist,
    required this.onOpenScanHistory,
    required this.onOpenHelpSafety,
    required this.onLogout,
  });

  final SkinoText text;
  final SkinAnalysisResult? result;
  final ActiveRoutine? activeRoutine;
  final SkinAnalysisResult? latestScan;
  final AuthSession? session;
  final bool isGuest;
  final Future<void> Function(SkinAnalysisResult result) onStartRoutine;
  final Future<void> Function() onStopRoutine;
  final Future<void> Function({
    String? checkDate,
    bool? morningDone,
    bool? nightDone,
  })
  onUpdateRoutineToday;
  final VoidCallback onOpenHome;
  final VoidCallback onStartScan;
  final VoidCallback onOpenSettings;
  final VoidCallback onOpenSpecialist;
  final VoidCallback onOpenScanHistory;
  final VoidCallback onOpenHelpSafety;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    final active = activeRoutine;
    final latestResult = result;

    return Scaffold(
      backgroundColor: const Color(0xFFFBF9F4),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFBF9F4),
        foregroundColor: const Color(0xFF282420),
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu_rounded),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        title: Text(text.care),
      ),
      drawer: _PageNavigationDrawer(
        text: text,
        session: session,
        onOpenHome: onOpenHome,
        onOpenScan: onStartScan,
        onOpenSettings: onOpenSettings,
        onOpenSpecialist: onOpenSpecialist,
        onOpenCare: null,
        onOpenScanHistory: onOpenScanHistory,
        onOpenHelpSafety: onOpenHelpSafety,
        onLogout: onLogout,
      ),
      body: _PageScaffold(
        children: [
          _CareHeroHeader(text: text),
          const SizedBox(height: 14),
          if (latestResult == null)
            _CareEmptyState(
              icon: Icons.center_focus_strong_rounded,
              assetIcon: SkinoAssets.iconScan,
              title: 'Scan first',
              subtitle:
                  'Skino needs one face scan before it can create a care routine.',
              actionLabel: text.startScan,
              onAction: onStartScan,
            )
          else if (isGuest)
            const _CareEmptyState(
              icon: Icons.lock_outline_rounded,
              title: 'Login required',
              subtitle:
                  'Your scan result is ready, but routine progress starts after login.',
            )
          else if (active == null)
            _RoutinePendingCard(
              text: text,
              result: latestResult,
              onStartRoutine: onStartRoutine,
            )
          else
            _ActiveRoutinePanel(
              text: text,
              activeRoutine: active,
              latestScan: latestScan,
              onStartScan: onStartScan,
              onStopRoutine: onStopRoutine,
              onUndoStopRoutine: () => onStartRoutine(active.skinAnalysis),
              onUpdateToday: onUpdateRoutineToday,
            ),
        ],
      ),
    );
  }
}

class _CareHeroHeader extends StatelessWidget {
  const _CareHeroHeader({required this.text});

  final SkinoText text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFFFE7D8)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF123C36).withValues(alpha: 0.035),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFFFFF3EC),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const SkinoImageIcon(
              asset: SkinoAssets.iconProgress,
              size: 42,
              padding: 3,
              backgroundColor: Colors.transparent,
              borderRadius: 15,
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  text.beautyRoutines,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF282420),
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    height: 1.05,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  text.beautyRoutinesSubtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF68625B),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    height: 1.3,
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

class _RoutinePendingCard extends StatelessWidget {
  const _RoutinePendingCard({
    required this.text,
    required this.result,
    required this.onStartRoutine,
  });

  final SkinoText text;
  final SkinAnalysisResult result;
  final Future<void> Function(SkinAnalysisResult result) onStartRoutine;

  @override
  Widget build(BuildContext context) {
    final routine = result.treatmentPackage;
    final needsRetake = result.scanQuality?.needsRetake ?? false;
    final morningSteps = _morningRoutineSteps(result);
    final nightSteps = _nightRoutineSteps(result);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFFFE3D1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _MiniScanSummary(text: text, result: result),
          const SizedBox(height: 14),
          Text(
            routine == null
                ? text.emptyBeautyRoutine
                : (text.isMyanmar
                      ? 'စတင်နိုင်သော care plan: ${routine.name}'
                      : 'Ready plan: ${routine.name}'),
            style: const TextStyle(
              color: Color(0xFF282420),
              fontSize: 17,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            routine?.reason ??
                'Run another scan if Skino could not generate a plan.',
            style: const TextStyle(
              color: Color(0xFF68625B),
              fontWeight: FontWeight.w500,
            ),
          ),
          if (routine != null) ...[
            const SizedBox(height: 14),
            _RoutineStarterPreview(
              text: text,
              followUpDays: routine.followUpDays,
              morningSteps: morningSteps,
              nightSteps: nightSteps,
            ),
          ],
          const SizedBox(height: 14),
          FilledButton.icon(
            onPressed: routine == null || needsRetake
                ? null
                : () async => await onStartRoutine(result),
            icon: const Icon(Icons.playlist_add_check_rounded),
            label: Text(
              needsRetake
                  ? (text.isMyanmar ? 'အရင် ပြန်စကင်ပါ' : 'Retake scan first')
                  : (text.isMyanmar ? 'Routine စတင်မယ်' : 'Start Routine Plan'),
            ),
          ),
        ],
      ),
    );
  }
}

class _RoutineStarterPreview extends StatelessWidget {
  const _RoutineStarterPreview({
    required this.text,
    required this.followUpDays,
    required this.morningSteps,
    required this.nightSteps,
  });

  final SkinoText text;
  final int followUpDays;
  final List<String> morningSteps;
  final List<String> nightSteps;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7F1),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFFFD0B3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const SkinoImageIcon.inline(
                asset: SkinoAssets.iconProgress,
                size: 28,
                backgroundColor: Colors.white,
                borderRadius: 10,
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Text(
                  text.isMyanmar
                      ? 'Routine စတင်ပြီး $followUpDays ရက်အတွင်း progress scan ပြန်လုပ်ပါ။'
                      : 'Start this routine, then compare with a follow-up scan in $followUpDays days.',
                  style: const TextStyle(
                    color: Color(0xFF282420),
                    fontWeight: FontWeight.w800,
                    height: 1.32,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _RoutineStarterColumn(
                title: text.morningCare,
                icon: Icons.wb_sunny_outlined,
                steps: morningSteps,
                accent: const Color(0xFFF98128),
              ),
              const SizedBox(width: 10),
              _RoutineStarterColumn(
                title: text.nightCare,
                icon: Icons.dark_mode_outlined,
                steps: nightSteps,
                accent: const Color(0xFF0E5C56),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RoutineStarterColumn extends StatelessWidget {
  const _RoutineStarterColumn({
    required this.title,
    required this.icon,
    required this.steps,
    required this.accent,
  });

  final String title;
  final IconData icon;
  final List<String> steps;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(11),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: accent.withValues(alpha: 0.16)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: accent, size: 17),
                const SizedBox(width: 5),
                Expanded(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF282420),
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            for (final step in steps.take(3)) ...[
              Text(
                '• ${_titleCase(step)}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFF625B53),
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 3),
            ],
          ],
        ),
      ),
    );
  }
}

class _ActiveRoutinePanel extends StatefulWidget {
  const _ActiveRoutinePanel({
    required this.text,
    required this.activeRoutine,
    required this.latestScan,
    required this.onStartScan,
    required this.onStopRoutine,
    required this.onUndoStopRoutine,
    required this.onUpdateToday,
  });

  final SkinoText text;
  final ActiveRoutine activeRoutine;
  final SkinAnalysisResult? latestScan;
  final VoidCallback onStartScan;
  final Future<void> Function() onStopRoutine;
  final Future<void> Function() onUndoStopRoutine;
  final Future<void> Function({
    String? checkDate,
    bool? morningDone,
    bool? nightDone,
  })
  onUpdateToday;

  @override
  State<_ActiveRoutinePanel> createState() => _ActiveRoutinePanelState();
}

class _ActiveRoutinePanelState extends State<_ActiveRoutinePanel> {
  String _selectedDate = '';
  late bool _morningDone;
  late bool _nightDone;
  Set<int> _morningStepChecks = <int>{};
  Set<int> _nightStepChecks = <int>{};
  bool _updatingMorning = false;
  bool _updatingNight = false;
  bool _showMorningRoutine = true;
  bool _showDashboardDetails = false;

  @override
  void initState() {
    super.initState();
    _syncFromWidget();
  }

  @override
  void didUpdateWidget(covariant _ActiveRoutinePanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    final oldToday = oldWidget.activeRoutine.today;
    final newToday = widget.activeRoutine.today;
    if (oldWidget.activeRoutine.id != widget.activeRoutine.id ||
        oldToday.date != newToday.date ||
        oldToday.morningDone != newToday.morningDone ||
        oldToday.nightDone != newToday.nightDone ||
        _weekSignature(oldWidget.activeRoutine) !=
            _weekSignature(widget.activeRoutine)) {
      _syncFromWidget();
    }
  }

  String _weekSignature(ActiveRoutine routine) {
    return routine.week.checkIns
        .map((day) => '${day.date}:${day.morningDone}:${day.nightDone}')
        .join('|');
  }

  void _syncFromWidget() {
    final week = widget.activeRoutine.week.checkIns;
    final selected =
        _dayFromDate(week, _selectedDate) ??
        _todayFrom(week) ??
        (week.isNotEmpty ? week.first : null);
    _selectedDate = selected?.date ?? widget.activeRoutine.today.date;
    _syncSelectedDayState();
    _loadStepChecks();
  }

  RoutineDayCheckIn? _dayFromDate(List<RoutineDayCheckIn> days, String date) {
    if (date.isEmpty) {
      return null;
    }
    for (final day in days) {
      if (day.date == date) {
        return day;
      }
    }
    return null;
  }

  RoutineDayCheckIn? _todayFrom(List<RoutineDayCheckIn> days) {
    for (final day in days) {
      if (day.isToday) {
        return day;
      }
    }
    return null;
  }

  void _syncSelectedDayState() {
    final selected = _selectedDay;
    _morningDone =
        selected?.morningDone ?? widget.activeRoutine.today.morningDone;
    _nightDone = selected?.nightDone ?? widget.activeRoutine.today.nightDone;
  }

  String _stepKey(String moment) {
    return 'skino.routine.${widget.activeRoutine.id}.$_selectedDate.$moment.steps';
  }

  Future<void> _loadStepChecks() async {
    final prefs = await SharedPreferences.getInstance();
    final morning = prefs.getStringList(_stepKey('morning'));
    final night = prefs.getStringList(_stepKey('night'));
    if (!mounted) {
      return;
    }
    setState(() {
      _morningStepChecks = _checksFromStorage(morning, _morningDone);
      _nightStepChecks = _checksFromStorage(night, _nightDone);
    });
  }

  Set<int> _checksFromStorage(List<String>? stored, bool sessionDone) {
    if (stored == null) {
      return sessionDone ? {0, 1, 2, 3, 4, 5} : <int>{};
    }
    return stored
        .map(int.tryParse)
        .whereType<int>()
        .where((index) => index >= 0)
        .toSet();
  }

  Future<void> _saveStepChecks(String moment, Set<int> checks) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _stepKey(moment),
      checks.map((index) => index.toString()).toList(),
    );
  }

  RoutineDayCheckIn? get _selectedDay {
    for (final day in widget.activeRoutine.week.checkIns) {
      if (day.date == _selectedDate) {
        return day;
      }
    }
    return null;
  }

  void _selectDay(RoutineDayCheckIn day) {
    setState(() {
      _selectedDate = day.date;
      _morningDone = day.morningDone;
      _nightDone = day.nightDone;
    });
    _loadStepChecks();
  }

  Future<void> _toggleMorningStep(int index, int totalSteps) async {
    if (_updatingMorning || _morningStepChecks.contains(index)) {
      return;
    }
    final previousChecks = Set<int>.from(_morningStepChecks);
    final next = Set<int>.from(_morningStepChecks);
    next.add(index);
    final nextDone = totalSteps > 0 && next.length >= totalSteps;
    setState(() => _morningStepChecks = next);
    try {
      await _saveStepChecks('morning', next);
      if (nextDone && !_morningDone) {
        await _setMorningDone(true);
      }
    } catch (_) {
      if (mounted) {
        setState(() => _morningStepChecks = previousChecks);
      }
      await _saveStepChecks('morning', previousChecks);
      rethrow;
    }
  }

  Future<void> _toggleNightStep(int index, int totalSteps) async {
    if (_updatingNight || _nightStepChecks.contains(index)) {
      return;
    }
    final previousChecks = Set<int>.from(_nightStepChecks);
    final next = Set<int>.from(_nightStepChecks);
    next.add(index);
    final nextDone = totalSteps > 0 && next.length >= totalSteps;
    setState(() => _nightStepChecks = next);
    try {
      await _saveStepChecks('night', next);
      if (nextDone && !_nightDone) {
        await _setNightDone(true);
      }
    } catch (_) {
      if (mounted) {
        setState(() => _nightStepChecks = previousChecks);
      }
      await _saveStepChecks('night', previousChecks);
      rethrow;
    }
  }

  Future<void> _setMorningDone(bool value) async {
    if (_updatingMorning || (!value && _morningDone)) {
      return;
    }
    final previous = _morningDone;
    setState(() {
      _morningDone = value;
      _updatingMorning = true;
    });
    try {
      await widget.onUpdateToday(checkDate: _selectedDate, morningDone: value);
    } catch (_) {
      if (mounted) {
        setState(() => _morningDone = previous);
      }
      rethrow;
    } finally {
      if (mounted) {
        setState(() => _updatingMorning = false);
      }
    }
  }

  Future<void> _setNightDone(bool value) async {
    if (_updatingNight || (!value && _nightDone)) {
      return;
    }
    final previous = _nightDone;
    setState(() {
      _nightDone = value;
      _updatingNight = true;
    });
    try {
      await widget.onUpdateToday(checkDate: _selectedDate, nightDone: value);
    } catch (_) {
      if (mounted) {
        setState(() => _nightDone = previous);
      }
      rethrow;
    } finally {
      if (mounted) {
        setState(() => _updatingNight = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = widget.text;
    final result = widget.activeRoutine.skinAnalysis;
    final routine = result.treatmentPackage;
    final morningSteps = _morningRoutineSteps(result);
    final nightSteps = _nightRoutineSteps(result);
    final selectedDay = _selectedDay;
    final visibleSteps = _showMorningRoutine ? morningSteps : nightSteps;
    final visibleChecks = _showMorningRoutine
        ? _visibleChecks(_morningStepChecks, morningSteps.length)
        : _visibleChecks(_nightStepChecks, nightSteps.length);
    final visibleDone = _showMorningRoutine ? _morningDone : _nightDone;
    final visibleUpdating = _showMorningRoutine
        ? _updatingMorning
        : _updatingNight;
    final visibleAccent = _showMorningRoutine
        ? const Color(0xFFF98128)
        : const Color(0xFF0E5C56);

    return Column(
      children: [
        _ActiveRoutinePlanBanner(
          text: text,
          routineName: routine?.name ?? text.calmRoutine,
          reason: routine?.reason ?? text.todayBeautyPlanSubtitle,
        ),
        const SizedBox(height: 12),
        _RoutineMomentSwitch(
          text: text,
          showMorning: _showMorningRoutine,
          morningDone: _morningDone,
          nightDone: _nightDone,
          onChanged: (showMorning) =>
              setState(() => _showMorningRoutine = showMorning),
        ),
        const SizedBox(height: 12),
        _RoutineTimeBlock(
          title:
              '${_showMorningRoutine ? text.morningCare : text.nightCare}${selectedDay == null ? '' : ' • ${selectedDay.label}'}',
          icon: _showMorningRoutine
              ? Icons.wb_sunny_outlined
              : Icons.dark_mode_outlined,
          steps: visibleSteps,
          accent: visibleAccent,
          checkedSteps: visibleChecks,
          isDone: visibleDone,
          isUpdating: visibleUpdating,
          onToggleStep: (index) => _showMorningRoutine
              ? _toggleMorningStep(index, morningSteps.length)
              : _toggleNightStep(index, nightSteps.length),
        ),
        const SizedBox(height: 12),
        _RoutineNextActionCard(
          text: text,
          showMorning: _showMorningRoutine,
          morningDone: _morningDone,
          nightDone: _nightDone,
          visibleDone: visibleDone,
          visibleCheckedCount: visibleChecks.length,
          visibleStepCount: visibleSteps.length,
          accent: visibleAccent,
          onSwitchMoment: () =>
              setState(() => _showMorningRoutine = !_showMorningRoutine),
        ),
        const SizedBox(height: 12),
        _RoutineTodayDashboard(
          text: text,
          activeRoutine: widget.activeRoutine,
          morningDone: _morningDone,
          nightDone: _nightDone,
          morningStepCount: morningSteps.length,
          nightStepCount: nightSteps.length,
          morningCheckedCount: _visibleChecks(
            _morningStepChecks,
            morningSteps.length,
          ).length,
          nightCheckedCount: _visibleChecks(
            _nightStepChecks,
            nightSteps.length,
          ).length,
          expanded: _showDashboardDetails,
          onToggleExpanded: () =>
              setState(() => _showDashboardDetails = !_showDashboardDetails),
        ),
        const SizedBox(height: 12),
        _RoutineWeekPlanner(
          text: text,
          days: widget.activeRoutine.week.checkIns,
          selectedDate: _selectedDate,
          onSelect: _selectDay,
        ),
        const SizedBox(height: 12),
        _RoutineReminderCard(text: text),
        const SizedBox(height: 12),
        _RoutineProgressCard(
          text: text,
          sourceScan: result,
          latestScan: widget.latestScan,
          startedAt: widget.activeRoutine.startedAt,
          onStartScan: widget.onStartScan,
        ),
        const SizedBox(height: 12),
        _StopRoutineCard(
          text: text,
          routineName: routine?.name ?? text.calmRoutine,
          onStopRoutine: widget.onStopRoutine,
          onUndoStopRoutine: widget.onUndoStopRoutine,
        ),
      ],
    );
  }

  Set<int> _visibleChecks(Set<int> checks, int totalSteps) {
    if (totalSteps <= 0) {
      return <int>{};
    }
    return checks.where((index) => index < totalSteps).toSet();
  }
}

class _ActiveRoutinePlanBanner extends StatelessWidget {
  const _ActiveRoutinePlanBanner({
    required this.text,
    required this.routineName,
    required this.reason,
  });

  final SkinoText text;
  final String routineName;
  final String reason;

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFFFE3D1)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF123C36).withValues(alpha: 0.04),
            blurRadius: 14,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Row(
          children: [
            const SkinoImageIcon(
              asset: SkinoAssets.iconRoutine,
              size: 52,
              padding: 5,
              backgroundColor: Color(0xFFFFF3EC),
              borderRadius: 18,
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    routineName,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF282420),
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      height: 1.16,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    reason,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF625B53),
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RoutineTodayDashboard extends StatelessWidget {
  const _RoutineTodayDashboard({
    required this.text,
    required this.activeRoutine,
    required this.morningDone,
    required this.nightDone,
    required this.morningStepCount,
    required this.nightStepCount,
    required this.morningCheckedCount,
    required this.nightCheckedCount,
    required this.expanded,
    required this.onToggleExpanded,
  });

  final SkinoText text;
  final ActiveRoutine activeRoutine;
  final bool morningDone;
  final bool nightDone;
  final int morningStepCount;
  final int nightStepCount;
  final int morningCheckedCount;
  final int nightCheckedCount;
  final bool expanded;
  final VoidCallback onToggleExpanded;

  @override
  Widget build(BuildContext context) {
    final week = activeRoutine.week.checkIns;
    final completedDays = week.where((day) => day.isComplete).length;
    final totalDays = week.isEmpty ? 7 : week.length;
    final todaySessions = [morningDone, nightDone].where((done) => done).length;
    final followUp = _followUpDueLabel(activeRoutine);
    final score = activeRoutine.skinAnalysis.skinHealthScore;
    final morningProgress = morningStepCount == 0
        ? (morningDone ? 1.0 : 0.0)
        : (morningCheckedCount / morningStepCount).clamp(0.0, 1.0);
    final nightProgress = nightStepCount == 0
        ? (nightDone ? 1.0 : 0.0)
        : (nightCheckedCount / nightStepCount).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF123C36),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF123C36).withValues(alpha: 0.16),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const SkinoImageIcon.page(
                asset: SkinoAssets.iconReport,
                size: 58,
                backgroundColor: Colors.white,
                borderRadius: 19,
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      text.isMyanmar
                          ? 'ဒီနေ့ care dashboard'
                          : 'Today care dashboard',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      todaySessions == 2
                          ? (text.isMyanmar
                                ? 'မနက်/ည routine ပြီးပါပြီ။'
                                : 'Morning and night routine are complete.')
                          : (text.isMyanmar
                                ? 'ဒီနေ့ $todaySessions/2 session ပြီးပါပြီ။'
                                : '$todaySessions of 2 sessions complete today.'),
                      style: const TextStyle(
                        color: Color(0xFFEAF6F1),
                        fontWeight: FontWeight.w600,
                        height: 1.32,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: expanded
                    ? (text.isMyanmar ? 'အကျဉ်းချုံ့မယ်' : 'Collapse')
                    : (text.isMyanmar ? 'အသေးစိတ်ကြည့်မယ်' : 'Expand'),
                onPressed: onToggleExpanded,
                style: IconButton.styleFrom(
                  backgroundColor: Colors.white.withValues(alpha: 0.12),
                  foregroundColor: Colors.white,
                ),
                icon: Icon(
                  expanded
                      ? Icons.keyboard_arrow_up_rounded
                      : Icons.keyboard_arrow_down_rounded,
                ),
              ),
              _DarkRoutineScore(score: score),
            ],
          ),
          if (expanded) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                _RoutineDashboardMetric(
                  label: text.isMyanmar ? 'ဒီနေ့' : 'Today',
                  value: '$todaySessions/2',
                  icon: Icons.check_circle_outline_rounded,
                ),
                const SizedBox(width: 8),
                _RoutineDashboardMetric(
                  label: text.isMyanmar ? 'အပတ်' : 'Week',
                  value: '$completedDays/$totalDays',
                  icon: Icons.calendar_month_outlined,
                ),
                const SizedBox(width: 8),
                _RoutineDashboardMetric(
                  label: text.isMyanmar ? 'စကင်' : 'Scan',
                  value: followUp.replaceFirst('Follow-up ', ''),
                  icon: Icons.center_focus_strong_outlined,
                ),
              ],
            ),
            const SizedBox(height: 14),
            _RoutineProgressLine(
              label: text.morningCare,
              value: morningProgress,
              done: morningDone,
              accent: const Color(0xFFF98128),
            ),
            const SizedBox(height: 8),
            _RoutineProgressLine(
              label: text.nightCare,
              value: nightProgress,
              done: nightDone,
              accent: const Color(0xFF7EF1CF),
            ),
          ],
        ],
      ),
    );
  }
}

class _RoutineNextActionCard extends StatelessWidget {
  const _RoutineNextActionCard({
    required this.text,
    required this.showMorning,
    required this.morningDone,
    required this.nightDone,
    required this.visibleDone,
    required this.visibleCheckedCount,
    required this.visibleStepCount,
    required this.accent,
    required this.onSwitchMoment,
  });

  final SkinoText text;
  final bool showMorning;
  final bool morningDone;
  final bool nightDone;
  final bool visibleDone;
  final int visibleCheckedCount;
  final int visibleStepCount;
  final Color accent;
  final VoidCallback onSwitchMoment;

  @override
  Widget build(BuildContext context) {
    final allDone = morningDone && nightDone;
    final momentLabel = showMorning ? text.morningCare : text.nightCare;
    final otherLabel = showMorning ? text.nightCare : text.morningCare;
    final title = allDone
        ? (text.isMyanmar ? 'ဒီနေ့ routine ပြီးပါပြီ' : 'Today is complete')
        : visibleDone
        ? (text.isMyanmar
              ? '$otherLabel ဆက်လုပ်ပါ'
              : 'Continue with $otherLabel')
        : (text.isMyanmar
              ? '$momentLabel အတွက် next step'
              : '$momentLabel next step');
    final detail = allDone
        ? (text.isMyanmar
              ? 'နောက် follow-up scan အတွက် progress ကို စောင့်ကြည့်ပါ။'
              : 'Keep the rhythm and watch for your follow-up scan.')
        : visibleDone
        ? (text.isMyanmar
              ? 'မပြီးသေးတဲ့ care moment ကို ပြောင်းကြည့်ပါ။'
              : 'Switch to the remaining care moment.')
        : (text.isMyanmar
              ? '$visibleCheckedCount/$visibleStepCount step ပြီးပါပြီ။'
              : '$visibleCheckedCount of $visibleStepCount steps complete.');

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFFFE3D1)),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: 0.07),
            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(17),
            ),
            child: Icon(
              allDone
                  ? Icons.verified_rounded
                  : showMorning
                  ? Icons.wb_sunny_outlined
                  : Icons.dark_mode_outlined,
              color: accent,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF282420),
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  detail,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF68625B),
                    fontWeight: FontWeight.w600,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          if (!allDone) ...[
            const SizedBox(width: 10),
            IconButton.filledTonal(
              onPressed: visibleDone ? onSwitchMoment : null,
              icon: const Icon(Icons.swap_horiz_rounded),
              tooltip: 'Switch routine moment',
            ),
          ],
        ],
      ),
    );
  }
}

class _DarkRoutineScore extends StatelessWidget {
  const _DarkRoutineScore({required this.score});

  final int score;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 56,
      height: 56,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '$score',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 19,
              fontWeight: FontWeight.w900,
              height: 1,
            ),
          ),
          const SizedBox(height: 2),
          const Text(
            'score',
            style: TextStyle(
              color: Color(0xFFEAF6F1),
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _RoutineDashboardMetric extends StatelessWidget {
  const _RoutineDashboardMetric({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        constraints: const BoxConstraints(minHeight: 72),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: const Color(0xFFFFD0B3), size: 18),
            const Spacer(),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w900,
              ),
            ),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFFEAF6F1),
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RoutineProgressLine extends StatelessWidget {
  const _RoutineProgressLine({
    required this.label,
    required this.value,
    required this.done,
    required this.accent,
  });

  final String label;
  final double value;
  final bool done;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 82,
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: done ? 1 : value,
              minHeight: 9,
              backgroundColor: Colors.white.withValues(alpha: 0.14),
              color: accent,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Icon(
          done ? Icons.check_circle_rounded : Icons.radio_button_unchecked,
          color: done ? accent : Colors.white.withValues(alpha: 0.5),
          size: 18,
        ),
      ],
    );
  }
}

class _RoutineReminderCard extends StatefulWidget {
  const _RoutineReminderCard({required this.text});

  final SkinoText text;

  @override
  State<_RoutineReminderCard> createState() => _RoutineReminderCardState();
}

class _RoutineWeekPlanner extends StatelessWidget {
  const _RoutineWeekPlanner({
    required this.text,
    required this.days,
    required this.selectedDate,
    required this.onSelect,
  });

  final SkinoText text;
  final List<RoutineDayCheckIn> days;
  final String selectedDate;
  final ValueChanged<RoutineDayCheckIn> onSelect;

  @override
  Widget build(BuildContext context) {
    final completed = days.where((day) => day.isComplete).length;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFFFE3D1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const SkinoImageIcon(
                asset: SkinoAssets.iconHistory,
                size: 46,
                padding: 4,
                backgroundColor: Color(0xFFFFF3EC),
                borderRadius: 17,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      text.isMyanmar ? 'အပတ်စဉ် care rhythm' : 'Care rhythm',
                      style: const TextStyle(
                        color: Color(0xFF282420),
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      text.isMyanmar
                          ? 'မနက်/ည routine ကို တစ်ပတ်စာ ကြည့်နိုင်ပါတယ်။'
                          : 'Build a habit, glow every day.',
                      style: const TextStyle(
                        color: Color(0xFF68625B),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              _StatusPill(
                label: '$completed/${days.length}',
                color: const Color(0xFFF98128),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (days.isEmpty)
            const Text(
              'Start your routine to build this week tracker.',
              style: TextStyle(
                color: Color(0xFF68625B),
                fontWeight: FontWeight.w500,
              ),
            )
          else
            Row(
              children: [
                for (final day in days) ...[
                  Expanded(
                    child: _RoutineDayCell(
                      day: day,
                      selected: day.date == selectedDate,
                      onTap: () => onSelect(day),
                    ),
                  ),
                  if (day != days.last) const SizedBox(width: 7),
                ],
              ],
            ),
        ],
      ),
    );
  }
}

class _RoutineDayCell extends StatelessWidget {
  const _RoutineDayCell({
    required this.day,
    required this.selected,
    required this.onTap,
  });

  final RoutineDayCheckIn day;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? const Color(0xFFF98128) : const Color(0xFFEAF6F1);
    final foreground = selected ? Colors.white : const Color(0xFF123C36);
    final complete = day.isComplete;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 7),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? const Color(0xFFF98128) : const Color(0xFFCCE7DE),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              day.label.isEmpty ? '--' : day.label.substring(0, 1),
              style: TextStyle(
                color: foreground,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 5),
            Container(
              width: 26,
              height: 22,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: selected
                    ? Colors.white.withValues(alpha: 0.2)
                    : Colors.white.withValues(alpha: 0.86),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                complete
                    ? Icons.sentiment_very_satisfied_rounded
                    : day.morningDone || day.nightDone
                    ? Icons.sentiment_satisfied_rounded
                    : Icons.sentiment_neutral_rounded,
                color: selected
                    ? Colors.white
                    : complete
                    ? const Color(0xFFF98128)
                    : const Color(0xFF8BBFB3),
                size: 16,
              ),
            ),
            const SizedBox(height: 5),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _RoutineMomentDot(done: day.morningDone, selected: selected),
                const SizedBox(width: 4),
                _RoutineMomentDot(done: day.nightDone, selected: selected),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _RoutineMomentDot extends StatelessWidget {
  const _RoutineMomentDot({required this.done, required this.selected});

  final bool done;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        color: done
            ? (selected ? Colors.white : const Color(0xFF0E5C56))
            : (selected ? Colors.white.withValues(alpha: 0.38) : Colors.white),
        shape: BoxShape.circle,
        border: Border.all(
          color: selected ? Colors.white : const Color(0xFFCCE7DE),
        ),
      ),
    );
  }
}

class _RoutineReminderCardState extends State<_RoutineReminderCard> {
  final RoutineReminderService _service = const RoutineReminderService();
  RoutineReminderSettings _settings = RoutineReminderSettings.defaults;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final settings = await _service.read();
    if (!mounted) {
      return;
    }
    setState(() {
      _settings = settings;
      _isLoading = false;
    });
  }

  Future<void> _save(RoutineReminderSettings settings) async {
    setState(() {
      _settings = settings;
      _isLoading = true;
    });
    await _service.save(settings);
    if (!mounted) {
      return;
    }
    setState(() => _isLoading = false);
  }

  Future<void> _toggle(bool enabled) {
    return _save(_settings.copyWith(enabled: enabled));
  }

  Future<void> _pickMorningTime() async {
    final picked = await _pickTime(
      hour: _settings.morningHour,
      minute: _settings.morningMinute,
    );
    if (picked == null) {
      return;
    }
    await _save(
      _settings.copyWith(
        morningHour: picked.hour,
        morningMinute: picked.minute,
      ),
    );
  }

  Future<void> _pickNightTime() async {
    final picked = await _pickTime(
      hour: _settings.nightHour,
      minute: _settings.nightMinute,
    );
    if (picked == null) {
      return;
    }
    await _save(
      _settings.copyWith(nightHour: picked.hour, nightMinute: picked.minute),
    );
  }

  Future<TimeOfDay?> _pickTime({required int hour, required int minute}) {
    return showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: hour, minute: minute),
    );
  }

  @override
  Widget build(BuildContext context) {
    final text = widget.text;
    final enabled = _settings.enabled;

    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7F1),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFFFD0B3)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFF98128).withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Row(
        children: [
          const SkinoImageIcon(
            asset: SkinoAssets.iconReminder,
            size: 52,
            padding: 5,
            backgroundColor: Colors.white,
            borderRadius: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  text.isMyanmar ? 'Routine reminder' : 'Routine reminder',
                  style: const TextStyle(
                    color: Color(0xFF282420),
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  runSpacing: 5,
                  children: [
                    _TinyTimeChip(
                      icon: Icons.wb_sunny_outlined,
                      label: _settings.morningLabel,
                      enabled: enabled,
                      onTap: _pickMorningTime,
                    ),
                    _TinyTimeChip(
                      icon: Icons.dark_mode_outlined,
                      label: _settings.nightLabel,
                      enabled: enabled,
                      onTap: _pickNightTime,
                    ),
                  ],
                ),
              ],
            ),
          ),
          Switch(
            value: enabled,
            activeThumbColor: const Color(0xFFFFFFFF),
            activeTrackColor: const Color(0xFFF98128),
            inactiveThumbColor: Colors.white,
            inactiveTrackColor: const Color(0xFFE8E1D7),
            onChanged: _isLoading ? null : _toggle,
          ),
        ],
      ),
    );
  }
}

class _TinyTimeChip extends StatelessWidget {
  const _TinyTimeChip({
    required this.icon,
    required this.label,
    required this.enabled,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(999),
      child: Ink(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: enabled ? 1 : 0.64),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: const Color(0xFFFFE3D1)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: const Color(0xFFF98128), size: 16),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                color: enabled
                    ? const Color(0xFF282420)
                    : const Color(0xFF8D857C),
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RoutineMomentSwitch extends StatelessWidget {
  const _RoutineMomentSwitch({
    required this.text,
    required this.showMorning,
    required this.morningDone,
    required this.nightDone,
    required this.onChanged,
  });

  final SkinoText text;
  final bool showMorning;
  final bool morningDone;
  final bool nightDone;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(7),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFFFE3D1)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFF98128).withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _RoutineMomentButton(
              icon: Icons.wb_sunny_outlined,
              label: text.morningCare,
              done: morningDone,
              selected: showMorning,
              accent: const Color(0xFFF98128),
              softColor: const Color(0xFFFFE3D1),
              onTap: () => onChanged(true),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _RoutineMomentButton(
              icon: Icons.dark_mode_outlined,
              label: text.nightCare,
              done: nightDone,
              selected: !showMorning,
              accent: const Color(0xFF0E5C56),
              softColor: const Color(0xFFEAF6F1),
              onTap: () => onChanged(false),
            ),
          ),
        ],
      ),
    );
  }
}

class _RoutineMomentButton extends StatelessWidget {
  const _RoutineMomentButton({
    required this.icon,
    required this.label,
    required this.done,
    required this.selected,
    required this.accent,
    required this.softColor,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool done;
  final bool selected;
  final Color accent;
  final Color softColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: selected ? accent : softColor,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected ? accent : accent.withValues(alpha: 0.16),
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: accent.withValues(alpha: 0.18),
                    blurRadius: 12,
                    offset: const Offset(0, 5),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: selected ? Colors.white : accent, size: 18),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: selected ? Colors.white : const Color(0xFF282420),
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                ),
              ),
            ),
            const SizedBox(width: 6),
            Icon(
              done ? Icons.check_circle_rounded : Icons.radio_button_unchecked,
              color: selected
                  ? Colors.white
                  : done
                  ? const Color(0xFF0E5C56)
                  : const Color(0xFFB8B0A7),
              size: 17,
            ),
          ],
        ),
      ),
    );
  }
}

class _RoutineTimeBlock extends StatelessWidget {
  const _RoutineTimeBlock({
    required this.title,
    required this.icon,
    required this.steps,
    required this.accent,
    required this.checkedSteps,
    required this.isDone,
    required this.isUpdating,
    required this.onToggleStep,
  });

  final String title;
  final IconData icon;
  final List<String> steps;
  final Color accent;
  final Set<int> checkedSteps;
  final bool isDone;
  final bool isUpdating;
  final ValueChanged<int> onToggleStep;

  @override
  Widget build(BuildContext context) {
    final completed = checkedSteps.length.clamp(0, steps.length);
    final allStepsDone = steps.isNotEmpty && completed == steps.length;

    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFFFE3D1)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF123C36).withValues(alpha: 0.04),
            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(17),
                ),
                child: Icon(icon, color: accent),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF282420),
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: allStepsDone || isDone
                      ? const Color(0xFFEAF6F1)
                      : const Color(0xFFFFF7F1),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: allStepsDone || isDone
                        ? const Color(0xFFB9DED3)
                        : const Color(0xFFFFD0B3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isUpdating)
                      const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    else
                      Icon(
                        allStepsDone || isDone
                            ? Icons.check_circle_rounded
                            : Icons.pending_actions_rounded,
                        size: 16,
                        color: allStepsDone || isDone
                            ? const Color(0xFF0E5C56)
                            : const Color(0xFFF98128),
                      ),
                    const SizedBox(width: 5),
                    Text(
                      '$completed/${steps.length}',
                      style: TextStyle(
                        color: allStepsDone || isDone
                            ? const Color(0xFF0E5C56)
                            : const Color(0xFFF98128),
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          for (final entry in steps.asMap().entries) ...[
            InkWell(
              onTap: isUpdating || checkedSteps.contains(entry.key)
                  ? null
                  : () => onToggleStep(entry.key),
              borderRadius: BorderRadius.circular(14),
              child: _RoutineCheckStep(
                index: entry.key + 1,
                label: entry.value,
                accent: accent,
                isDone: checkedSteps.contains(entry.key),
              ),
            ),
            if (entry.key != steps.length - 1)
              const Padding(
                padding: EdgeInsets.only(left: 78, right: 44),
                child: Divider(height: 1, color: Color(0xFFF1E9E2)),
              ),
          ],
        ],
      ),
    );
  }
}

class _RoutineCheckStep extends StatelessWidget {
  const _RoutineCheckStep({
    required this.index,
    required this.label,
    required this.accent,
    required this.isDone,
  });

  final int index;
  final String label;
  final Color accent;
  final bool isDone;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            width: 28,
            height: 28,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: isDone ? accent : Colors.white,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: isDone ? accent : const Color(0xFFFFD0B3),
              ),
            ),
            child: isDone
                ? const Icon(Icons.check_rounded, color: Colors.white, size: 17)
                : Text(
                    '$index',
                    style: const TextStyle(
                      color: Color(0xFFF98128),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
          ),
          const SizedBox(width: 10),
          AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            width: 30,
            height: 30,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: isDone ? const Color(0xFFEAF6F1) : const Color(0xFFFFF3EC),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(
              _routineStepIcon(label),
              color: isDone ? const Color(0xFF0E5C56) : accent,
              size: 18,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: isDone
                    ? const Color(0xFF8D8780)
                    : const Color(0xFF282420),
                fontWeight: isDone ? FontWeight.w500 : FontWeight.w600,
                height: 1.2,
                decoration: isDone
                    ? TextDecoration.lineThrough
                    : TextDecoration.none,
                decorationColor: const Color(0xFF8D8780),
                decorationThickness: 2,
              ),
            ),
          ),
          Icon(
            isDone ? Icons.check_circle_rounded : Icons.circle_outlined,
            color: isDone ? accent : const Color(0xFFB8B0A7),
          ),
        ],
      ),
    );
  }
}

IconData _routineStepIcon(String label) {
  final value = label.toLowerCase();
  if (value.contains('cleanser') || value.contains('clean')) {
    return Icons.water_drop_outlined;
  }
  if (value.contains('serum') ||
      value.contains('treatment') ||
      value.contains('spot')) {
    return Icons.science_outlined;
  }
  if (value.contains('moistur') || value.contains('cream')) {
    return Icons.spa_outlined;
  }
  if (value.contains('sun') || value.contains('spf')) {
    return Icons.wb_sunny_outlined;
  }
  return Icons.checklist_rounded;
}

class _RoutineProgressCard extends StatelessWidget {
  const _RoutineProgressCard({
    required this.text,
    required this.sourceScan,
    required this.latestScan,
    required this.startedAt,
    required this.onStartScan,
  });

  final SkinoText text;
  final SkinAnalysisResult sourceScan;
  final SkinAnalysisResult? latestScan;
  final DateTime? startedAt;
  final VoidCallback onStartScan;

  @override
  Widget build(BuildContext context) {
    final days = sourceScan.treatmentPackage?.followUpDays ?? 14;
    final started = startedAt ?? sourceScan.createdAt;
    final daysPassed = started == null
        ? 0
        : DateTime.now().difference(started.toLocal()).inDays.clamp(0, 999);
    final daysLeft = (days - daysPassed).clamp(0, days);
    final isCompleted = daysPassed >= days;
    final comparisonScan = _isFollowUpScan(sourceScan, latestScan)
        ? latestScan
        : null;
    final scoreDelta = comparisonScan == null
        ? null
        : comparisonScan.skinHealthScore - sourceScan.skinHealthScore;
    final sourceConcerns = sourceScan.concerns.map((item) => item.name).toSet();
    final latestConcerns =
        comparisonScan?.concerns.map((item) => item.name).toSet() ??
        const <String>{};
    final improvedConcerns = sourceConcerns.difference(latestConcerns);
    final newConcerns = latestConcerns.difference(sourceConcerns);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF6F1),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const SkinoImageIcon(
                asset: SkinoAssets.iconProgress,
                size: 34,
                padding: 2,
                backgroundColor: Colors.white,
                borderRadius: 12,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  text.progressTracker,
                  style: const TextStyle(
                    color: Color(0xFF123C36),
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              _StatusPill(
                label: comparisonScan == null
                    ? (isCompleted ? 'Completed' : '$daysLeft days left')
                    : 'Report ready',
                color: const Color(0xFF0E5C56),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            comparisonScan == null
                ? isCompleted
                      ? 'Routine cycle completed from Scan #${sourceScan.id ?? '--'}. Take a follow-up scan to compare your progress.'
                      : 'This routine started from Scan #${sourceScan.id ?? '--'}. Follow it daily and scan again after the follow-up cycle.'
                : 'Routine cycle completed. Compare Scan #${sourceScan.id ?? '--'} with Scan #${comparisonScan.id ?? '--'}.',
            style: const TextStyle(
              color: Color(0xFF625B53),
              fontWeight: FontWeight.w500,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _RoutineTrackingMetric(
                label: 'Baseline',
                value: '${sourceScan.skinHealthScore}',
                icon: Icons.flag_outlined,
                assetIcon: SkinoAssets.iconReport,
              ),
              const SizedBox(width: 8),
              _RoutineTrackingMetric(
                label: comparisonScan == null ? 'Cycle' : 'Change',
                value: scoreDelta == null
                    ? '$daysPassed/$days d'
                    : '${scoreDelta >= 0 ? '+' : ''}$scoreDelta',
                icon: scoreDelta == null
                    ? Icons.calendar_today_outlined
                    : scoreDelta >= 0
                    ? Icons.arrow_upward_rounded
                    : Icons.arrow_downward_rounded,
                assetIcon: SkinoAssets.iconProgress,
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (comparisonScan == null)
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: isCompleted ? onStartScan : null,
                icon: const Icon(Icons.center_focus_strong_rounded),
                label: Text(
                  isCompleted
                      ? 'Take follow-up scan'
                      : 'Follow-up scan in $daysLeft days',
                ),
              ),
            )
          else ...[
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _SmallInfoChip(
                  label: improvedConcerns.isEmpty
                      ? 'No concern cleared yet'
                      : 'Improved: ${_concernSummary(text, improvedConcerns)}',
                ),
                if (newConcerns.isNotEmpty)
                  _SmallInfoChip(
                    label: 'Watch: ${_concernSummary(text, newConcerns)}',
                  ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => _CompareReportPage(
                      text: text,
                      before: sourceScan,
                      after: comparisonScan,
                    ),
                  ),
                ),
                icon: const SkinoImageIcon(
                  asset: SkinoAssets.iconReport,
                  size: 22,
                  padding: 1,
                  backgroundColor: Colors.transparent,
                  borderRadius: 8,
                ),
                label: const Text('Open compare report'),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFF98128),
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _CompareReportPage extends StatelessWidget {
  const _CompareReportPage({
    required this.text,
    required this.before,
    required this.after,
  });

  final SkinoText text;
  final SkinAnalysisResult before;
  final SkinAnalysisResult after;

  @override
  Widget build(BuildContext context) {
    final delta = after.skinHealthScore - before.skinHealthScore;
    final beforeConcerns = before.concerns.map((item) => item.name).toSet();
    final afterConcerns = after.concerns.map((item) => item.name).toSet();
    final improved = beforeConcerns.difference(afterConcerns);
    final watch = afterConcerns.difference(beforeConcerns);
    final headline = delta >= 0
        ? (text.isMyanmar ? 'တိုးတက်မှုရှိနေပါတယ်' : 'Progress improved')
        : (text.isMyanmar ? 'ပြန်စစ်ရန်လိုပါတယ်' : 'Needs attention');

    return Scaffold(
      backgroundColor: const Color(0xFFFBF9F4),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFBF9F4),
        foregroundColor: const Color(0xFF282420),
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(text.isMyanmar ? 'နှိုင်းယှဉ် report' : 'Compare report'),
      ),
      body: _PageScaffold(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.96),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xFFFFE3D1)),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x10123C36),
                  blurRadius: 18,
                  offset: Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: const Color(0xFFFFE3D1),
                      child: const SkinoImageIcon(
                        asset: SkinoAssets.iconReport,
                        size: 34,
                        padding: 2,
                        backgroundColor: Colors.transparent,
                        borderRadius: 12,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            headline,
                            style: const TextStyle(
                              color: Color(0xFF282420),
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            '${delta >= 0 ? '+' : ''}$delta score change',
                            style: const TextStyle(
                              color: Color(0xFFF98128),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    _StatusPill(
                      label: 'Scan #${after.id ?? '--'}',
                      color: const Color(0xFF0E5C56),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _CompareScoreChart(before: before, after: after),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: _CompareScoreTile(
                        label: text.isMyanmar ? 'စတင်ချိန်' : 'Before',
                        score: before.skinHealthScore,
                        scan: before,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _CompareScoreTile(
                        label: text.isMyanmar ? 'နောက်ဆုံး' : 'After',
                        score: after.skinHealthScore,
                        scan: after,
                        highlight: true,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.96),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: const Color(0xFFFFE3D1)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  text.isMyanmar ? 'Concern ပြောင်းလဲမှု' : 'Concern changes',
                  style: const TextStyle(
                    color: Color(0xFF282420),
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 12),
                _CompareScanRow(
                  label: text.isMyanmar ? 'စတင်' : 'Before',
                  scan: before,
                ),
                const SizedBox(height: 10),
                _CompareScanRow(
                  label: text.isMyanmar ? 'ယခု' : 'After',
                  scan: after,
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _SmallInfoChip(
                      label: improved.isEmpty
                          ? (text.isMyanmar
                                ? 'တိုးတက်မှု: ဆက်လက် track'
                                : 'Improved: still tracking')
                          : 'Improved: ${_concernSummary(text, improved)}',
                    ),
                    _SmallInfoChip(
                      label: watch.isEmpty
                          ? (text.isMyanmar
                                ? 'အသစ်တွေ့သော concern: မရှိ'
                                : 'New concerns: none')
                          : 'Watch: ${_concernSummary(text, watch)}',
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _ResultChangeExplanationCard(
            text: text,
            before: before,
            after: after,
          ),
        ],
      ),
    );
  }
}

class _CompareScoreChart extends StatelessWidget {
  const _CompareScoreChart({required this.before, required this.after});

  final SkinAnalysisResult before;
  final SkinAnalysisResult after;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 116,
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7F1),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFFFD0B3)),
      ),
      child: CustomPaint(
        painter: _CompareScoreChartPainter(
          beforeScore: before.skinHealthScore,
          afterScore: after.skinHealthScore,
        ),
        child: const SizedBox.expand(),
      ),
    );
  }
}

class _CompareScoreChartPainter extends CustomPainter {
  const _CompareScoreChartPainter({
    required this.beforeScore,
    required this.afterScore,
  });

  final int beforeScore;
  final int afterScore;

  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = const Color(0xFFE8E1D7)
      ..strokeWidth = 1;
    for (var i = 1; i <= 3; i++) {
      final y = size.height * i / 4;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    Offset pointFor(int score, double x) {
      final normalized = score.clamp(0, 100) / 100;
      return Offset(x, size.height - (size.height * normalized));
    }

    final before = pointFor(beforeScore, size.width * 0.18);
    final after = pointFor(afterScore, size.width * 0.82);
    final linePaint = Paint()
      ..color = const Color(0xFFF98128)
      ..strokeWidth = 3.2
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(before, after, linePaint);

    final fillPaint = Paint()..color = const Color(0xFFF98128);
    final haloPaint = Paint()..color = const Color(0xFFFFD0B3);
    canvas
      ..drawCircle(before, 9, haloPaint)
      ..drawCircle(before, 5, fillPaint)
      ..drawCircle(after, 9, haloPaint)
      ..drawCircle(after, 5, fillPaint);

    _paintChartLabel(canvas, before, '$beforeScore', Alignment.topLeft);
    _paintChartLabel(canvas, after, '$afterScore', Alignment.topRight);
  }

  void _paintChartLabel(
    Canvas canvas,
    Offset point,
    String label,
    Alignment alignment,
  ) {
    final painter = TextPainter(
      text: TextSpan(
        text: label,
        style: const TextStyle(
          color: Color(0xFF123C36),
          fontSize: 13,
          fontWeight: FontWeight.w900,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    final dx = alignment == Alignment.topLeft
        ? point.dx - painter.width - 8
        : point.dx + 8;
    final dy = (point.dy - painter.height / 2).clamp(0.0, double.infinity);
    painter.paint(canvas, Offset(dx.clamp(0, double.infinity), dy));
  }

  @override
  bool shouldRepaint(covariant _CompareScoreChartPainter oldDelegate) {
    return oldDelegate.beforeScore != beforeScore ||
        oldDelegate.afterScore != afterScore;
  }
}

class _CompareScoreTile extends StatelessWidget {
  const _CompareScoreTile({
    required this.label,
    required this.score,
    required this.scan,
    this.highlight = false,
  });

  final String label;
  final int score;
  final SkinAnalysisResult scan;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: highlight ? const Color(0xFFFFE3D1) : const Color(0xFFEAF6F1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: highlight ? const Color(0xFFFFD0B3) : const Color(0xFFCCE7DE),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: highlight
                  ? const Color(0xFF8A3A08)
                  : const Color(0xFF0E5C56),
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '$score',
            style: TextStyle(
              color: highlight
                  ? const Color(0xFFF98128)
                  : const Color(0xFF0E5C56),
              fontSize: 24,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'Scan #${scan.id ?? '--'}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: highlight
                  ? const Color(0xFF8A3A08)
                  : const Color(0xFF68625B),
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _CompareScanRow extends StatelessWidget {
  const _CompareScanRow({required this.label, required this.scan});

  final String label;
  final SkinAnalysisResult scan;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 62,
          child: Text(
            label,
            style: const TextStyle(
              color: Color(0xFF68625B),
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Expanded(
          child: Text(
            'Scan #${scan.id ?? '--'} • ${_formatScanTimestamp(scan.createdAt)} • ${scan.skinType}',
            style: const TextStyle(
              color: Color(0xFF282420),
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

class _StopRoutineCard extends StatelessWidget {
  const _StopRoutineCard({
    required this.text,
    required this.routineName,
    required this.onStopRoutine,
    required this.onUndoStopRoutine,
  });

  final SkinoText text;
  final String routineName;
  final Future<void> Function() onStopRoutine;
  final Future<void> Function() onUndoStopRoutine;

  Future<void> _confirmStop(BuildContext context) async {
    final shouldStop = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(text.isMyanmar ? 'Routine ရပ်မလား?' : 'Stop routine?'),
        content: Text(
          text.isMyanmar
              ? '$routineName ကို active routine အဖြစ် ရပ်ပါမယ်။ Scan history မဖျက်ပါဘူး။'
              : '$routineName will stop as your active routine. Your scan history will stay saved.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(text.isMyanmar ? 'မရပ်သေးပါ' : 'Keep routine'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFF98128),
              foregroundColor: Colors.white,
            ),
            child: Text(text.isMyanmar ? 'ရပ်မယ်' : 'Stop'),
          ),
        ],
      ),
    );

    if (shouldStop == true) {
      await onStopRoutine();
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          duration: const Duration(seconds: 10),
          content: Text(
            text.isMyanmar
                ? 'Routine ကို ရပ်လိုက်ပါပြီ။'
                : 'Routine stopped. You can start a new one from scan history.',
          ),
          action: SnackBarAction(
            label: text.isMyanmar ? 'ပြန်ယူမယ်' : 'Undo',
            onPressed: () async {
              await onUndoStopRoutine();
            },
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFFFE3D1)),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            backgroundColor: Color(0xFFFFF3EC),
            child: Icon(Icons.pause_circle_outline, color: Color(0xFFF98128)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text.isMyanmar
                  ? 'Routine ပြောင်းချင်ရင် အရင်ရပ်နိုင်ပါတယ်။'
                  : 'Need a new plan? Stop this routine first, or replace it from another scan.',
              style: const TextStyle(
                color: Color(0xFF625B53),
                fontWeight: FontWeight.w600,
                height: 1.35,
              ),
            ),
          ),
          TextButton(
            onPressed: () => _confirmStop(context),
            child: Text(text.isMyanmar ? 'ရပ်မယ်' : 'Stop'),
          ),
        ],
      ),
    );
  }
}

class _RoutineTrackingMetric extends StatelessWidget {
  const _RoutineTrackingMetric({
    required this.label,
    required this.value,
    required this.icon,
    this.assetIcon,
  });

  final String label;
  final String value;
  final IconData icon;
  final String? assetIcon;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFCCE7DE)),
        ),
        child: Row(
          children: [
            if (assetIcon == null)
              Icon(icon, color: const Color(0xFFF98128), size: 18)
            else
              SkinoImageIcon(
                asset: assetIcon!,
                size: 22,
                padding: 1,
                backgroundColor: Colors.transparent,
                borderRadius: 8,
              ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF68625B),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF123C36),
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

bool _isFollowUpScan(SkinAnalysisResult? source, SkinAnalysisResult? latest) {
  if (source == null || latest == null) {
    return false;
  }

  if (source.id != null && latest.id != null && source.id == latest.id) {
    return false;
  }

  final sourceDate = source.createdAt;
  final latestDate = latest.createdAt;
  if (sourceDate == null || latestDate == null) {
    return true;
  }

  return latestDate.isAfter(sourceDate);
}

String _followUpDueLabel(ActiveRoutine routine) {
  final days = routine.routine.followUpDays;
  final started = routine.startedAt ?? routine.skinAnalysis.createdAt;
  if (started == null) {
    return 'Follow-up in $days days';
  }
  final passed = DateTime.now().difference(started.toLocal()).inDays;
  final left = (days - passed).clamp(0, days);
  return left == 0 ? 'Follow-up due now' : 'Follow-up in $left days';
}

String _concernSummary(SkinoText text, Set<String> concerns) {
  return concerns.take(2).map(text.concernLabel).join(', ');
}

class _CareEmptyState extends StatelessWidget {
  const _CareEmptyState({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.assetIcon,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String? assetIcon;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFFFE3D1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Align(
            alignment: Alignment.center,
            child: CircleAvatar(
              radius: 28,
              backgroundColor: const Color(0xFFFFE3D1),
              child: assetIcon == null
                  ? Icon(icon, color: const Color(0xFFF98128))
                  : SkinoImageIcon(
                      asset: assetIcon!,
                      size: 44,
                      padding: 3,
                      backgroundColor: Colors.transparent,
                      borderRadius: 16,
                    ),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF282420),
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF68625B),
              fontWeight: FontWeight.w500,
              height: 1.4,
            ),
          ),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 14),
            FilledButton.icon(
              onPressed: onAction,
              icon: const Icon(Icons.center_focus_strong_rounded),
              label: Text(actionLabel!),
            ),
          ],
        ],
      ),
    );
  }
}

class _ScanHistoryPage extends StatelessWidget {
  const _ScanHistoryPage({
    required this.text,
    required this.scanHistory,
    required this.latestResult,
    required this.activeRoutine,
    required this.isSavedHistory,
    required this.isGuest,
    required this.session,
    required this.isLoading,
    required this.appointmentRequestMessage,
    required this.onRequestAppointment,
    required this.onStartRoutine,
    required this.onOpenHome,
    required this.onOpenScan,
    required this.onOpenSettings,
    required this.onOpenSpecialist,
    required this.onOpenCare,
    required this.onOpenHelpSafety,
    required this.onStartScan,
    required this.onNewScan,
    required this.onDeleteScan,
    required this.onLogout,
  });

  final SkinoText text;
  final List<SkinAnalysisResult> scanHistory;
  final SkinAnalysisResult? latestResult;
  final ActiveRoutine? activeRoutine;
  final bool isSavedHistory;
  final bool isGuest;
  final AuthSession? session;
  final bool isLoading;
  final String? appointmentRequestMessage;
  final Future<void> Function(AppointmentRequestDraft draft)
  onRequestAppointment;
  final Future<void> Function(SkinAnalysisResult result) onStartRoutine;
  final VoidCallback onOpenHome;
  final VoidCallback onOpenScan;
  final VoidCallback onOpenSettings;
  final VoidCallback onOpenSpecialist;
  final VoidCallback onOpenCare;
  final VoidCallback onOpenHelpSafety;
  final VoidCallback onStartScan;
  final VoidCallback onNewScan;
  final Future<void> Function(SkinAnalysisResult result) onDeleteScan;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    final visibleScans = scanHistory.isEmpty && latestResult != null
        ? [latestResult!]
        : scanHistory;
    var selectedFilter = _ScanHistoryFilter.all;

    return Scaffold(
      backgroundColor: const Color(0xFFFBF9F4),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFBF9F4),
        foregroundColor: const Color(0xFF282420),
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu_rounded),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        title: Text(text.analysisHistory),
      ),
      drawer: _PageNavigationDrawer(
        text: text,
        session: session,
        onOpenHome: onOpenHome,
        onOpenScan: onOpenScan,
        onOpenSettings: onOpenSettings,
        onOpenSpecialist: onOpenSpecialist,
        onOpenCare: onOpenCare,
        onOpenScanHistory: null,
        onOpenHelpSafety: onOpenHelpSafety,
        onLogout: onLogout,
      ),
      body: StatefulBuilder(
        builder: (context, setFilterState) {
          final filteredScans = _filteredScanHistory(
            visibleScans,
            selectedFilter,
            activeRoutine,
          );

          return _PageScaffold(
            children: [
              _PageTitle(
                title: text.analysisHistory,
                subtitle: isSavedHistory
                    ? (text.isMyanmar
                          ? 'သိမ်းထားသော scan များကို ရက်စွဲ၊ score နှင့် routine ဖြင့်ကြည့်ပါ။'
                          : 'Review saved scans with date, score, and routine plan.')
                    : (text.isMyanmar
                          ? 'Scan history သိမ်းရန် Login ဝင်ပါ။'
                          : 'Login to save scan history across devices.'),
              ),
              const SizedBox(height: 14),
              if (visibleScans.isNotEmpty) ...[
                _ScanHistoryFilterBar(
                  selected: selectedFilter,
                  onSelected: (filter) =>
                      setFilterState(() => selectedFilter = filter),
                ),
                const SizedBox(height: 12),
              ],
              if (visibleScans.isEmpty)
                _CareEmptyState(
                  icon: Icons.history_rounded,
                  assetIcon: SkinoAssets.iconHistory,
                  title: text.isMyanmar
                      ? 'Scan history မရှိသေးပါ'
                      : 'No scan history yet',
                  subtitle: text.isMyanmar
                      ? 'ပထမဆုံး scan လုပ်ပြီးနောက် result ကို ဒီနေရာမှာပြပါမယ်။'
                      : 'Run your first scan and Skino will show the result here.',
                  actionLabel: text.startScan,
                  onAction: onStartScan,
                )
              else if (filteredScans.isEmpty)
                _CareEmptyState(
                  icon: Icons.filter_alt_off_outlined,
                  title: 'No scans in this filter',
                  subtitle: 'Try another filter or take a new scan.',
                )
              else
                for (final entry in filteredScans.asMap().entries) ...[
                  _ScanHistoryCard(
                    text: text,
                    result: entry.value,
                    index: entry.key,
                    isActiveRoutineSource:
                        activeRoutine?.skinAnalysisId == entry.value.id,
                    isFollowUpScan: _isFollowUpScan(
                      activeRoutine?.skinAnalysis,
                      entry.value,
                    ),
                    onDelete: () => onDeleteScan(entry.value),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => _ResultPage(
                          text: text,
                          result: entry.value,
                          isGuest: isGuest,
                          session: session,
                          isLoading: isLoading,
                          appointmentRequestMessage: appointmentRequestMessage,
                          onRequestAppointment: onRequestAppointment,
                          onStartRoutine: onStartRoutine,
                          onOpenCare: onOpenCare,
                          activeRoutine: activeRoutine,
                          routineIsActive:
                              activeRoutine?.skinAnalysisId == entry.value.id,
                          onNewScan: onNewScan,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
            ],
          );
        },
      ),
    );
  }
}

enum _ScanHistoryFilter { all, routineSource, badScan, followUp }

List<SkinAnalysisResult> _filteredScanHistory(
  List<SkinAnalysisResult> scans,
  _ScanHistoryFilter filter,
  ActiveRoutine? activeRoutine,
) {
  return scans.where((scan) {
    return switch (filter) {
      _ScanHistoryFilter.all => true,
      _ScanHistoryFilter.routineSource =>
        activeRoutine?.skinAnalysisId == scan.id,
      _ScanHistoryFilter.badScan => scan.scanQuality?.needsRetake ?? false,
      _ScanHistoryFilter.followUp => _isFollowUpScan(
        activeRoutine?.skinAnalysis,
        scan,
      ),
    };
  }).toList();
}

class _ScanHistoryFilterBar extends StatelessWidget {
  const _ScanHistoryFilterBar({
    required this.selected,
    required this.onSelected,
  });

  final _ScanHistoryFilter selected;
  final ValueChanged<_ScanHistoryFilter> onSelected;

  @override
  Widget build(BuildContext context) {
    final items = [
      (_ScanHistoryFilter.all, 'All'),
      (_ScanHistoryFilter.routineSource, 'Routine source'),
      (_ScanHistoryFilter.badScan, 'Bad scan'),
      (_ScanHistoryFilter.followUp, 'Follow-up'),
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final item in items)
          ChoiceChip(
            label: Text(item.$2),
            selected: selected == item.$1,
            onSelected: (_) => onSelected(item.$1),
            selectedColor: const Color(0xFFFFE3D1),
            backgroundColor: Colors.white,
            checkmarkColor: const Color(0xFFF98128),
            labelStyle: TextStyle(
              color: selected == item.$1
                  ? const Color(0xFF8A3A08)
                  : const Color(0xFF625B53),
              fontWeight: FontWeight.w800,
              fontSize: 12,
            ),
            side: BorderSide(
              color: selected == item.$1
                  ? const Color(0xFFF98128)
                  : const Color(0xFFFFE3D1),
            ),
          ),
      ],
    );
  }
}

class _ScanHistoryCard extends StatelessWidget {
  const _ScanHistoryCard({
    required this.text,
    required this.result,
    required this.index,
    required this.isActiveRoutineSource,
    required this.isFollowUpScan,
    required this.onDelete,
    required this.onTap,
  });

  final SkinoText text;
  final SkinAnalysisResult result;
  final int index;
  final bool isActiveRoutineSource;
  final bool isFollowUpScan;
  final Future<void> Function() onDelete;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final label = index == 0
        ? text.latestScan
        : text.isMyanmar
        ? 'နှိုင်းယှဉ်စကင် ${index + 1}'
        : 'Compare scan ${index + 1}';
    final scanId = result.id == null
        ? (text.isMyanmar ? 'Guest scan' : 'Guest scan')
        : 'Scan #${result.id}';
    final createdAt = _formatScanTimestamp(result.createdAt);
    final routineName = result.treatmentPackage?.name ?? text.calmRoutine;
    final isBadScan = result.scanQuality?.needsRetake ?? false;

    return Dismissible(
      key: ValueKey(
        'scan-history-${result.id ?? result.createdAt?.toIso8601String() ?? 'local'}-$index',
      ),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 22),
        decoration: BoxDecoration(
          color: const Color(0xFFFFE9E9),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: const Color(0xFFFFC9C9)),
        ),
        child: const Icon(
          Icons.delete_outline_rounded,
          color: Color(0xFF9E2732),
        ),
      ),
      confirmDismiss: (_) => _confirmAndDelete(context),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.96),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFFFE3D1)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _ScoreBubble(score: result.skinHealthScore),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          label,
                          style: const TextStyle(
                            color: Color(0xFF282420),
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '$scanId  •  $createdAt',
                          style: const TextStyle(
                            color: Color(0xFF0E5C56),
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 3),
                        if (isActiveRoutineSource) ...[
                          _StatusPill(
                            label: text.isMyanmar
                                ? 'Active routine'
                                : 'Active routine',
                            color: const Color(0xFFF98128),
                          ),
                          const SizedBox(height: 6),
                        ],
                        if (isBadScan) ...[
                          _StatusPill(
                            label: text.isMyanmar ? 'Bad scan' : 'Bad scan',
                            color: const Color(0xFF9E2732),
                          ),
                          const SizedBox(height: 6),
                        ],
                        if (isFollowUpScan) ...[
                          _StatusPill(
                            label: text.isMyanmar ? 'Follow-up' : 'Follow-up',
                            color: const Color(0xFF0E5C56),
                          ),
                          const SizedBox(height: 6),
                        ],
                        Text(
                          text.isMyanmar
                              ? '${text.concernLabel(result.skinType)} • acne ${text.severityLabel(result.acneSeverity)}'
                              : '${text.concernLabel(result.skinType)} • ${text.severityLabel(result.acneSeverity)} acne',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xFF68625B),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: text.isMyanmar ? 'ဖျက်မယ်' : 'Delete scan',
                    onPressed: () => _confirmAndDelete(context),
                    icon: Icon(
                      isActiveRoutineSource
                          ? Icons.lock_outline_rounded
                          : Icons.delete_outline_rounded,
                    ),
                    color: isActiveRoutineSource
                        ? const Color(0xFFB8B0A7)
                        : const Color(0xFF9E2732),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF6F1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFCCE7DE)),
                ),
                child: Row(
                  children: [
                    const SkinoImageIcon(
                      asset: SkinoAssets.iconProgress,
                      size: 22,
                      padding: 1,
                      backgroundColor: Colors.transparent,
                      borderRadius: 8,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        routineName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFF0E5C56),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (result.concerns.isNotEmpty) ...[
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: result.concerns
                      .take(3)
                      .map(
                        (concern) => _SmallInfoChip(
                          label:
                              '${text.concernLabel(concern.name)} ${(concern.confidence * 100).round()}%',
                        ),
                      )
                      .toList(),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<bool> _confirmAndDelete(BuildContext context) async {
    if (isActiveRoutineSource) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            text.isMyanmar
                ? 'ဒီ scan က active routine source ဖြစ်နေသောကြောင့် မဖျက်နိုင်သေးပါ။'
                : 'This scan is used by your active routine, so stop or replace the routine first.',
          ),
        ),
      );
      return false;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(text.isMyanmar ? 'Scan ဖျက်မလား?' : 'Delete scan?'),
        content: Text(
          text.isMyanmar
              ? 'ဒီ scan history ကို ဖျက်ပြီးပါက ပြန်ယူမရပါ။'
              : 'This scan history item will be removed permanently.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(text.isMyanmar ? 'မဖျက်ပါ' : 'Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF9E2732),
              foregroundColor: Colors.white,
            ),
            child: Text(text.isMyanmar ? 'ဖျက်မယ်' : 'Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) {
      return false;
    }

    await onDelete();
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            text.isMyanmar ? 'Scan history ဖျက်ပြီးပါပြီ။' : 'Scan deleted.',
          ),
        ),
      );
    }
    return true;
  }
}

class _HelpSafetyPage extends StatelessWidget {
  const _HelpSafetyPage({
    required this.text,
    required this.session,
    required this.onOpenHome,
    required this.onOpenScan,
    required this.onOpenSettings,
    required this.onOpenSpecialist,
    required this.onOpenCare,
    required this.onOpenScanHistory,
    required this.onLogout,
  });

  final SkinoText text;
  final AuthSession? session;
  final VoidCallback onOpenHome;
  final VoidCallback onOpenScan;
  final VoidCallback onOpenSettings;
  final VoidCallback onOpenSpecialist;
  final VoidCallback onOpenCare;
  final VoidCallback onOpenScanHistory;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFBF9F4),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFBF9F4),
        foregroundColor: const Color(0xFF282420),
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu_rounded),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        title: Text(text.helpSafety),
      ),
      drawer: _PageNavigationDrawer(
        text: text,
        session: session,
        onOpenHome: onOpenHome,
        onOpenScan: onOpenScan,
        onOpenSettings: onOpenSettings,
        onOpenSpecialist: onOpenSpecialist,
        onOpenCare: onOpenCare,
        onOpenScanHistory: onOpenScanHistory,
        onOpenHelpSafety: () {},
        onLogout: onLogout,
      ),
      body: _PageScaffold(
        children: [
          const _PageTitle(
            title: 'Help / Safety',
            subtitle: 'Use Skino as guidance, not as a medical diagnosis.',
          ),
          const SizedBox(height: 14),
          const _SafetyTipCard(
            icon: Icons.privacy_tip_outlined,
            title: 'Face scan privacy',
            subtitle:
                'Keep face photos, skin records, and notes private unless the user gives permission.',
          ),
          const SizedBox(height: 12),
          const _SafetyTipCard(
            icon: Icons.medical_services_outlined,
            assetIcon: SkinoAssets.iconSpecialist,
            title: 'Specialist care',
            subtitle:
                'Painful, spreading, severe, or uncertain skin concerns should be reviewed by a specialist.',
          ),
          const SizedBox(height: 12),
          const _SafetyTipCard(
            icon: Icons.spa_outlined,
            assetIcon: SkinoAssets.iconRoutine,
            title: 'Gentle routine first',
            subtitle:
                'Routine suggestions should stay simple and avoid aggressive product mixing.',
          ),
        ],
      ),
    );
  }
}

String _formatScanTimestamp(DateTime? value) {
  if (value == null) {
    return 'Just now';
  }

  final local = value.toLocal();
  final hour = local.hour == 0
      ? 12
      : local.hour > 12
      ? local.hour - 12
      : local.hour;
  final minute = local.minute.toString().padLeft(2, '0');
  final period = local.hour >= 12 ? 'PM' : 'AM';

  return '${local.year}-${local.month.toString().padLeft(2, '0')}-${local.day.toString().padLeft(2, '0')} $hour:$minute $period';
}

class _SafetyTipCard extends StatelessWidget {
  const _SafetyTipCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.assetIcon,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String? assetIcon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFFFE3D1)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: const Color(0xFFEAF6F1),
            child: assetIcon == null
                ? Icon(icon, color: const Color(0xFF0E5C56))
                : SkinoImageIcon(
                    asset: assetIcon!,
                    size: 34,
                    padding: 2,
                    backgroundColor: Colors.transparent,
                    borderRadius: 12,
                  ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xFF282420),
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: Color(0xFF68625B),
                    fontWeight: FontWeight.w500,
                    height: 1.4,
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

class _MiniScanSummary extends StatelessWidget {
  const _MiniScanSummary({required this.text, required this.result});

  final SkinoText text;
  final SkinAnalysisResult result;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _ScoreBubble(score: result.skinHealthScore),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text.isMyanmar
                ? '${text.concernLabel(result.skinType)} skin, acne ${text.severityLabel(result.acneSeverity)}'
                : '${text.concernLabel(result.skinType)} skin, ${text.severityLabel(result.acneSeverity)} acne',
            style: const TextStyle(
              color: Color(0xFF625B53),
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}

class _ScoreBubble extends StatelessWidget {
  const _ScoreBubble({required this.score});

  final int score;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 54,
      height: 54,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: const Color(0xFF0E5C56),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Text(
        '$score',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _SmallInfoChip extends StatelessWidget {
  const _SmallInfoChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3EC),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Color(0xFF625B53),
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

List<String> _morningRoutineSteps(SkinAnalysisResult result) {
  final steps = result.treatmentPackage?.steps ?? const <String>[];

  if (steps.isEmpty) {
    return const ['Gentle cleanse', 'Light moisturizer', 'Apply sunscreen'];
  }

  return steps.map(_titleCase).toList(growable: false);
}

List<String> _nightRoutineSteps(SkinAnalysisResult result) {
  final sourceSteps = result.treatmentPackage?.steps ?? const <String>[];
  final nightSteps = sourceSteps
      .where((step) => !step.toLowerCase().contains('sunscreen'))
      .map(_titleCase)
      .toList();

  if (nightSteps.isEmpty) {
    return const ['Gentle cleanse', 'Barrier moisturizer'];
  }

  if (!nightSteps.any((step) => step.toLowerCase().contains('clean'))) {
    nightSteps.insert(0, 'Gentle Cleanser');
  }

  return nightSteps;
}

class _SpecialistDirectoryPage extends StatelessWidget {
  const _SpecialistDirectoryPage({
    required this.text,
    required this.result,
    required this.activeRoutine,
    required this.isGuest,
    required this.session,
    required this.isLoading,
    required this.message,
    required this.onSubmit,
    required this.onOpenHome,
    required this.onOpenScan,
    required this.onOpenSettings,
    required this.onOpenCare,
    required this.onOpenScanHistory,
    required this.onOpenHelpSafety,
    required this.onLogout,
  });

  final SkinoText text;
  final SkinAnalysisResult? result;
  final ActiveRoutine? activeRoutine;
  final bool isGuest;
  final AuthSession? session;
  final bool isLoading;
  final String? message;
  final Future<void> Function(AppointmentRequestDraft draft) onSubmit;
  final VoidCallback onOpenHome;
  final VoidCallback onOpenScan;
  final VoidCallback onOpenSettings;
  final VoidCallback onOpenCare;
  final VoidCallback onOpenScanHistory;
  final VoidCallback onOpenHelpSafety;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    final specialists = _specialistProfiles();

    return Scaffold(
      backgroundColor: const Color(0xFFFBF9F4),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFBF9F4),
        foregroundColor: const Color(0xFF282420),
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu_rounded),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        title: Text(
          text.specialistDirectoryTitle,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
      ),
      drawer: _PageNavigationDrawer(
        text: text,
        session: session,
        onOpenHome: onOpenHome,
        onOpenScan: onOpenScan,
        onOpenSettings: onOpenSettings,
        onOpenSpecialist: () {},
        onOpenCare: onOpenCare,
        onOpenScanHistory: onOpenScanHistory,
        onOpenHelpSafety: onOpenHelpSafety,
        onLogout: onLogout,
      ),
      body: _PageScaffold(
        children: [
          _PageTitle(
            title: text.specialistDirectoryTitle,
            subtitle: text.specialistDirectorySubtitle,
          ),
          const SizedBox(height: 14),
          for (final specialist in specialists) ...[
            _SpecialistProfileCard(
              text: text,
              specialist: specialist,
              onChoose: () {
                final latestResult = result;
                if (latestResult == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(text.specialistNeedsScan),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                  return;
                }

                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => _AppointmentPage(
                      text: text,
                      result: latestResult,
                      isGuest: isGuest,
                      session: session,
                      isLoading: isLoading,
                      message: message,
                      selectedSpecialist: specialist,
                      activeRoutine: activeRoutine,
                      onSubmit: onSubmit,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }
}

class _SpecialistProfile {
  const _SpecialistProfile({
    required this.name,
    required this.role,
    required this.schedule,
    required this.accent,
  });

  final String name;
  final String role;
  final String schedule;
  final Color accent;
}

class _SpecialistProfileCard extends StatelessWidget {
  const _SpecialistProfileCard({
    required this.text,
    required this.specialist,
    required this.onChoose,
  });

  final SkinoText text;
  final _SpecialistProfile specialist;
  final VoidCallback onChoose;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFFFE3D1)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x10123C36),
            blurRadius: 18,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 26,
                backgroundColor: specialist.accent.withValues(alpha: 0.14),
                child: const SkinoImageIcon(
                  asset: SkinoAssets.iconSpecialist,
                  size: 42,
                  padding: 3,
                  backgroundColor: Colors.transparent,
                  borderRadius: 16,
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      specialist.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF282420),
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      specialist.role,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF625B53),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFEAF6F1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.event_available_outlined,
                  color: Color(0xFF0E5C56),
                  size: 18,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    specialist.schedule,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF0E5C56),
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton.tonalIcon(
              onPressed: onChoose,
              icon: const Icon(Icons.calendar_month_rounded),
              label: Text(text.chooseSpecialist),
            ),
          ),
        ],
      ),
    );
  }
}

List<_SpecialistProfile> _specialistProfiles() {
  return const [
    _SpecialistProfile(
      name: 'Dr. May Thandar',
      role: 'Acne and sensitive skin',
      schedule: 'Mon, Wed, Fri',
      accent: Color(0xFFF98128),
    ),
    _SpecialistProfile(
      name: 'Dr. Htet Aung',
      role: 'Dark spots and texture',
      schedule: 'Tue, Thu',
      accent: Color(0xFF0E5C56),
    ),
    _SpecialistProfile(
      name: 'Dr. Ei Mon',
      role: 'Routine review',
      schedule: 'Weekend follow-up',
      accent: Color(0xFF7A8F72),
    ),
  ];
}

class _SelectedSpecialistPanel extends StatelessWidget {
  const _SelectedSpecialistPanel({
    required this.specialists,
    required this.selectedName,
    required this.onSelected,
  });

  final List<_SpecialistProfile> specialists;
  final String selectedName;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    final selected = specialists.firstWhere(
      (item) => item.name == selectedName,
      orElse: () => specialists.first,
    );

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF6F1),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: selected.accent.withValues(alpha: 0.16),
                child: const SkinoImageIcon(
                  asset: SkinoAssets.iconSpecialist,
                  size: 32,
                  padding: 2,
                  backgroundColor: Colors.transparent,
                  borderRadius: 12,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      selected.name,
                      style: const TextStyle(
                        color: Color(0xFF123C36),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      selected.role,
                      style: const TextStyle(
                        color: Color(0xFF625B53),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final specialist in specialists)
                ChoiceChip(
                  label: Text(specialist.name.replaceFirst('Dr. ', '')),
                  selected: selectedName == specialist.name,
                  onSelected: (_) => onSelected(specialist.name),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AppointmentPage extends StatelessWidget {
  const _AppointmentPage({
    required this.text,
    required this.result,
    required this.isGuest,
    required this.session,
    required this.isLoading,
    required this.message,
    required this.selectedSpecialist,
    required this.activeRoutine,
    required this.onSubmit,
  });

  final SkinoText text;
  final SkinAnalysisResult result;
  final bool isGuest;
  final AuthSession? session;
  final bool isLoading;
  final String? message;
  final _SpecialistProfile? selectedSpecialist;
  final ActiveRoutine? activeRoutine;
  final Future<void> Function(AppointmentRequestDraft draft) onSubmit;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFBF9F4),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFBF9F4),
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(text.appointmentTitle),
      ),
      body: _PageScaffold(
        children: [
          _PageTitle(
            title: text.appointmentTitle,
            subtitle: text.appointmentSubtitle,
          ),
          const SizedBox(height: 14),
          _AppointmentRequestCard(
            text: text,
            result: result,
            isGuest: isGuest,
            session: session,
            isLoading: isLoading,
            message: message,
            selectedSpecialist: selectedSpecialist,
            activeRoutine: activeRoutine,
            onSubmit: onSubmit,
          ),
        ],
      ),
    );
  }
}

class _AppointmentRequestCard extends StatefulWidget {
  const _AppointmentRequestCard({
    required this.text,
    required this.result,
    required this.isGuest,
    required this.session,
    required this.isLoading,
    required this.message,
    required this.selectedSpecialist,
    required this.activeRoutine,
    required this.onSubmit,
  });

  final SkinoText text;
  final SkinAnalysisResult result;
  final bool isGuest;
  final AuthSession? session;
  final bool isLoading;
  final String? message;
  final _SpecialistProfile? selectedSpecialist;
  final ActiveRoutine? activeRoutine;
  final Future<void> Function(AppointmentRequestDraft draft) onSubmit;

  @override
  State<_AppointmentRequestCard> createState() =>
      _AppointmentRequestCardState();
}

class _AppointmentRequestCardState extends State<_AppointmentRequestCard> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _goalController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  String _contactMethod = 'phone';
  late String _selectedSpecialistName;
  late SkinAnalysisResult _selectedScan;
  DateTime? _preferredDate;

  @override
  void initState() {
    super.initState();
    _selectedSpecialistName =
        widget.selectedSpecialist?.name ?? _specialistProfiles().first.name;
    _selectedScan = widget.result;
    _syncSignedInUser();
    _goalController.text = switch (widget.result.acneSeverity) {
      'severe' || 'moderate' => widget.text.appointmentGoalAcne,
      _ => widget.text.appointmentGoalRoutine,
    };
  }

  @override
  void didUpdateWidget(covariant _AppointmentRequestCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.session?.user.id != widget.session?.user.id) {
      _syncSignedInUser();
    }
    if (oldWidget.result.id != widget.result.id) {
      _selectedScan = widget.result;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _goalController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _syncSignedInUser() {
    final user = widget.session?.user;

    if (user == null) {
      return;
    }

    _nameController.text = user.name;
    _emailController.text = user.email;
    _contactMethod = 'in_app';
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final hasContact =
        _phoneController.text.trim().isNotEmpty ||
        _emailController.text.trim().isNotEmpty ||
        !widget.isGuest;

    if (!hasContact) {
      _showValidation(widget.text.appointmentContactRequired);
      return;
    }

    await widget.onSubmit(
      AppointmentRequestDraft(
        name: _nameController.text,
        email: _emailController.text,
        phone: _phoneController.text,
        preferredContactMethod: _contactMethod,
        beautyGoal: _goalController.text,
        notes: _notesController.text,
        result: _selectedScan,
        preferredDate: _preferredDate,
        requestedSpecialist: _selectedSpecialistName,
      ),
    );
  }

  Future<void> _pickPreferredDate() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: _preferredDate ?? now.add(const Duration(days: 1)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 45)),
    );

    if (!mounted || date == null) {
      return;
    }

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_preferredDate ?? now),
    );

    if (!mounted) {
      return;
    }

    setState(() {
      _preferredDate = DateTime(
        date.year,
        date.month,
        date.day,
        time?.hour ?? 9,
        time?.minute ?? 0,
      );
    });
  }

  void _clearPreferredDate() {
    setState(() => _preferredDate = null);
  }

  String _preferredDateLabel() {
    final date = _preferredDate;
    if (date == null) {
      return widget.text.appointmentAnyTime;
    }

    final material = MaterialLocalizations.of(context);
    final day = material.formatMediumDate(date);
    final time = material.formatTimeOfDay(TimeOfDay.fromDateTime(date));

    return '$day, $time';
  }

  String? _validateGuestName(String? value) {
    if (!widget.isGuest) {
      return null;
    }
    if ((value ?? '').trim().isEmpty) {
      return widget.text.appointmentNameRequired;
    }
    return null;
  }

  String? _validateEmail(String? value) {
    final email = (value ?? '').trim();
    if (email.isEmpty) {
      return null;
    }
    final isEmail = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email);
    return isEmail ? null : widget.text.appointmentEmailInvalid;
  }

  void _showValidation(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEscalation = [
      'moderate',
      'severe',
    ].contains(_selectedScan.acneSeverity.toLowerCase());

    final text = widget.text;

    return Form(
      key: _formKey,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.96),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: const Color(0xFFFFD0B3)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x14123C36),
              blurRadius: 20,
              offset: Offset(0, 12),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: isEscalation
                      ? const Color(0xFFF98128)
                      : const Color(0xFF0E5C56),
                  child: const Icon(
                    Icons.calendar_month_rounded,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        text.appointmentCardTitle,
                        style: const TextStyle(
                          color: Color(0xFF282420),
                          fontWeight: FontWeight.w500,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        text.appointmentCardSubtitle,
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
            const SizedBox(height: 14),
            _AppointmentScanSourcePicker(
              text: text,
              selectedScan: _selectedScan,
              latestScan: widget.result,
              activeRoutine: widget.activeRoutine,
              onSelected: (scan) => setState(() => _selectedScan = scan),
            ),
            const SizedBox(height: 10),
            _SelectedSpecialistPanel(
              specialists: _specialistProfiles(),
              selectedName: _selectedSpecialistName,
              onSelected: (name) =>
                  setState(() => _selectedSpecialistName = name),
            ),
            const SizedBox(height: 14),
            if (widget.isGuest) ...[
              _AppointmentTextField(
                controller: _nameController,
                label: text.appointmentName,
                icon: Icons.person_outline_rounded,
                validator: _validateGuestName,
              ),
              const SizedBox(height: 10),
            ],
            _AppointmentTextField(
              controller: _phoneController,
              label: text.appointmentPhone,
              icon: Icons.phone_outlined,
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 10),
            _AppointmentTextField(
              controller: _emailController,
              label: text.appointmentEmail,
              icon: Icons.mail_outline_rounded,
              keyboardType: TextInputType.emailAddress,
              validator: _validateEmail,
            ),
            const SizedBox(height: 10),
            _AppointmentOptionBlock(
              label: text.appointmentPreferredContact,
              icon: Icons.forum_outlined,
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final option in [
                    'phone',
                    'email',
                    'viber',
                    'telegram',
                    'in_app',
                  ])
                    ChoiceChip(
                      label: Text(text.appointmentContactMethod(option)),
                      selected: _contactMethod == option,
                      onSelected: widget.isLoading
                          ? null
                          : (_) => setState(() => _contactMethod = option),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            _AppointmentOptionBlock(
              label: text.appointmentPreferredTime,
              icon: Icons.event_available_outlined,
              child: Row(
                children: [
                  Expanded(child: Text(_preferredDateLabel())),
                  TextButton(
                    onPressed: widget.isLoading ? null : _pickPreferredDate,
                    child: Text(text.appointmentPickTime),
                  ),
                  if (_preferredDate != null)
                    IconButton(
                      tooltip: text.appointmentClearTime,
                      onPressed: widget.isLoading ? null : _clearPreferredDate,
                      icon: const Icon(Icons.close_rounded),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final goal in [
                  text.appointmentGoalAcne,
                  text.appointmentGoalRoutine,
                  text.appointmentGoalDarkSpots,
                ])
                  ChoiceChip(
                    label: Text(goal),
                    selected: _goalController.text == goal,
                    onSelected: widget.isLoading
                        ? null
                        : (_) => setState(() => _goalController.text = goal),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            _AppointmentTextField(
              controller: _goalController,
              label: text.appointmentBeautyGoal,
              icon: Icons.spa_outlined,
            ),
            const SizedBox(height: 10),
            _AppointmentTextField(
              controller: _notesController,
              label: text.appointmentNotes,
              icon: Icons.notes_rounded,
              maxLines: 3,
            ),
            if (widget.message != null) ...[
              const SizedBox(height: 12),
              _AppointmentSuccess(message: widget.message!),
            ],
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: widget.isLoading ? null : _submit,
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF0E5C56),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                icon: widget.isLoading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.send_rounded),
                label: Text(
                  text.appointmentSubmit,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AppointmentScanSummary extends StatelessWidget {
  const _AppointmentScanSummary({required this.text, required this.result});

  final SkinoText text;
  final SkinAnalysisResult result;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3EC),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Icon(Icons.fact_check_outlined, color: Color(0xFFF98128)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text.appointmentScanSummary(
                score: result.skinHealthScore,
                skinType: result.skinType,
                severity: result.acneSeverity,
              ),
              style: const TextStyle(
                color: Color(0xFF625B53),
                fontWeight: FontWeight.w500,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AppointmentScanSourcePicker extends StatelessWidget {
  const _AppointmentScanSourcePicker({
    required this.text,
    required this.selectedScan,
    required this.latestScan,
    required this.activeRoutine,
    required this.onSelected,
  });

  final SkinoText text;
  final SkinAnalysisResult selectedScan;
  final SkinAnalysisResult latestScan;
  final ActiveRoutine? activeRoutine;
  final ValueChanged<SkinAnalysisResult> onSelected;

  @override
  Widget build(BuildContext context) {
    final routineScan = activeRoutine?.skinAnalysis;
    final hasDifferentRoutineScan =
        routineScan != null && routineScan.id != latestScan.id;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (hasDifferentRoutineScan) ...[
          Text(
            text.isMyanmar
                ? 'Appointment အတွက် scan source ရွေးပါ'
                : 'Choose scan for appointment',
            style: const TextStyle(
              color: Color(0xFF282420),
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ChoiceChip(
                label: Text(
                  latestScan.id == null
                      ? 'Latest scan'
                      : 'Latest Scan #${latestScan.id}',
                ),
                selected: selectedScan.id == latestScan.id,
                onSelected: (_) => onSelected(latestScan),
              ),
              ChoiceChip(
                label: Text('Active routine Scan #${routineScan.id ?? '--'}'),
                selected: selectedScan.id == routineScan.id,
                onSelected: (_) => onSelected(routineScan),
              ),
            ],
          ),
          const SizedBox(height: 10),
        ],
        _AppointmentScanSummary(text: text, result: selectedScan),
      ],
    );
  }
}

class _AppointmentTextField extends StatelessWidget {
  const _AppointmentTextField({
    required this.controller,
    required this.label,
    required this.icon,
    this.keyboardType,
    this.maxLines = 1,
    this.validator,
  });

  final TextEditingController controller;
  final String label;
  final IconData icon;
  final TextInputType? keyboardType;
  final int maxLines;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      validator: validator,
      decoration: _fieldDecoration(label, icon),
    );
  }
}

class _AppointmentOptionBlock extends StatelessWidget {
  const _AppointmentOptionBlock({
    required this.label,
    required this.icon,
    required this.child,
  });

  final String label;
  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return InputDecorator(
      decoration: _fieldDecoration(label, icon),
      child: child,
    );
  }
}

class _AppointmentSuccess extends StatelessWidget {
  const _AppointmentSuccess({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF6F1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle_rounded, color: Color(0xFF0E5C56)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: Color(0xFF123C36),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

InputDecoration _fieldDecoration(String label, IconData icon) {
  return InputDecoration(
    labelText: label,
    prefixIcon: Icon(icon),
    filled: true,
    fillColor: const Color(0xFFFBF9F4),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: Color(0xFFE8E1D7)),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: Color(0xFFE8E1D7)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: Color(0xFF0E5C56), width: 1.5),
    ),
  );
}

class _NextScanReminderCard extends StatefulWidget {
  const _NextScanReminderCard({required this.text});

  final SkinoText text;

  @override
  State<_NextScanReminderCard> createState() => _NextScanReminderCardState();
}

class _NextScanReminderCardState extends State<_NextScanReminderCard> {
  static const _enabledKey = 'skino.next_scan_reminder.enabled';
  static const _daysKey = 'skino.next_scan_reminder.days';

  bool _enabled = true;
  int _days = 14;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) {
      return;
    }
    setState(() {
      _enabled = prefs.getBool(_enabledKey) ?? true;
      _days = prefs.getInt(_daysKey) ?? 14;
      _loaded = true;
    });
  }

  Future<void> _save({bool? enabled, int? days}) async {
    final nextEnabled = enabled ?? _enabled;
    final nextDays = days ?? _days;
    setState(() {
      _enabled = nextEnabled;
      _days = nextDays;
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_enabledKey, nextEnabled);
    await prefs.setInt(_daysKey, nextDays);
  }

  @override
  Widget build(BuildContext context) {
    final text = widget.text;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFFFE3D1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const CircleAvatar(
                backgroundColor: Color(0xFFEAF6F1),
                child: Icon(
                  Icons.event_repeat_rounded,
                  color: Color(0xFF0E5C56),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      text.isMyanmar
                          ? 'Next scan reminder'
                          : 'Next scan reminder',
                      style: const TextStyle(
                        color: Color(0xFF282420),
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      text.isMyanmar
                          ? 'Routine progress အတွက် follow-up scan ကို သတိပေးမယ်။'
                          : 'Remind you when it is time for a follow-up scan.',
                      style: const TextStyle(
                        color: Color(0xFF68625B),
                        fontWeight: FontWeight.w500,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: _enabled,
                onChanged: _loaded ? (value) => _save(enabled: value) : null,
                activeThumbColor: const Color(0xFFF98128),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final day in const [7, 14, 30])
                ChoiceChip(
                  label: Text('${day}d'),
                  selected: _days == day,
                  onSelected: _enabled && _loaded
                      ? (_) => _save(days: day)
                      : null,
                  selectedColor: const Color(0xFFFFE3D1),
                  labelStyle: TextStyle(
                    color: _days == day
                        ? const Color(0xFFF98128)
                        : const Color(0xFF68625B),
                    fontWeight: FontWeight.w800,
                  ),
                  side: BorderSide(
                    color: _days == day
                        ? const Color(0xFFFFD0B3)
                        : const Color(0xFFE8E1D7),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SimpleDataControlCard extends StatefulWidget {
  const _SimpleDataControlCard({required this.text, required this.enabled});

  final SkinoText text;
  final bool enabled;

  @override
  State<_SimpleDataControlCard> createState() => _SimpleDataControlCardState();
}

class _SimpleDataControlCardState extends State<_SimpleDataControlCard> {
  String? _message;

  Future<void> _resetLocalPreferences() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          widget.text.isMyanmar
              ? 'Local preferences reset?'
              : 'Reset local preferences?',
        ),
        content: Text(
          widget.text.isMyanmar
              ? 'Routine reminder နဲ့ next scan reminder setting များကို default ပြန်ထားမယ်။ Scan history မဖျက်ပါ။'
              : 'This resets routine and next scan reminder settings only. Scan history will not be deleted.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(widget.text.isMyanmar ? 'မလုပ်တော့ပါ' : 'Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(widget.text.isMyanmar ? 'Reset' : 'Reset'),
          ),
        ],
      ),
    );
    if (confirmed != true) {
      return;
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_NextScanReminderCardState._enabledKey);
    await prefs.remove(_NextScanReminderCardState._daysKey);
    await const RoutineReminderService().save(RoutineReminderSettings.defaults);
    if (!mounted) {
      return;
    }
    setState(() {
      _message = widget.text.isMyanmar
          ? 'Local preferences reset လုပ်ပြီးပါပြီ။'
          : 'Local preferences reset.';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE8E1D7)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const CircleAvatar(
                backgroundColor: Color(0xFFFFF3EC),
                child: Icon(
                  Icons.manage_accounts_outlined,
                  color: Color(0xFFF98128),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.text.dataControl,
                      style: const TextStyle(
                        color: Color(0xFF282420),
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      widget.text.isMyanmar
                          ? 'Local reminder/preference များကို ထိန်းချုပ်နိုင်ပါတယ်။'
                          : 'Manage local reminder and preference data.',
                      style: const TextStyle(
                        color: Color(0xFF68625B),
                        fontWeight: FontWeight.w500,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: widget.enabled ? _resetLocalPreferences : null,
              icon: const Icon(Icons.restart_alt_rounded),
              label: Text(
                widget.text.isMyanmar
                    ? 'Local preferences reset'
                    : 'Reset local preferences',
              ),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFF98128),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 13),
              ),
            ),
          ),
          if (_message != null) ...[
            const SizedBox(height: 8),
            Text(
              _message!,
              style: const TextStyle(
                color: Color(0xFF0E5C56),
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SettingsPage extends StatelessWidget {
  const _SettingsPage({
    required this.text,
    required this.language,
    required this.onLanguageChanged,
    required this.session,
    required this.baseUrlController,
    required this.isLoading,
    required this.error,
    required this.allowModelTraining,
    required this.privacySettingsLoaded,
    required this.onModelTrainingConsentChanged,
    required this.onSaveApiBaseUrl,
    required this.onLogin,
    required this.onGoogleLogin,
    required this.onLogout,
  });

  final SkinoText text;
  final AppLanguage language;
  final ValueChanged<AppLanguage> onLanguageChanged;
  final AuthSession? session;
  final TextEditingController baseUrlController;
  final bool isLoading;
  final String? error;
  final bool allowModelTraining;
  final bool privacySettingsLoaded;
  final Future<void> Function(bool granted) onModelTrainingConsentChanged;
  final Future<void> Function() onSaveApiBaseUrl;
  final Future<void> Function(String email, String password) onLogin;
  final Future<void> Function() onGoogleLogin;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    return _PageScaffold(
      children: [
        _PageTitle(title: text.settingsTitle, subtitle: text.settingsSubtitle),
        const SizedBox(height: 12),
        if (session != null) ...[
          ProfilePanel(user: session!.user),
          const SizedBox(height: 12),
        ],
        _LanguageToggle(
          text: text,
          language: language,
          onChanged: onLanguageChanged,
        ),
        const SizedBox(height: 12),
        if (session == null) ...[
          _GuestModeNotice(text: text),
          const SizedBox(height: 12),
          _ApiConnectionCard(
            baseUrlController: baseUrlController,
            enabled: !isLoading,
            onSave: onSaveApiBaseUrl,
          ),
          const SizedBox(height: 12),
          AuthCard(
            baseUrlController: baseUrlController,
            isLoading: isLoading,
            error: error,
            onLogin: onLogin,
            onGoogleLogin: onGoogleLogin,
          ),
        ] else ...[
          _ModelLearningPrivacyCard(
            text: text,
            enabled: !isLoading,
            isAllowed: allowModelTraining,
            isLoaded: privacySettingsLoaded,
            onChanged: onModelTrainingConsentChanged,
          ),
          const SizedBox(height: 12),
          _RoutineReminderCard(text: text),
          const SizedBox(height: 12),
          _NextScanReminderCard(text: text),
          const SizedBox(height: 12),
          _SimpleDataControlCard(text: text, enabled: !isLoading),
          const SizedBox(height: 12),
          _SettingsGroup(
            title: text.accountAccess,
            children: [
              _SettingsTile(
                icon: Icons.face_retouching_natural,
                assetIcon: SkinoAssets.resultMascot,
                title: text.skinProfile,
                subtitle: text.skinProfileSubtitle,
                trailingLabel: text.soon,
              ),
              _SettingsTile(
                icon: Icons.cloud_done_outlined,
                assetIcon: SkinoAssets.iconProgress,
                title: text.savedProgress,
                subtitle: text.savedProgressSubtitle,
                trailingLabel: text.ready,
              ),
            ],
          ),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: onLogout,
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF9E2732),
                side: const BorderSide(color: Color(0xFFFFC9C9)),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              icon: const Icon(Icons.logout_rounded),
              label: Text(text.logout),
            ),
          ),
        ],
      ],
    );
  }
}

class _ApiConnectionCard extends StatefulWidget {
  const _ApiConnectionCard({
    required this.baseUrlController,
    required this.enabled,
    required this.onSave,
  });

  final TextEditingController baseUrlController;
  final bool enabled;
  final Future<void> Function() onSave;

  @override
  State<_ApiConnectionCard> createState() => _ApiConnectionCardState();
}

class _ApiConnectionCardState extends State<_ApiConnectionCard> {
  String? _savedMessage;
  String? _testMessage;
  bool _isTesting = false;

  @override
  Widget build(BuildContext context) {
    final normalizedUrl = ApiConfig.normalizeBaseUrl(
      widget.baseUrlController.text,
    );
    final uri = Uri.tryParse(normalizedUrl);
    final isHttps = uri?.scheme == 'https';
    final isLocal = uri?.host == '127.0.0.1' || uri?.host == 'localhost';
    final isEmulator = uri?.host == '10.0.2.2';
    final isLan = _isPrivateLanHost(uri?.host);
    final status = isEmulator
        ? 'Android emulator'
        : isLocal
        ? 'Desktop local'
        : isLan
        ? 'Same Wi-Fi'
        : isHttps
        ? 'HTTPS API'
        : 'Check URL';
    final accent = isEmulator || isLocal || isLan || isHttps
        ? const Color(0xFF0E5C56)
        : const Color(0xFFF98128);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFFFE3D1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: accent.withValues(alpha: 0.14),
                child: Icon(Icons.link_rounded, color: accent),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'API connection',
                      style: TextStyle(
                        color: Color(0xFF282420),
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      'Use your laptop API on the same Wi-Fi for login and AI analysis.',
                      style: TextStyle(
                        color: Color(0xFF68625B),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              _StatusPill(label: status, color: accent),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: widget.baseUrlController,
            enabled: widget.enabled,
            keyboardType: TextInputType.url,
            onChanged: (_) {
              if (_savedMessage != null) {
                setState(() {
                  _savedMessage = null;
                  _testMessage = null;
                });
              } else {
                setState(() => _testMessage = null);
              }
            },
            decoration: InputDecoration(
              labelText: 'Laravel API URL',
              helperText: normalizedUrl,
              prefixIcon: const Icon(Icons.cloud_outlined),
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ActionChip(
                avatar: const Icon(Icons.phone_android_rounded, size: 18),
                label: const Text('Emulator'),
                onPressed: widget.enabled
                    ? () => _setUrl(ApiConfig.emulatorBaseUrl)
                    : null,
              ),
              ActionChip(
                avatar: const Icon(Icons.wifi_rounded, size: 18),
                label: const Text('Home Wi-Fi'),
                onPressed: widget.enabled
                    ? () => _setUrl(ApiConfig.homeWifiBaseUrl)
                    : null,
              ),
              ActionChip(
                avatar: const Icon(Icons.hub_outlined, size: 18),
                label: const Text('Hackathon'),
                onPressed: widget.enabled
                    ? () => _setUrl(ApiConfig.hackathonWifiBaseUrl)
                    : null,
              ),
              ActionChip(
                avatar: const Icon(Icons.laptop_mac_rounded, size: 18),
                label: const Text('Desktop'),
                onPressed: widget.enabled
                    ? () => _setUrl(ApiConfig.localBaseUrl)
                    : null,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: widget.enabled && !_isTesting ? _test : null,
                  icon: _isTesting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.wifi_find_rounded),
                  label: Text(_isTesting ? 'Testing...' : 'Test'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF0E5C56),
                    side: const BorderSide(color: Color(0xFFBFE6D7)),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton.icon(
                  onPressed: widget.enabled ? _save : null,
                  icon: const Icon(Icons.save_outlined),
                  label: const Text('Save'),
                ),
              ),
            ],
          ),
          if (_savedMessage != null) ...[
            const SizedBox(height: 8),
            Text(
              _savedMessage!,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF0E5C56),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          if (_testMessage != null) ...[
            const SizedBox(height: 8),
            Text(
              _testMessage!,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: _testMessage!.startsWith('Connected')
                    ? const Color(0xFF0E5C56)
                    : const Color(0xFF9E2732),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _setUrl(String value) {
    widget.baseUrlController.text = value;
    setState(() => _savedMessage = null);
  }

  Future<void> _save() async {
    widget.baseUrlController.text = ApiConfig.normalizeBaseUrl(
      widget.baseUrlController.text,
    );
    await widget.onSave();
    if (mounted) {
      setState(
        () => _savedMessage = 'Saved for login, scan, and appointments.',
      );
    }
  }

  Future<void> _test() async {
    final normalizedUrl = ApiConfig.normalizeBaseUrl(
      widget.baseUrlController.text,
    );
    setState(() {
      _isTesting = true;
      _testMessage = null;
    });
    try {
      final response = await http
          .get(
            Uri.parse('$normalizedUrl/health'),
            headers: const {'Accept': 'application/json'},
          )
          .timeout(const Duration(seconds: 6));
      if (!mounted) {
        return;
      }
      setState(() {
        _testMessage = response.statusCode >= 200 && response.statusCode < 300
            ? 'Connected. Save this URL, then login and scan.'
            : 'Reached server, but health failed (${response.statusCode}).';
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _testMessage =
            'Cannot connect. Check phone browser /api/health, firewall, and laptop IP.';
      });
    } finally {
      if (mounted) {
        setState(() => _isTesting = false);
      }
    }
  }

  bool _isPrivateLanHost(String? host) {
    if (host == null) {
      return false;
    }

    return host.startsWith('192.168.') ||
        host.startsWith('10.') ||
        RegExp(r'^172\.(1[6-9]|2\d|3[0-1])\.').hasMatch(host);
  }
}

class _GuestModeNotice extends StatelessWidget {
  const _GuestModeNotice({required this.text});

  final SkinoText text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF6F1),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFCCE7DE)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14123C36),
            blurRadius: 18,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 24,
            backgroundColor: Colors.white,
            child: Icon(Icons.person_outline_rounded, color: Color(0xFF0E5C56)),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  text.guestMode,
                  style: const TextStyle(
                    color: Color(0xFF123C36),
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  text.guestModeSubtitle,
                  style: const TextStyle(
                    color: Color(0xFF625B53),
                    fontWeight: FontWeight.w500,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          _StatusPill(label: text.soon, color: Color(0xFF0E5C56)),
        ],
      ),
    );
  }
}

class _ModelLearningPrivacyCard extends StatelessWidget {
  const _ModelLearningPrivacyCard({
    required this.text,
    required this.enabled,
    required this.isAllowed,
    required this.isLoaded,
    required this.onChanged,
  });

  final SkinoText text;
  final bool enabled;
  final bool isAllowed;
  final bool isLoaded;
  final Future<void> Function(bool granted) onChanged;

  @override
  Widget build(BuildContext context) {
    final accent = isAllowed
        ? const Color(0xFF0E5C56)
        : const Color(0xFFF98128);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFFFE3D1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: accent.withValues(alpha: 0.14),
                child: Icon(Icons.privacy_tip_outlined, color: accent),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      text.modelLearningPrivacy,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      isLoaded
                          ? text.modelLearningPrivacySubtitle
                          : text.modelLearningLoading,
                      style: const TextStyle(
                        color: Color(0xFF68625B),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: isAllowed,
                activeThumbColor: const Color(0xFF0E5C56),
                onChanged: enabled ? onChanged : null,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            text.modelLearningBody,
            style: const TextStyle(
              color: Color(0xFF625B53),
              fontWeight: FontWeight.w500,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 12),
          _StatusPill(
            label: isAllowed ? text.modelLearningOn : text.modelLearningOff,
            color: accent,
          ),
        ],
      ),
    );
  }
}

class _SettingsGroup extends StatelessWidget {
  const _SettingsGroup({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFFFE3D1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
          ...children,
        ],
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.trailingLabel,
    this.assetIcon,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String trailingLabel;
  final String? assetIcon;

  @override
  Widget build(BuildContext context) {
    final isReady = trailingLabel.toLowerCase() == 'ready';
    final accent = isReady ? const Color(0xFF0E5C56) : const Color(0xFFF98128);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: const Color(0xFFFFF3EA),
              borderRadius: BorderRadius.circular(14),
            ),
            child: assetIcon == null
                ? Icon(icon, color: accent, size: 20)
                : SkinoImageIcon(
                    asset: assetIcon!,
                    size: 32,
                    padding: 2,
                    backgroundColor: Colors.transparent,
                    borderRadius: 12,
                  ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: Color(0xFF68625B),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          _StatusPill(label: trailingLabel, color: accent),
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.24)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _LanguageToggle extends StatelessWidget {
  const _LanguageToggle({
    required this.text,
    required this.language,
    required this.onChanged,
  });

  final SkinoText text;
  final AppLanguage language;
  final ValueChanged<AppLanguage> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFFFE3D1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const CircleAvatar(
                backgroundColor: Color(0xFFEAF6F1),
                child: Icon(Icons.translate_rounded, color: Color(0xFF0E5C56)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      text.languageTitle,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      text.languageSubtitle,
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
          const SizedBox(height: 14),
          SegmentedButton<AppLanguage>(
            segments: AppLanguage.values
                .map(
                  (item) => ButtonSegment<AppLanguage>(
                    value: item,
                    label: Text(item.label),
                  ),
                )
                .toList(),
            selected: {language},
            onSelectionChanged: (selection) => onChanged(selection.first),
          ),
        ],
      ),
    );
  }
}

class _PageScaffold extends StatelessWidget {
  const _PageScaffold({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFCFAF7), Color(0xFFFBF8F4), Color(0xFFF7F5EF)],
        ),
      ),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 96),
        children: children,
      ),
    );
  }
}

class _PageTitle extends StatelessWidget {
  const _PageTitle({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: const Color(0xFF282420),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: const TextStyle(
            color: Color(0xFF68625B),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _DrawerSectionTitle extends StatelessWidget {
  const _DrawerSectionTitle(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 6),
      child: Text(
        title,
        style: const TextStyle(
          color: Color(0xFF68625B),
          fontWeight: FontWeight.w500,
          fontSize: 11,
        ),
      ),
    );
  }
}

class _DrawerItem extends StatelessWidget {
  const _DrawerItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.assetIcon,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String? assetIcon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      minLeadingWidth: 28,
      dense: true,
      visualDensity: const VisualDensity(horizontal: -2, vertical: -2),
      contentPadding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
      onTap: onTap,
      leading: assetIcon == null
          ? Icon(icon, color: const Color(0xFF0E5C56), size: 22)
          : SkinoImageIcon(
              asset: assetIcon!,
              size: 30,
              padding: 3,
              backgroundColor: const Color(0xFFEAF6F1),
              borderRadius: 12,
            ),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 15),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(
          color: Color(0xFF625B53),
          fontWeight: FontWeight.w400,
          fontSize: 13,
          height: 1.28,
        ),
      ),
      trailing: const Icon(Icons.chevron_right_rounded, size: 21),
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

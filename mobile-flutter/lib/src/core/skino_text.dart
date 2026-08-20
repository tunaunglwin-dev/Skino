import 'package:flutter/widgets.dart';

import '../../generated/l10n/app_localizations.dart';
import 'app_language.dart';

class SkinoText {
  SkinoText(this.language)
    : _l10n = lookupAppLocalizations(Locale(language.code));

  final AppLanguage language;
  final AppLocalizations _l10n;

  bool get isMyanmar => language == AppLanguage.myanmar;

  String get home => _l10n.home;
  String get scan => _l10n.scan;
  String get settings => _l10n.settings;
  String get welcomeTitle => _l10n.welcomeTitle;
  String get welcomeSubtitle => _l10n.welcomeSubtitle;
  String get beautyWorkspace => _l10n.beautyWorkspace;
  String get guestBeautyCheck => _l10n.guestBeautyCheck;
  String get guestBeautySubtitle => _l10n.guestBeautySubtitle;
  String get faceBeautyScan => _l10n.faceBeautyScan;
  String get faceBeautyScanSubtitle => _l10n.faceBeautyScanSubtitle;
  String get buddyName => _l10n.buddyName;
  String get buddyReady => _l10n.buddyReady;
  String get buddyPhotoReady => _l10n.buddyPhotoReady;
  String get buddyRoutineTap => _l10n.buddyRoutineTap;
  String buddyResultMessage(String severity) {
    final label = severityLabel(severity);
    if (severity == 'moderate' || severity == 'severe') {
      return isMyanmar
          ? '$label ဖြစ်နိုင်တယ်။ Calm care နဲ့ specialist option ကိုထားမယ်။'
          : '$label detected. I will keep calm care and specialist help ready.';
    }
    if (severity == 'mild') {
      return isMyanmar
          ? '$label ပါ။ Routine ကိုပုံမှန်လုပ်ရင် track ကြည့်လို့ရမယ်။'
          : '$label. Keep the routine steady and track again soon.';
    }
    return isMyanmar
        ? 'Healthy mood ကောင်းတယ်။ နေ့စဉ် care ကိုဆက်ထိန်းမယ်။'
        : 'Healthy mood looks good. Let us keep daily care steady.';
  }

  String latestSeverity(String severity) {
    return isMyanmar
        ? 'နောက်ဆုံးအခြေအနေ: ${severityLabel(severity)}'
        : 'Latest severity: ${severityLabel(severity)}';
  }

  String get dailyImprovement => _l10n.dailyImprovement;
  String get dailyImprovementSubtitle => _l10n.dailyImprovementSubtitle;
  String get specialistHelp => _l10n.specialistHelp;
  String get specialistHelpSubtitle => _l10n.specialistHelpSubtitle;
  String get readyFirstScan => _l10n.readyFirstScan;
  String latestScore(int score) =>
      isMyanmar ? 'နောက်ဆုံး score: $score' : 'Latest score: $score';
  String get guestHeroSubtitle => _l10n.guestHeroSubtitle;
  String activeRoutine(String name) => isMyanmar
      ? 'လက်ရှိ routine: $name။ နူးညံ့စွာ ဆက်လုပ်ပြီး နောက်တစ်ကြိမ် စကင်လုပ်ပါ။'
      : 'Active routine: $name. Keep the routine simple, track follow-up, and scan again after the cycle.';
  String get startScan => _l10n.startScan;
  String get skinScanTitle => _l10n.skinScanTitle;
  String get scanResultTitle => _l10n.scanResultTitle;
  String get latestScan => _l10n.latestScan;
  String get scanExplanation => _l10n.scanExplanation;
  String get skinZoneDetails => _l10n.skinZoneDetails;
  String get skinType => _l10n.skinType;
  String get acneSeverity => _l10n.acneSeverity;
  String get concerns => _l10n.concerns;
  String get scoreMeaning => _l10n.scoreMeaning;
  String get scanQuality => _l10n.scanQuality;
  String get routineReason => _l10n.routineReason;
  String skinTypeConfidence(int percent) => isMyanmar
      ? 'skin type ယုံကြည်မှု $percent%'
      : '$percent% skin type confidence';
  String get detectedConcerns => _l10n.detectedConcerns;
  String get noStrongConcern => _l10n.noStrongConcern;
  String get noAcneDetected => _l10n.noAcneDetected;
  String acneSeverityTitle(String severity) => isMyanmar
      ? '${severityLabel(severity)} ဝက်ခြံ'
      : '${_titleCase(severity)} acne';
  String get severeAcneHint => _l10n.severeAcneHint;
  String get moderateAcneHint => _l10n.moderateAcneHint;
  String get mildAcneHint => _l10n.mildAcneHint;
  String get clearAcneHint => _l10n.clearAcneHint;
  String get emptyBeautyRoutine => _l10n.emptyBeautyRoutine;
  String get scanCompleteTitle => _l10n.scanCompleteTitle;
  String scanCompleteSubtitle(int score) => isMyanmar
      ? 'Skin score $score ရရှိထားသည်။ ရလဒ်ကို သီးခြားဖတ်ပါ။'
      : 'Skin score $score is ready. Open the result page for details.';
  String get viewResult => _l10n.viewResult;
  String get newScan => _l10n.newScan;
  String get resultScanAgainHint => _l10n.resultScanAgainHint;
  String get requestAppointment => _l10n.requestAppointment;
  String get appointmentTitle => _l10n.appointmentTitle;
  String get appointmentSubtitle => _l10n.appointmentSubtitle;
  String get specialistDirectoryTitle => _l10n.specialistDirectoryTitle;
  String get specialistDirectorySubtitle => _l10n.specialistDirectorySubtitle;
  String get specialistNeedsScan => _l10n.specialistNeedsScan;
  String get chooseSpecialist => _l10n.chooseSpecialist;
  String get appointmentCardTitle => _l10n.appointmentCardTitle;
  String get appointmentCardSubtitle => _l10n.appointmentCardSubtitle;
  String appointmentScanSummary({
    required int score,
    required String skinType,
    required String severity,
  }) {
    final severityText = severityLabel(severity);
    return isMyanmar
        ? 'CRM သို့ပို့မည့် summary: score $score, skin type ${concernLabel(skinType)}, acne $severityText.'
        : 'CRM summary: score $score, skin type ${concernLabel(skinType)}, acne $severityText.';
  }

  String get appointmentName => _l10n.appointmentName;
  String get appointmentPhone => _l10n.appointmentPhone;
  String get appointmentEmail => _l10n.appointmentEmail;
  String get appointmentPreferredContact => _l10n.appointmentPreferredContact;
  String get appointmentPreferredTime => _l10n.appointmentPreferredTime;
  String get appointmentAnyTime => _l10n.appointmentAnyTime;
  String get appointmentPickTime => _l10n.appointmentPickTime;
  String get appointmentClearTime => _l10n.appointmentClearTime;
  String get appointmentBeautyGoal => _l10n.appointmentBeautyGoal;
  String get appointmentNotes => _l10n.appointmentNotes;
  String get appointmentSubmit => _l10n.appointmentSubmit;
  String get appointmentGoalAcne => _l10n.appointmentGoalAcne;
  String get appointmentGoalRoutine => _l10n.appointmentGoalRoutine;
  String get appointmentGoalDarkSpots => _l10n.appointmentGoalDarkSpots;
  String get appointmentNameRequired => _l10n.appointmentNameRequired;
  String get appointmentContactRequired => _l10n.appointmentContactRequired;
  String get appointmentEmailInvalid => _l10n.appointmentEmailInvalid;
  String appointmentContactMethod(String method) {
    return switch (method) {
      'phone' => isMyanmar ? 'ဖုန်း' : 'Phone',
      'email' => 'Email',
      'viber' => 'Viber',
      'telegram' => 'Telegram',
      'in_app' => isMyanmar ? 'In app' : 'In app',
      _ => method,
    };
  }

  String get scanEmptySubtitle => _l10n.scanEmptySubtitle;
  String get startLiveScan => _l10n.startLiveScan;
  String get startLiveScanSubtitle => _l10n.startLiveScanSubtitle;
  String get viewScanHistory => _l10n.viewScanHistory;
  String get viewScanHistorySubtitle => _l10n.viewScanHistorySubtitle;
  String get trackProgress => _l10n.trackProgress;
  String get trackProgressSubtitle => _l10n.trackProgressSubtitle;
  String get scanReadySubtitle => _l10n.scanReadySubtitle;
  String get settingsTitle => settings;
  String get settingsSubtitle => _l10n.settingsSubtitle;
  String get accountAccess => _l10n.accountAccess;
  String get guestMode => _l10n.guestMode;
  String get guestModeSubtitle => _l10n.guestModeSubtitle;
  String get signedIn => _l10n.signedIn;
  String get signedInSubtitle => _l10n.signedInSubtitle;
  String get privacySafety => _l10n.privacySafety;
  String get privacySafetySubtitle => _l10n.privacySafetySubtitle;
  String get modelLearningPrivacy => _l10n.modelLearningPrivacy;
  String get modelLearningPrivacySubtitle => _l10n.modelLearningPrivacySubtitle;
  String get modelLearningOn => _l10n.modelLearningOn;
  String get modelLearningOff => _l10n.modelLearningOff;
  String get modelLearningLoading => _l10n.modelLearningLoading;
  String get modelLearningBody => _l10n.modelLearningBody;
  String get dataControl => _l10n.dataControl;
  String get dataControlSubtitle => _l10n.dataControlSubtitle;
  String get appPreferences => _l10n.appPreferences;
  String get languageTitle => _l10n.languageTitle;
  String get languageSubtitle => _l10n.languageSubtitle;
  String get skinProfile => _l10n.skinProfile;
  String get skinProfileSubtitle => _l10n.skinProfileSubtitle;
  String get notifications => _l10n.notifications;
  String get notificationSubtitle => _l10n.notificationSubtitle;
  String get savedProgress => _l10n.savedProgress;
  String get savedProgressSubtitle => _l10n.savedProgressSubtitle;
  String get apiConnection => _l10n.apiConnection;
  String get apiConnectionSubtitle => _l10n.apiConnectionSubtitle;
  String get accountSecurity => _l10n.accountSecurity;
  String get accountSecuritySubtitle => _l10n.accountSecuritySubtitle;
  String get ready => _l10n.ready;
  String get soon => _l10n.soon;
  String get logout => _l10n.logout;
  String get skinProfileDrawer => _l10n.skinProfileDrawer;
  String get skinProfileDrawerSubtitle => _l10n.skinProfileDrawerSubtitle;
  String get analysisHistory => _l10n.analysisHistory;
  String get analysisHistorySubtitle => _l10n.analysisHistorySubtitle;
  String get specialistAppointment => _l10n.specialistAppointment;
  String get specialistAppointmentSubtitle =>
      _l10n.specialistAppointmentSubtitle;
  String get care => _l10n.care;
  String get careSubtitle => _l10n.careSubtitle;
  String get products => _l10n.products;
  String get productsSubtitle => _l10n.productsSubtitle;
  String get orders => _l10n.orders;
  String get ordersSubtitle => _l10n.ordersSubtitle;
  String get helpSafety => _l10n.helpSafety;
  String get helpSafetySubtitle => _l10n.helpSafetySubtitle;
  String get beautyRoutines => _l10n.beautyRoutines;
  String get beautyRoutinesSubtitle => _l10n.beautyRoutinesSubtitle;
  String get todayBeautyPlan => _l10n.todayBeautyPlan;
  String get todayBeautyPlanSubtitle => _l10n.todayBeautyPlanSubtitle;
  String get dailyRoutine => _l10n.dailyRoutine;
  String get progressTracker => _l10n.progressTracker;
  String get morningCare => _l10n.morningCare;
  String get nightCare => _l10n.nightCare;
  String get gentleCleanser => _l10n.gentleCleanser;
  String get sunscreen => _l10n.sunscreen;
  String get calmRoutine => _l10n.calmRoutine;
  String get nextScan => _l10n.nextScan;
  String get saveProgressHint => _l10n.saveProgressHint;
  String get oilBalance => _l10n.oilBalance;
  String get darkSpots => _l10n.darkSpots;
  String get acneCare => _l10n.acneCare;
  String get hydration => _l10n.hydration;
  String scanNextMessage({required bool isGuest, required String severity}) {
    final isEscalation = severity == 'moderate' || severity == 'severe';
    if (isGuest) {
      return isMyanmar
          ? 'ဒီစကင်ကို သိမ်းရန်၊ progress ကြည့်ရန်၊ reminder ရရန် Login ဝင်ပါ။'
          : 'Login when you want to save this scan, track improvement, and receive routine reminders.';
    }
    if (isEscalation) {
      return isMyanmar
          ? 'ဝက်ခြံနာခြင်း၊ ပျံ့ခြင်း၊ မတိုးတက်ခြင်းရှိလျှင် specialist အကြံဉာဏ်ယူပါ။'
          : 'Consider specialist guidance if acne is painful, spreading, or not improving.';
    }
    return isMyanmar
        ? 'Routine ကို နူးညံ့စွာ ဆက်လုပ်ပြီး beauty progress ကို နောက်စကင်ဖြင့်ကြည့်ပါ။'
        : 'Keep your routine gentle and scan again to track beauty progress.';
  }

  String severityLabel(String severity) {
    if (!isMyanmar) {
      return _titleCase(severity);
    }
    return switch (severity) {
      'none' => _l10n.noneSeverity,
      'mild' => _l10n.mildSeverity,
      'moderate' => _l10n.moderateSeverity,
      'severe' => _l10n.severeSeverity,
      _ => severity,
    };
  }

  String concernLabel(String concern) {
    if (!isMyanmar) {
      return _titleCase(concern);
    }

    return switch (concern) {
      'dark_spots' => _l10n.darkSpotsConcern,
      'oiliness' => _l10n.oilinessConcern,
      'dryness' => _l10n.drynessConcern,
      'redness' => _l10n.rednessConcern,
      'acne' => _l10n.acneConcern,
      'texture' => _l10n.textureConcern,
      _ => _titleCase(concern),
    };
  }

  String routineStep(String step) {
    if (!isMyanmar) {
      return _titleCase(step);
    }

    final normalized = step.toLowerCase();
    if (normalized.contains('cleanser')) return 'Gentle Cleanser';
    if (normalized.contains('serum')) return 'Serum';
    if (normalized.contains('moisturizer')) return 'Moisturizer';
    if (normalized.contains('sunscreen')) return 'Sunscreen';
    if (normalized.contains('spot')) return 'Spot treatment';
    return _titleCase(step);
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

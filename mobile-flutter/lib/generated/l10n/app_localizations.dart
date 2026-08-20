import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_my.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('my'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Skino'**
  String get appTitle;

  /// No description provided for @home.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

  /// No description provided for @scan.
  ///
  /// In en, this message translates to:
  /// **'Scan'**
  String get scan;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @buddy.
  ///
  /// In en, this message translates to:
  /// **'Buddy'**
  String get buddy;

  /// No description provided for @scanExplanation.
  ///
  /// In en, this message translates to:
  /// **'Scan explanation'**
  String get scanExplanation;

  /// No description provided for @skinZoneDetails.
  ///
  /// In en, this message translates to:
  /// **'Skin zone details'**
  String get skinZoneDetails;

  /// No description provided for @skinType.
  ///
  /// In en, this message translates to:
  /// **'Skin type'**
  String get skinType;

  /// No description provided for @acneSeverity.
  ///
  /// In en, this message translates to:
  /// **'Acne severity'**
  String get acneSeverity;

  /// No description provided for @concerns.
  ///
  /// In en, this message translates to:
  /// **'Concerns'**
  String get concerns;

  /// No description provided for @scoreMeaning.
  ///
  /// In en, this message translates to:
  /// **'Score meaning'**
  String get scoreMeaning;

  /// No description provided for @scanQuality.
  ///
  /// In en, this message translates to:
  /// **'Scan quality'**
  String get scanQuality;

  /// No description provided for @routineReason.
  ///
  /// In en, this message translates to:
  /// **'Routine reason'**
  String get routineReason;

  /// No description provided for @welcomeTitle.
  ///
  /// In en, this message translates to:
  /// **'Welcome to Skino'**
  String get welcomeTitle;

  /// No description provided for @welcomeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Try a face beauty scan first. Save and track later with login.'**
  String get welcomeSubtitle;

  /// No description provided for @beautyWorkspace.
  ///
  /// In en, this message translates to:
  /// **'Beauty workspace'**
  String get beautyWorkspace;

  /// No description provided for @guestBeautyCheck.
  ///
  /// In en, this message translates to:
  /// **'Guest beauty check'**
  String get guestBeautyCheck;

  /// No description provided for @guestBeautySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Scan now. Login only when you want to save progress.'**
  String get guestBeautySubtitle;

  /// No description provided for @faceBeautyScan.
  ///
  /// In en, this message translates to:
  /// **'Face beauty scan'**
  String get faceBeautyScan;

  /// No description provided for @faceBeautyScanSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Check acne severity and skin score in under a minute.'**
  String get faceBeautyScanSubtitle;

  /// No description provided for @buddyName.
  ///
  /// In en, this message translates to:
  /// **'Skino Buddy'**
  String get buddyName;

  /// No description provided for @buddyReady.
  ///
  /// In en, this message translates to:
  /// **'Start a scan and I will read your skin mood.'**
  String get buddyReady;

  /// No description provided for @buddyPhotoReady.
  ///
  /// In en, this message translates to:
  /// **'Scan frame is ready. Tap analyze and I will read the result.'**
  String get buddyPhotoReady;

  /// No description provided for @buddyRoutineTap.
  ///
  /// In en, this message translates to:
  /// **'Nice check-in. Keep today routine gentle.'**
  String get buddyRoutineTap;

  /// No description provided for @dailyImprovement.
  ///
  /// In en, this message translates to:
  /// **'Daily improvement'**
  String get dailyImprovement;

  /// No description provided for @dailyImprovementSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Gentle routines, reminders, and next scan check-ins.'**
  String get dailyImprovementSubtitle;

  /// No description provided for @specialistHelp.
  ///
  /// In en, this message translates to:
  /// **'Specialist help'**
  String get specialistHelp;

  /// No description provided for @specialistHelpSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Recommended when acne looks moderate, severe, or uncertain.'**
  String get specialistHelpSubtitle;

  /// No description provided for @readyFirstScan.
  ///
  /// In en, this message translates to:
  /// **'Ready for your first scan'**
  String get readyFirstScan;

  /// No description provided for @guestHeroSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Scan with the acne model, get focused concerns, then move into daily care and progress tracking.'**
  String get guestHeroSubtitle;

  /// No description provided for @startScan.
  ///
  /// In en, this message translates to:
  /// **'Start scan'**
  String get startScan;

  /// No description provided for @skinScanTitle.
  ///
  /// In en, this message translates to:
  /// **'Skin scan'**
  String get skinScanTitle;

  /// No description provided for @scanResultTitle.
  ///
  /// In en, this message translates to:
  /// **'Scan result'**
  String get scanResultTitle;

  /// No description provided for @latestScan.
  ///
  /// In en, this message translates to:
  /// **'Latest scan'**
  String get latestScan;

  /// No description provided for @detectedConcerns.
  ///
  /// In en, this message translates to:
  /// **'Detected concerns'**
  String get detectedConcerns;

  /// No description provided for @noStrongConcern.
  ///
  /// In en, this message translates to:
  /// **'No strong concern detected'**
  String get noStrongConcern;

  /// No description provided for @noAcneDetected.
  ///
  /// In en, this message translates to:
  /// **'No acne detected'**
  String get noAcneDetected;

  /// No description provided for @severeAcneHint.
  ///
  /// In en, this message translates to:
  /// **'Specialist review is recommended.'**
  String get severeAcneHint;

  /// No description provided for @moderateAcneHint.
  ///
  /// In en, this message translates to:
  /// **'Use a focused routine and consider follow-up.'**
  String get moderateAcneHint;

  /// No description provided for @mildAcneHint.
  ///
  /// In en, this message translates to:
  /// **'Start gentle acne care and track progress.'**
  String get mildAcneHint;

  /// No description provided for @clearAcneHint.
  ///
  /// In en, this message translates to:
  /// **'Keep your daily routine and scan again later.'**
  String get clearAcneHint;

  /// No description provided for @emptyBeautyRoutine.
  ///
  /// In en, this message translates to:
  /// **'Run a scan to generate a beauty routine.'**
  String get emptyBeautyRoutine;

  /// No description provided for @scanCompleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Scan complete'**
  String get scanCompleteTitle;

  /// No description provided for @viewResult.
  ///
  /// In en, this message translates to:
  /// **'View result'**
  String get viewResult;

  /// No description provided for @newScan.
  ///
  /// In en, this message translates to:
  /// **'New scan'**
  String get newScan;

  /// No description provided for @resultScanAgainHint.
  ///
  /// In en, this message translates to:
  /// **'Start fresh with a new live scan frame when you want to scan again.'**
  String get resultScanAgainHint;

  /// No description provided for @requestAppointment.
  ///
  /// In en, this message translates to:
  /// **'Specialist appointment'**
  String get requestAppointment;

  /// No description provided for @appointmentTitle.
  ///
  /// In en, this message translates to:
  /// **'Appointment request'**
  String get appointmentTitle;

  /// No description provided for @appointmentSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Send a focused request so the team can match the right specialist.'**
  String get appointmentSubtitle;

  /// No description provided for @specialistDirectoryTitle.
  ///
  /// In en, this message translates to:
  /// **'Specialist profiles'**
  String get specialistDirectoryTitle;

  /// No description provided for @specialistDirectorySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Choose a specialist profile, then send the latest scan summary as a request.'**
  String get specialistDirectorySubtitle;

  /// No description provided for @specialistNeedsScan.
  ///
  /// In en, this message translates to:
  /// **'Run a scan first before sending an appointment request.'**
  String get specialistNeedsScan;

  /// No description provided for @chooseSpecialist.
  ///
  /// In en, this message translates to:
  /// **'Choose'**
  String get chooseSpecialist;

  /// No description provided for @appointmentCardTitle.
  ///
  /// In en, this message translates to:
  /// **'Request specialist appointment'**
  String get appointmentCardTitle;

  /// No description provided for @appointmentCardSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Send this scan summary to admin CRM for follow-up.'**
  String get appointmentCardSubtitle;

  /// No description provided for @appointmentName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get appointmentName;

  /// No description provided for @appointmentPhone.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get appointmentPhone;

  /// No description provided for @appointmentEmail.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get appointmentEmail;

  /// No description provided for @appointmentPreferredContact.
  ///
  /// In en, this message translates to:
  /// **'Preferred contact'**
  String get appointmentPreferredContact;

  /// No description provided for @appointmentPreferredTime.
  ///
  /// In en, this message translates to:
  /// **'Preferred time'**
  String get appointmentPreferredTime;

  /// No description provided for @appointmentAnyTime.
  ///
  /// In en, this message translates to:
  /// **'Admin can arrange the time'**
  String get appointmentAnyTime;

  /// No description provided for @appointmentPickTime.
  ///
  /// In en, this message translates to:
  /// **'Pick'**
  String get appointmentPickTime;

  /// No description provided for @appointmentClearTime.
  ///
  /// In en, this message translates to:
  /// **'Clear time'**
  String get appointmentClearTime;

  /// No description provided for @appointmentBeautyGoal.
  ///
  /// In en, this message translates to:
  /// **'Beauty goal'**
  String get appointmentBeautyGoal;

  /// No description provided for @appointmentNotes.
  ///
  /// In en, this message translates to:
  /// **'Notes for specialist'**
  String get appointmentNotes;

  /// No description provided for @appointmentSubmit.
  ///
  /// In en, this message translates to:
  /// **'Send appointment request'**
  String get appointmentSubmit;

  /// No description provided for @appointmentGoalAcne.
  ///
  /// In en, this message translates to:
  /// **'Specialist acne consultation'**
  String get appointmentGoalAcne;

  /// No description provided for @appointmentGoalRoutine.
  ///
  /// In en, this message translates to:
  /// **'Routine review with specialist'**
  String get appointmentGoalRoutine;

  /// No description provided for @appointmentGoalDarkSpots.
  ///
  /// In en, this message translates to:
  /// **'Dark spots review'**
  String get appointmentGoalDarkSpots;

  /// No description provided for @appointmentNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter your name.'**
  String get appointmentNameRequired;

  /// No description provided for @appointmentContactRequired.
  ///
  /// In en, this message translates to:
  /// **'Please add a phone number or email.'**
  String get appointmentContactRequired;

  /// No description provided for @appointmentEmailInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid email.'**
  String get appointmentEmailInvalid;

  /// No description provided for @scanEmptySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Center your face in the scan frame for a beauty check.'**
  String get scanEmptySubtitle;

  /// No description provided for @startLiveScan.
  ///
  /// In en, this message translates to:
  /// **'Start live face scan'**
  String get startLiveScan;

  /// No description provided for @startLiveScanSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Open the camera, lock a face scan frame, then analyze.'**
  String get startLiveScanSubtitle;

  /// No description provided for @viewScanHistory.
  ///
  /// In en, this message translates to:
  /// **'View scan history'**
  String get viewScanHistory;

  /// No description provided for @viewScanHistorySubtitle.
  ///
  /// In en, this message translates to:
  /// **'After login, saved scans will appear here.'**
  String get viewScanHistorySubtitle;

  /// No description provided for @trackProgress.
  ///
  /// In en, this message translates to:
  /// **'Track progress'**
  String get trackProgress;

  /// No description provided for @trackProgressSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Review score changes across routine cycles.'**
  String get trackProgressSubtitle;

  /// No description provided for @scanReadySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Latest scan is ready. Review severity and routine guidance below.'**
  String get scanReadySubtitle;

  /// No description provided for @settingsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Profile, login, privacy, and beauty preferences.'**
  String get settingsSubtitle;

  /// No description provided for @accountAccess.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get accountAccess;

  /// No description provided for @guestMode.
  ///
  /// In en, this message translates to:
  /// **'Guest mode'**
  String get guestMode;

  /// No description provided for @guestModeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Scan is available. Login is needed for saving and appointments.'**
  String get guestModeSubtitle;

  /// No description provided for @signedIn.
  ///
  /// In en, this message translates to:
  /// **'Signed in'**
  String get signedIn;

  /// No description provided for @signedInSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Scan history, routine progress, and orders can be saved.'**
  String get signedInSubtitle;

  /// No description provided for @privacySafety.
  ///
  /// In en, this message translates to:
  /// **'Privacy / Safety'**
  String get privacySafety;

  /// No description provided for @privacySafetySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Face photos, scan results, and health notes need careful handling.'**
  String get privacySafetySubtitle;

  /// No description provided for @modelLearningPrivacy.
  ///
  /// In en, this message translates to:
  /// **'AI learning privacy'**
  String get modelLearningPrivacy;

  /// No description provided for @modelLearningPrivacySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Only scans you allow can enter the AI improvement review queue.'**
  String get modelLearningPrivacySubtitle;

  /// No description provided for @modelLearningOn.
  ///
  /// In en, this message translates to:
  /// **'Allowed'**
  String get modelLearningOn;

  /// No description provided for @modelLearningOff.
  ///
  /// In en, this message translates to:
  /// **'Private'**
  String get modelLearningOff;

  /// No description provided for @modelLearningLoading.
  ///
  /// In en, this message translates to:
  /// **'Checking privacy setting'**
  String get modelLearningLoading;

  /// No description provided for @modelLearningBody.
  ///
  /// In en, this message translates to:
  /// **'Guest scans are never used for training. Logged-in scans stay private by default and can only help improve the model after your permission and human review.'**
  String get modelLearningBody;

  /// No description provided for @dataControl.
  ///
  /// In en, this message translates to:
  /// **'Data control'**
  String get dataControl;

  /// No description provided for @dataControlSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Users will control saved scans and reports.'**
  String get dataControlSubtitle;

  /// No description provided for @appPreferences.
  ///
  /// In en, this message translates to:
  /// **'App preferences'**
  String get appPreferences;

  /// No description provided for @languageTitle.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get languageTitle;

  /// No description provided for @languageSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Myanmar is the default language.'**
  String get languageSubtitle;

  /// No description provided for @skinProfile.
  ///
  /// In en, this message translates to:
  /// **'Skin profile'**
  String get skinProfile;

  /// No description provided for @skinProfileSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Goals, allergies, sensitivity, and routine quiz.'**
  String get skinProfileSubtitle;

  /// No description provided for @notifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// No description provided for @notificationSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Routine reminders and next scan check-ins.'**
  String get notificationSubtitle;

  /// No description provided for @savedProgress.
  ///
  /// In en, this message translates to:
  /// **'Progress saving'**
  String get savedProgress;

  /// No description provided for @savedProgressSubtitle.
  ///
  /// In en, this message translates to:
  /// **'After login, scan comparisons and routine streaks can appear.'**
  String get savedProgressSubtitle;

  /// No description provided for @apiConnection.
  ///
  /// In en, this message translates to:
  /// **'API connection'**
  String get apiConnection;

  /// No description provided for @apiConnectionSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Demo backend connection setting.'**
  String get apiConnectionSubtitle;

  /// No description provided for @accountSecurity.
  ///
  /// In en, this message translates to:
  /// **'Account security'**
  String get accountSecurity;

  /// No description provided for @accountSecuritySubtitle.
  ///
  /// In en, this message translates to:
  /// **'For Google login and secure sessions.'**
  String get accountSecuritySubtitle;

  /// No description provided for @ready.
  ///
  /// In en, this message translates to:
  /// **'Ready'**
  String get ready;

  /// No description provided for @soon.
  ///
  /// In en, this message translates to:
  /// **'Soon'**
  String get soon;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout;

  /// No description provided for @skinProfileDrawer.
  ///
  /// In en, this message translates to:
  /// **'Skin profile'**
  String get skinProfileDrawer;

  /// No description provided for @skinProfileDrawerSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Goals, allergies, sensitivity, routine'**
  String get skinProfileDrawerSubtitle;

  /// No description provided for @analysisHistory.
  ///
  /// In en, this message translates to:
  /// **'Analysis history'**
  String get analysisHistory;

  /// No description provided for @analysisHistorySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Past scans and saved reports'**
  String get analysisHistorySubtitle;

  /// No description provided for @specialistAppointment.
  ///
  /// In en, this message translates to:
  /// **'Specialist appointment'**
  String get specialistAppointment;

  /// No description provided for @specialistAppointmentSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Optional help for moderate or severe acne'**
  String get specialistAppointmentSubtitle;

  /// No description provided for @care.
  ///
  /// In en, this message translates to:
  /// **'Care'**
  String get care;

  /// No description provided for @careSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Daily routines and beauty goals'**
  String get careSubtitle;

  /// No description provided for @products.
  ///
  /// In en, this message translates to:
  /// **'Products'**
  String get products;

  /// No description provided for @productsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Routine product showcase'**
  String get productsSubtitle;

  /// No description provided for @orders.
  ///
  /// In en, this message translates to:
  /// **'Orders'**
  String get orders;

  /// No description provided for @ordersSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Purchases and payment history'**
  String get ordersSubtitle;

  /// No description provided for @helpSafety.
  ///
  /// In en, this message translates to:
  /// **'Help / Safety'**
  String get helpSafety;

  /// No description provided for @helpSafetySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Support, privacy, and safety info'**
  String get helpSafetySubtitle;

  /// No description provided for @beautyRoutines.
  ///
  /// In en, this message translates to:
  /// **'Beauty routines'**
  String get beautyRoutines;

  /// No description provided for @beautyRoutinesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Daily care, reminders, and check-ins'**
  String get beautyRoutinesSubtitle;

  /// No description provided for @todayBeautyPlan.
  ///
  /// In en, this message translates to:
  /// **'Today\'s beauty plan'**
  String get todayBeautyPlan;

  /// No description provided for @todayBeautyPlanSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Keep the routine gentle and matched to your latest scan.'**
  String get todayBeautyPlanSubtitle;

  /// No description provided for @dailyRoutine.
  ///
  /// In en, this message translates to:
  /// **'Daily routine'**
  String get dailyRoutine;

  /// No description provided for @progressTracker.
  ///
  /// In en, this message translates to:
  /// **'Progress tracker'**
  String get progressTracker;

  /// No description provided for @morningCare.
  ///
  /// In en, this message translates to:
  /// **'Morning'**
  String get morningCare;

  /// No description provided for @nightCare.
  ///
  /// In en, this message translates to:
  /// **'Night'**
  String get nightCare;

  /// No description provided for @gentleCleanser.
  ///
  /// In en, this message translates to:
  /// **'Gentle cleanse'**
  String get gentleCleanser;

  /// No description provided for @sunscreen.
  ///
  /// In en, this message translates to:
  /// **'Apply sunscreen'**
  String get sunscreen;

  /// No description provided for @calmRoutine.
  ///
  /// In en, this message translates to:
  /// **'Calm routine'**
  String get calmRoutine;

  /// No description provided for @nextScan.
  ///
  /// In en, this message translates to:
  /// **'Next scan'**
  String get nextScan;

  /// No description provided for @saveProgressHint.
  ///
  /// In en, this message translates to:
  /// **'Login when you want to save progress.'**
  String get saveProgressHint;

  /// No description provided for @oilBalance.
  ///
  /// In en, this message translates to:
  /// **'Oil balance'**
  String get oilBalance;

  /// No description provided for @darkSpots.
  ///
  /// In en, this message translates to:
  /// **'Dark spots'**
  String get darkSpots;

  /// No description provided for @acneCare.
  ///
  /// In en, this message translates to:
  /// **'Acne care'**
  String get acneCare;

  /// No description provided for @hydration.
  ///
  /// In en, this message translates to:
  /// **'Hydration'**
  String get hydration;

  /// No description provided for @noneSeverity.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get noneSeverity;

  /// No description provided for @mildSeverity.
  ///
  /// In en, this message translates to:
  /// **'Mild'**
  String get mildSeverity;

  /// No description provided for @moderateSeverity.
  ///
  /// In en, this message translates to:
  /// **'Moderate'**
  String get moderateSeverity;

  /// No description provided for @severeSeverity.
  ///
  /// In en, this message translates to:
  /// **'Severe'**
  String get severeSeverity;

  /// No description provided for @darkSpotsConcern.
  ///
  /// In en, this message translates to:
  /// **'Dark Spots'**
  String get darkSpotsConcern;

  /// No description provided for @oilinessConcern.
  ///
  /// In en, this message translates to:
  /// **'Oiliness'**
  String get oilinessConcern;

  /// No description provided for @drynessConcern.
  ///
  /// In en, this message translates to:
  /// **'Dryness'**
  String get drynessConcern;

  /// No description provided for @rednessConcern.
  ///
  /// In en, this message translates to:
  /// **'Redness'**
  String get rednessConcern;

  /// No description provided for @acneConcern.
  ///
  /// In en, this message translates to:
  /// **'Acne'**
  String get acneConcern;

  /// No description provided for @textureConcern.
  ///
  /// In en, this message translates to:
  /// **'Texture'**
  String get textureConcern;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'my'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'my':
      return AppLocalizationsMy();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}

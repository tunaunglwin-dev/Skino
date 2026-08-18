import 'app_language.dart';

class SkinoText {
  const SkinoText(this.language);

  final AppLanguage language;

  bool get isMyanmar => language == AppLanguage.myanmar;

  String get home => isMyanmar ? 'ပင်မ' : 'Home';
  String get scan => isMyanmar ? 'စကင်' : 'Scan';
  String get settings => isMyanmar ? 'ဆက်တင်' : 'Settings';
  String get welcomeTitle =>
      isMyanmar ? 'Skino မှ ကြိုဆိုပါတယ်' : 'Welcome to Skino';
  String get welcomeSubtitle => isMyanmar
      ? 'မျက်နှာအလှအတွက် စကင်အရင်လုပ်ကြည့်ပါ။ မှတ်တမ်းသိမ်းပြီး တိုးတက်မှုကိုကြည့်ချင်မှသာ Login ဝင်ပါ။'
      : 'Try a face beauty scan first. Save and track later with login.';
  String get beautyWorkspace =>
      isMyanmar ? 'အလှအပလုပ်ဆောင်ချက်များ' : 'Beauty workspace';
  String get guestBeautyCheck =>
      isMyanmar ? 'ဧည့်သည်အနေဖြင့် စကင်' : 'Guest beauty check';
  String get guestBeautySubtitle => isMyanmar
      ? 'ယခု စကင်လုပ်နိုင်ပါတယ်။ တိုးတက်မှုသိမ်းချင်မှ Login ဝင်ပါ။'
      : 'Scan now. Login only when you want to save progress.';
  String get faceBeautyScan =>
      isMyanmar ? 'မျက်နှာအလှ စကင်' : 'Face beauty scan';
  String get faceBeautyScanSubtitle => isMyanmar
      ? 'ဝက်ခြံအခြေအနေနှင့် အသားအရေ score ကို အမြန်စစ်ပါ။'
      : 'Check acne severity and skin score in under a minute.';
  String get buddyName => isMyanmar ? 'Skino Buddy' : 'Skino Buddy';
  String get buddyReady => isMyanmar
      ? 'စကင်စလုပ်ရင် skin mood ကို ကူဖတ်ပေးမယ်။'
      : 'Start a scan and I will read your skin mood.';
  String get buddyPhotoReady => isMyanmar
      ? 'စကင်ဖရိမ်ရပြီ။ Analyze နှိပ်လိုက်ရင် result ကိုဖတ်ပေးမယ်။'
      : 'Scan frame is ready. Tap analyze and I will read the result.';
  String get buddyRoutineTap => isMyanmar
      ? 'ကောင်းတယ်။ ဒီနေ့ routine ကို နူးညံ့စွာဆက်လုပ်ပါ။'
      : 'Nice check-in. Keep today routine gentle.';
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

  String get dailyImprovement =>
      isMyanmar ? 'နေ့စဉ်တိုးတက်မှု' : 'Daily improvement';
  String get dailyImprovementSubtitle => isMyanmar
      ? 'နူးညံ့တဲ့ routine၊ သတိပေးချက်နဲ့ နောက်စကင်ချိန်များ။'
      : 'Gentle routines, reminders, and next scan check-ins.';
  String get specialistHelp =>
      isMyanmar ? 'Specialist အကူအညီ' : 'Specialist help';
  String get specialistHelpSubtitle => isMyanmar
      ? 'ဝက်ခြံအခြေအနေ များ၊ ပြင်း၊ မသေချာလျှင် အကြံပြုပါမယ်။'
      : 'Recommended when acne looks moderate, severe, or uncertain.';
  String get readyFirstScan =>
      isMyanmar ? 'ပထမဆုံး စကင်လုပ်ရန် အသင့်' : 'Ready for your first scan';
  String latestScore(int score) =>
      isMyanmar ? 'နောက်ဆုံး score: $score' : 'Latest score: $score';
  String get guestHeroSubtitle => isMyanmar
      ? 'ဝက်ခြံအခြေအနေ၊ concern များကိုစစ်ပြီး နေ့စဉ် routine နှင့် progress tracking သို့ ဆက်သွားပါ။'
      : 'Scan with the acne model, get focused concerns, then move into daily care and progress tracking.';
  String activeRoutine(String name) => isMyanmar
      ? 'လက်ရှိ routine: $name။ နူးညံ့စွာ ဆက်လုပ်ပြီး နောက်တစ်ကြိမ် စကင်လုပ်ပါ။'
      : 'Active routine: $name. Keep the routine simple, track follow-up, and scan again after the cycle.';
  String get startScan => isMyanmar ? 'စကင်စတင်မယ်' : 'Start scan';
  String get skinScanTitle => isMyanmar ? 'မျက်နှာ စကင်' : 'Skin scan';
  String get scanResultTitle => isMyanmar ? 'စကင် ရလဒ်' : 'Scan result';
  String get latestScan => isMyanmar ? 'နောက်ဆုံး စကင်' : 'Latest scan';
  String skinTypeConfidence(int percent) => isMyanmar
      ? 'skin type ယုံကြည်မှု $percent%'
      : '$percent% skin type confidence';
  String get detectedConcerns =>
      isMyanmar ? 'တွေ့ရှိသော concern များ' : 'Detected concerns';
  String get noStrongConcern =>
      isMyanmar ? 'အရေးကြီး concern မတွေ့ပါ' : 'No strong concern detected';
  String get noAcneDetected =>
      isMyanmar ? 'ဝက်ခြံ မတွေ့ပါ' : 'No acne detected';
  String acneSeverityTitle(String severity) => isMyanmar
      ? '${severityLabel(severity)} ဝက်ခြံ'
      : '${_titleCase(severity)} acne';
  String get severeAcneHint => isMyanmar
      ? 'Specialist review ယူရန် အကြံပြုပါသည်။'
      : 'Specialist review is recommended.';
  String get moderateAcneHint => isMyanmar
      ? 'Focused routine လုပ်ပြီး follow-up စဉ်းစားပါ။'
      : 'Use a focused routine and consider follow-up.';
  String get mildAcneHint => isMyanmar
      ? 'Gentle acne care စတင်ပြီး progress ကြည့်ပါ။'
      : 'Start gentle acne care and track progress.';
  String get clearAcneHint => isMyanmar
      ? 'နေ့စဉ် routine ကို ဆက်လုပ်ပြီး နောက်မှ ပြန်စကင်ပါ။'
      : 'Keep your daily routine and scan again later.';
  String get emptyBeautyRoutine => isMyanmar
      ? 'Routine ရရန် စကင်လုပ်ပါ။'
      : 'Run a scan to generate a beauty routine.';
  String get scanCompleteTitle => isMyanmar ? 'စကင်ပြီးပါပြီ' : 'Scan complete';
  String scanCompleteSubtitle(int score) => isMyanmar
      ? 'Skin score $score ရရှိထားသည်။ ရလဒ်ကို သီးခြားဖတ်ပါ။'
      : 'Skin score $score is ready. Open the result page for details.';
  String get viewResult => isMyanmar ? 'ရလဒ်ကြည့်မယ်' : 'View result';
  String get newScan => isMyanmar ? 'အသစ်စကင်' : 'New scan';
  String get resultScanAgainHint => isMyanmar
      ? 'နောက်တစ်ကြိမ် စကင်လုပ်ချင်လျှင် live scan frame အသစ်နဲ့ စတင်နိုင်ပါတယ်။'
      : 'Start fresh with a new live scan frame when you want to scan again.';
  String get requestAppointment =>
      isMyanmar ? 'Specialist appointment' : 'Specialist appointment';
  String get appointmentTitle =>
      isMyanmar ? 'Appointment request' : 'Appointment request';
  String get appointmentSubtitle => isMyanmar
      ? 'ဆရာဝန်/ specialist များစွာရှိနိုင်သောကြောင့် request ကို သီးခြားပို့ပါ။'
      : 'Send a focused request so the team can match the right specialist.';
  String get specialistDirectoryTitle =>
      isMyanmar ? 'Specialist profiles' : 'Specialist profiles';
  String get specialistDirectorySubtitle => isMyanmar
      ? 'အဆင်ပြေသော specialist ကိုရွေးပြီး နောက်ဆုံးစကင် summary ဖြင့် request ပို့ပါ။'
      : 'Choose a specialist profile, then send the latest scan summary as a request.';
  String get specialistNeedsScan => isMyanmar
      ? 'Appointment request ပို့ရန် စကင်ရလဒ်တစ်ခု အရင်လိုပါတယ်။'
      : 'Run a scan first before sending an appointment request.';
  String get chooseSpecialist => isMyanmar ? 'ရွေးမယ်' : 'Choose';
  String get appointmentCardTitle => isMyanmar
      ? 'Specialist appointment တောင်းမယ်'
      : 'Request specialist appointment';
  String get appointmentCardSubtitle => isMyanmar
      ? 'စကင် summary ကို admin CRM သို့ပို့ပြီး follow-up လုပ်ပါမယ်။'
      : 'Send this scan summary to admin CRM for follow-up.';
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

  String get appointmentName => isMyanmar ? 'အမည်' : 'Name';
  String get appointmentPhone => isMyanmar ? 'ဖုန်း' : 'Phone';
  String get appointmentEmail => isMyanmar ? 'Email' : 'Email';
  String get appointmentPreferredContact =>
      isMyanmar ? 'ဆက်သွယ်ရန်နည်းလမ်း' : 'Preferred contact';
  String get appointmentPreferredTime =>
      isMyanmar ? 'အဆင်ပြေသောအချိန်' : 'Preferred time';
  String get appointmentAnyTime =>
      isMyanmar ? 'Admin မှ အချိန်ညှိပေးမည်' : 'Admin can arrange the time';
  String get appointmentPickTime => isMyanmar ? 'ရွေးမယ်' : 'Pick';
  String get appointmentClearTime => isMyanmar ? 'အချိန်ဖျက်မယ်' : 'Clear time';
  String get appointmentBeautyGoal => isMyanmar ? 'Beauty goal' : 'Beauty goal';
  String get appointmentNotes =>
      isMyanmar ? 'Specialist အတွက် note' : 'Notes for specialist';
  String get appointmentSubmit =>
      isMyanmar ? 'Appointment request ပို့မယ်' : 'Send appointment request';
  String get appointmentGoalAcne => isMyanmar
      ? 'ဝက်ခြံ specialist consultation'
      : 'Specialist acne consultation';
  String get appointmentGoalRoutine => isMyanmar
      ? 'Routine review with specialist'
      : 'Routine review with specialist';
  String get appointmentGoalDarkSpots =>
      isMyanmar ? 'Dark spots review' : 'Dark spots review';
  String get appointmentNameRequired =>
      isMyanmar ? 'အမည်ထည့်ပါ။' : 'Please enter your name.';
  String get appointmentContactRequired => isMyanmar
      ? 'ဖုန်းနံပါတ် သို့မဟုတ် Email တစ်ခုထည့်ပါ။'
      : 'Please add a phone number or email.';
  String get appointmentEmailInvalid =>
      isMyanmar ? 'Email format မမှန်ပါ။' : 'Enter a valid email.';
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

  String get scanEmptySubtitle => isMyanmar
      ? 'မျက်နှာကို scan frame ထဲရှေ့တည့်တည့်ထားပြီး အလှအပစစ်ဆေးပါ။'
      : 'Center your face in the scan frame for a beauty check.';
  String get startLiveScan =>
      isMyanmar ? 'Live face scan စမယ်' : 'Start live face scan';
  String get startLiveScanSubtitle => isMyanmar
      ? 'Camera ကိုဖွင့်ပြီး face scan frame ဖမ်း၊ ပြီးရင် analyze လုပ်ပါ။'
      : 'Open the camera, lock a face scan frame, then analyze.';
  String get viewScanHistory =>
      isMyanmar ? 'Scan history ကြည့်မယ်' : 'View scan history';
  String get viewScanHistorySubtitle => isMyanmar
      ? 'Login ပြီးနောက် ယခင် scan များကို ဒီနေရာမှာကြည့်နိုင်မယ်။'
      : 'After login, saved scans will appear here.';
  String get trackProgress => isMyanmar ? 'Progress track' : 'Track progress';
  String get trackProgressSubtitle => isMyanmar
      ? 'Routine cycle အလိုက် score ပြောင်းလဲမှုကိုကြည့်ရန်။'
      : 'Review score changes across routine cycles.';
  String get scanReadySubtitle => isMyanmar
      ? 'နောက်ဆုံးစကင် ပြီးပါပြီ။ အခြေအနေနှင့် routine ကို ကြည့်ပါ။'
      : 'Latest scan is ready. Review severity and routine guidance below.';
  String get settingsTitle => settings;
  String get settingsSubtitle => isMyanmar
      ? 'ပရိုဖိုင်၊ Login၊ privacy နှင့် beauty preference များ။'
      : 'Profile, login, privacy, and beauty preferences.';
  String get accountAccess => isMyanmar ? 'အကောင့်' : 'Account';
  String get guestMode => isMyanmar ? 'Guest mode' : 'Guest mode';
  String get guestModeSubtitle => isMyanmar
      ? 'စကင်လုပ်နိုင်ပါတယ်။ သိမ်းရန်နှင့် appointment အတွက် Login လိုပါတယ်။'
      : 'Scan is available. Login is needed for saving and appointments.';
  String get signedIn => isMyanmar ? 'Login ဝင်ထားသည်' : 'Signed in';
  String get signedInSubtitle => isMyanmar
      ? 'Scan history၊ routine progress နှင့် orders ကို သိမ်းနိုင်ပါပြီ။'
      : 'Scan history, routine progress, and orders can be saved.';
  String get privacySafety =>
      isMyanmar ? 'Privacy / Safety' : 'Privacy / Safety';
  String get privacySafetySubtitle => isMyanmar
      ? 'မျက်နှာဓာတ်ပုံ၊ scan result နှင့် health note များကို ဂရုစိုက်ထားရန်။'
      : 'Face photos, scan results, and health notes need careful handling.';
  String get modelLearningPrivacy =>
      isMyanmar ? 'AI learning privacy' : 'AI learning privacy';
  String get modelLearningPrivacySubtitle => isMyanmar
      ? 'သင်ခွင့်ပြုမှသာ scan များကို AI တိုးတက်ရေး review queue သို့ပို့ပါမယ်။'
      : 'Only scans you allow can enter the AI improvement review queue.';
  String get modelLearningOn => isMyanmar ? 'ခွင့်ပြုထားသည်' : 'Allowed';
  String get modelLearningOff => isMyanmar ? 'မခွင့်ပြုထား' : 'Private';
  String get modelLearningLoading =>
      isMyanmar ? 'Privacy setting စစ်နေသည်' : 'Checking privacy setting';
  String get modelLearningBody => isMyanmar
      ? 'Guest scan များကို training မလုပ်ပါ။ Login scan များလည်း default private ဖြစ်ပြီး သင်ခွင့်ပြုမှသာ လူစစ်ဆေးပြီး model တိုးတက်ရေးတွင်သုံးနိုင်မည်။'
      : 'Guest scans are never used for training. Logged-in scans stay private by default and can only help improve the model after your permission and human review.';
  String get dataControl => isMyanmar ? 'Data control' : 'Data control';
  String get dataControlSubtitle => isMyanmar
      ? 'သိမ်းထားသော scan/report များကို user ကထိန်းချုပ်နိုင်မည်။'
      : 'Users will control saved scans and reports.';
  String get appPreferences =>
      isMyanmar ? 'App preferences' : 'App preferences';
  String get languageTitle => isMyanmar ? 'ဘာသာစကား' : 'Language';
  String get languageSubtitle => isMyanmar
      ? 'Default သည် မြန်မာဘာသာ ဖြစ်သည်။'
      : 'Myanmar is the default language.';
  String get skinProfile => isMyanmar ? 'Skin profile' : 'Skin profile';
  String get skinProfileSubtitle => isMyanmar
      ? 'Goal၊ allergy၊ sensitivity နှင့် routine quiz။'
      : 'Goals, allergies, sensitivity, and routine quiz.';
  String get notifications => isMyanmar ? 'သတိပေးချက်များ' : 'Notifications';
  String get notificationSubtitle => isMyanmar
      ? 'Routine reminder နှင့် နောက်စကင်သတိပေးချက်များ။'
      : 'Routine reminders and next scan check-ins.';
  String get savedProgress => isMyanmar ? 'Progress saving' : 'Progress saving';
  String get savedProgressSubtitle => isMyanmar
      ? 'Login ဝင်ပြီးနောက် scan comparison နှင့် routine streak များပြနိုင်မည်။'
      : 'After login, scan comparisons and routine streaks can appear.';
  String get apiConnection => isMyanmar ? 'API connection' : 'API connection';
  String get apiConnectionSubtitle => isMyanmar
      ? 'Demo backend နှင့် ချိတ်ဆက်မှု setting။'
      : 'Demo backend connection setting.';
  String get accountSecurity =>
      isMyanmar ? 'Account security' : 'Account security';
  String get accountSecuritySubtitle => isMyanmar
      ? 'Google login နှင့် secure session အတွက်။'
      : 'For Google login and secure sessions.';
  String get ready => isMyanmar ? 'Ready' : 'Ready';
  String get soon => isMyanmar ? 'Soon' : 'Soon';
  String get logout => isMyanmar ? 'Logout' : 'Logout';
  String get skinProfileDrawer => isMyanmar ? 'Skin profile' : 'Skin profile';
  String get skinProfileDrawerSubtitle => isMyanmar
      ? 'Goal၊ allergy၊ sensitivity၊ routine'
      : 'Goals, allergies, sensitivity, routine';
  String get analysisHistory =>
      isMyanmar ? 'စကင် မှတ်တမ်း' : 'Analysis history';
  String get analysisHistorySubtitle => isMyanmar
      ? 'ယခင်စကင်များနှင့် report များ'
      : 'Past scans and saved reports';
  String get specialistAppointment =>
      isMyanmar ? 'Specialist appointment' : 'Specialist appointment';
  String get specialistAppointmentSubtitle => isMyanmar
      ? 'ဝက်ခြံများ/ပြင်းလျှင် အကူအညီယူရန်'
      : 'Optional help for moderate or severe acne';
  String get care => isMyanmar ? 'Care' : 'Care';
  String get careSubtitle => isMyanmar
      ? 'နေ့စဉ် routine နှင့် beauty goal'
      : 'Daily routines and beauty goals';
  String get products => isMyanmar ? 'Products' : 'Products';
  String get productsSubtitle =>
      isMyanmar ? 'Routine ထုတ်ကုန်များ' : 'Routine product showcase';
  String get orders => isMyanmar ? 'Orders' : 'Orders';
  String get ordersSubtitle => isMyanmar
      ? 'မှာယူမှုများနှင့် payment မှတ်တမ်း'
      : 'Purchases and payment history';
  String get helpSafety => isMyanmar ? 'Help / Safety' : 'Help / Safety';
  String get helpSafetySubtitle => isMyanmar
      ? 'အကူအညီ၊ privacy နှင့် safety info'
      : 'Support, privacy, and safety info';
  String get beautyRoutines =>
      isMyanmar ? 'Beauty routines' : 'Beauty routines';
  String get beautyRoutinesSubtitle => isMyanmar
      ? 'နေ့စဉ် routine၊ reminder နှင့် check-in'
      : 'Daily care, reminders, and check-ins';
  String get todayBeautyPlan =>
      isMyanmar ? 'ဒီနေ့ beauty plan' : "Today's beauty plan";
  String get todayBeautyPlanSubtitle => isMyanmar
      ? 'စကင်ရလဒ်အတိုင်း နူးညံ့တဲ့ routine ကို ဆက်လုပ်ပါ။'
      : 'Keep the routine gentle and matched to your latest scan.';
  String get dailyRoutine => isMyanmar ? 'နေ့စဉ် routine' : 'Daily routine';
  String get progressTracker =>
      isMyanmar ? 'တိုးတက်မှု tracker' : 'Progress tracker';
  String get morningCare => isMyanmar ? 'မနက်' : 'Morning';
  String get nightCare => isMyanmar ? 'ည' : 'Night';
  String get gentleCleanser =>
      isMyanmar ? 'နူးညံ့စွာ သန့်စင်' : 'Gentle cleanse';
  String get sunscreen => isMyanmar ? 'Sunscreen လိမ်း' : 'Apply sunscreen';
  String get calmRoutine => isMyanmar ? 'Calm routine' : 'Calm routine';
  String get nextScan => isMyanmar ? 'နောက်စကင်' : 'Next scan';
  String get saveProgressHint => isMyanmar
      ? 'Progress သိမ်းရန် Login ဝင်နိုင်ပါတယ်။'
      : 'Login when you want to save progress.';
  String get oilBalance => isMyanmar ? 'အဆီထိန်းညှိ' : 'Oil balance';
  String get darkSpots => isMyanmar ? 'အမဲစက်' : 'Dark spots';
  String get acneCare => isMyanmar ? 'ဝက်ခြံ care' : 'Acne care';
  String get hydration => isMyanmar ? 'ရေဓာတ်ဖြည့်' : 'Hydration';
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
      'none' => 'မတွေ့',
      'mild' => 'အနည်းငယ်',
      'moderate' => 'အလယ်အလတ်',
      'severe' => 'ပြင်း',
      _ => severity,
    };
  }

  String concernLabel(String concern) {
    if (!isMyanmar) {
      return _titleCase(concern);
    }

    return switch (concern) {
      'dark_spots' => 'အမဲစက်',
      'oiliness' => 'အဆီပြန်',
      'dryness' => 'ခြောက်သွေ့',
      'redness' => 'နီမြန်း',
      'acne' => 'ဝက်ခြံ',
      'texture' => 'Texture',
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

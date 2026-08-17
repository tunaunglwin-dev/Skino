import 'package:flutter/material.dart';

import 'src/app/skin_ai_mobile_app.dart';
import 'src/features/analysis/data/routine_reminder_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await RoutineReminderService.initialize();
  runApp(const SkinAiMobileApp());
}

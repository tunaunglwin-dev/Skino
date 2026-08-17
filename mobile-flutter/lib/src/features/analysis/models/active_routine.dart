import 'skin_analysis_result.dart';
import 'treatment_package.dart';

class ActiveRoutine {
  const ActiveRoutine({
    required this.id,
    required this.skinAnalysisId,
    required this.routine,
    required this.startedAt,
    required this.today,
    required this.week,
    required this.skinAnalysis,
  });

  final int id;
  final int skinAnalysisId;
  final TreatmentPackage routine;
  final DateTime? startedAt;
  final RoutineToday today;
  final RoutineWeek week;
  final SkinAnalysisResult skinAnalysis;

  factory ActiveRoutine.fromJson(Map<String, dynamic> json) {
    return ActiveRoutine(
      id: int.parse(json['id'].toString()),
      skinAnalysisId: int.parse(json['skin_analysis_id'].toString()),
      routine: TreatmentPackage.fromJson(
        json['routine'] as Map<String, dynamic>,
      ),
      startedAt: DateTime.tryParse(json['started_at']?.toString() ?? ''),
      today: RoutineToday.fromJson(
        json['today'] as Map<String, dynamic>? ?? {},
      ),
      week: RoutineWeek.fromJson(json['week'] as Map<String, dynamic>? ?? {}),
      skinAnalysis: SkinAnalysisResult.fromJson(
        json['skin_analysis'] as Map<String, dynamic>,
      ),
    );
  }
}

class RoutineWeek {
  const RoutineWeek({
    required this.startDate,
    required this.endDate,
    required this.checkIns,
  });

  final String startDate;
  final String endDate;
  final List<RoutineDayCheckIn> checkIns;

  factory RoutineWeek.fromJson(Map<String, dynamic> json) {
    final items = json['check_ins'] as List<dynamic>? ?? const [];

    return RoutineWeek(
      startDate: json['start_date']?.toString() ?? '',
      endDate: json['end_date']?.toString() ?? '',
      checkIns: items
          .map(
            (item) => RoutineDayCheckIn.fromJson(item as Map<String, dynamic>),
          )
          .toList(),
    );
  }
}

class RoutineDayCheckIn {
  const RoutineDayCheckIn({
    required this.date,
    required this.label,
    required this.isToday,
    required this.morningDone,
    required this.nightDone,
  });

  final String date;
  final String label;
  final bool isToday;
  final bool morningDone;
  final bool nightDone;

  bool get isComplete => morningDone && nightDone;

  factory RoutineDayCheckIn.fromJson(Map<String, dynamic> json) {
    return RoutineDayCheckIn(
      date: json['date']?.toString() ?? '',
      label: json['label']?.toString() ?? '',
      isToday: json['is_today'] == true,
      morningDone: json['morning_done'] == true,
      nightDone: json['night_done'] == true,
    );
  }
}

class RoutineToday {
  const RoutineToday({
    required this.date,
    required this.morningDone,
    required this.nightDone,
  });

  final String date;
  final bool morningDone;
  final bool nightDone;

  factory RoutineToday.fromJson(Map<String, dynamic> json) {
    return RoutineToday(
      date: json['date']?.toString() ?? '',
      morningDone: json['morning_done'] == true,
      nightDone: json['night_done'] == true,
    );
  }
}

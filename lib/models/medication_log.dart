import 'package:did_you_take_a_pill/models/dose_schedule.dart';

/// 날짜별 + 약별 + 시간대별 복약 기록 모델.
/// 의학적 해석 없이 식별자와 상태(bool)만 저장.
class MedicationLog {
  final String medicationId;
  final String date; // yyyy-MM-dd
  final DoseTime doseTime;
  final bool isTaken;

  const MedicationLog({
    required this.medicationId,
    required this.date,
    required this.doseTime,
    this.isTaken = false,
  });

  MedicationLog copyWith({bool? isTaken}) {
    return MedicationLog(
      medicationId: medicationId,
      date: date,
      doseTime: doseTime,
      isTaken: isTaken ?? this.isTaken,
    );
  }

  /// SharedPreferences 키 생성.
  String get storageKey => 'taken_${medicationId}_${date}_${doseTime.name}';
}

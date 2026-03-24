import 'package:did_you_take_a_pill/models/dose_schedule.dart';

/// 개별 약 정보 모델.
/// 의학적 해석 없이 이름(String), 수치(int), 복용시간대(List)만 다룸.
class Medication {
  final String id;
  final String name;
  final int totalCount;
  final int remainingCount;
  final List<DoseTime> doseTimes;

  const Medication({
    required this.id,
    required this.name,
    required this.totalCount,
    required this.remainingCount,
    required this.doseTimes,
  });

  Medication copyWith({
    String? name,
    int? totalCount,
    int? remainingCount,
    List<DoseTime>? doseTimes,
  }) {
    return Medication(
      id: id,
      name: name ?? this.name,
      totalCount: totalCount ?? this.totalCount,
      remainingCount: remainingCount ?? this.remainingCount,
      doseTimes: doseTimes ?? this.doseTimes,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'totalCount': totalCount,
        'remainingCount': remainingCount,
        'doseTimes': doseTimes.map((dt) => dt.index).toList(),
      };

  factory Medication.fromJson(Map<String, dynamic> json) {
    return Medication(
      id: json['id'] as String,
      name: json['name'] as String,
      totalCount: json['totalCount'] as int? ?? 0,
      remainingCount: json['remainingCount'] as int? ?? 0,
      doseTimes: (json['doseTimes'] as List<dynamic>?)
              ?.map((e) => DoseTime.values[e as int])
              .toList() ??
          [DoseTime.morning],
    );
  }

  /// 해당 시간대에 복용해야 하는 약인지 확인.
  bool shouldTakeAt(DoseTime doseTime) {
    return doseTimes.contains(doseTime);
  }
}

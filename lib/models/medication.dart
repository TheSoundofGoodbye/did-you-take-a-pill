import 'package:did_you_take_a_pill/models/dose_schedule.dart';

/// 개별 약 정보 모델.
/// 의학적 해석 없이 이름(String), 수치(int), 복용시간대(List)만 다룸.
class Medication {
  final String id;
  final String name;
  final int totalDays;
  final int totalCount;
  final int remainingCount;
  final List<DoseTime> doseTimes;
  final String? imagePath;
  /// 약이 소진(remainingCount == 0)된 날짜. null이면 아직 남아있음.
  final DateTime? depletedDate;

  const Medication({
    required this.id,
    required this.name,
    required this.totalDays,
    required this.totalCount,
    required this.remainingCount,
    required this.doseTimes,
    this.imagePath,
    this.depletedDate,
  });

  /// 남은 일수 계산 (내림 — 완전히 복용 가능한 일수만 표시).
  int get remainingDays {
    if (doseTimes.isEmpty) return 0;
    // floor(): 아침+저녁 중 한 번만 남아도 '1일' 되는 왜곡 방지
    // 단, 알약이 남아있으면 최소 1일은 보장 (0으로 떨어지기 전까지)
    final days = (remainingCount / doseTimes.length).floor();
    return (remainingCount > 0 && days == 0) ? 1 : days;
  }

  /// imagePath를 명시적으로 null로 설정하려면 clearImage: true 사용.
  Medication copyWith({
    String? name,
    int? totalDays,
    int? totalCount,
    int? remainingCount,
    List<DoseTime>? doseTimes,
    String? imagePath,
    bool clearImage = false,
    DateTime? depletedDate,
    bool clearDepletedDate = false,
  }) {
    return Medication(
      id: id,
      name: name ?? this.name,
      totalDays: totalDays ?? this.totalDays,
      totalCount: totalCount ?? this.totalCount,
      remainingCount: remainingCount ?? this.remainingCount,
      doseTimes: doseTimes ?? this.doseTimes,
      imagePath: clearImage ? null : (imagePath ?? this.imagePath),
      depletedDate: clearDepletedDate ? null : (depletedDate ?? this.depletedDate),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'totalDays': totalDays,
        'totalCount': totalCount,
        'remainingCount': remainingCount,
        'doseTimes': doseTimes.map((dt) => dt.index).toList(),
        if (imagePath != null) 'imagePath': imagePath,
        if (depletedDate != null) 'depletedDate': depletedDate!.toIso8601String(),
      };

  factory Medication.fromJson(Map<String, dynamic> json) {
    final doseTimes = (json['doseTimes'] as List<dynamic>?)
            ?.map((e) => DoseTime.values[e as int])
            .toList() ??
        [DoseTime.morning];
    final totalCount = json['totalCount'] as int? ?? 0;
    // 기존 데이터 호환: totalDays가 없으면 totalCount/doseTimes.length로 역산
    final totalDays = json['totalDays'] as int? ??
        (doseTimes.isNotEmpty ? (totalCount / doseTimes.length).ceil() : 0);
    final depletedDateStr = json['depletedDate'] as String?;
    return Medication(
      id: json['id'] as String,
      name: json['name'] as String,
      totalDays: totalDays,
      totalCount: totalCount,
      remainingCount: json['remainingCount'] as int? ?? 0,
      doseTimes: doseTimes,
      imagePath: json['imagePath'] as String?,
      depletedDate: depletedDateStr != null ? DateTime.parse(depletedDateStr) : null,
    );
  }

  /// 해당 시간대에 복용해야 하는 약인지 확인.
  bool shouldTakeAt(DoseTime doseTime) {
    return doseTimes.contains(doseTime);
  }
}

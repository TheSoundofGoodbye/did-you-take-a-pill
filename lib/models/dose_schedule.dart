/// 복용 시간대 구분.
enum DoseTime {
  morning,   // 아침 (04:00~10:59)
  afternoon, // 점심 (11:00~16:59)
  evening,   // 저녁 (17:00~03:59)
}

extension DoseTimeExtension on DoseTime {
  String get displayName {
    switch (this) {
      case DoseTime.morning:
        return '아침';
      case DoseTime.afternoon:
        return '점심';
      case DoseTime.evening:
        return '저녁';
    }
  }

  String get timeLabel {
    switch (this) {
      case DoseTime.morning:
        return '09:00 AM';
      case DoseTime.afternoon:
        return '12:00 PM';
      case DoseTime.evening:
        return '06:00 PM';
    }
  }

  /// 현재 시각 기준으로 해당하는 DoseTime 반환.
  static DoseTime fromCurrentTime() {
    final hour = DateTime.now().hour;
    if (hour >= 4 && hour < 11) return DoseTime.morning;
    if (hour >= 11 && hour < 17) return DoseTime.afternoon;
    return DoseTime.evening;
  }
}

/// DoseTime 리스트의 표시 이름 생성 유틸.
String doseTimesDisplayName(List<DoseTime> doseTimes) {
  return doseTimes.map((dt) => dt.displayName).join(', ');
}

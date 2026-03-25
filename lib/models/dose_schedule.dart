/// 복용 시간대 구분.
enum DoseTime {
  wakeUp,    // 일어나자마자 (공복)
  morning,   // 아침식사
  afternoon, // 점심식사
  evening,   // 저녁식사
  bedTime,   // 자기전
}

extension DoseTimeExtension on DoseTime {
  String get displayName {
    switch (this) {
      case DoseTime.wakeUp:
        return '기상 후 약';
      case DoseTime.morning:
        return '아침약';
      case DoseTime.afternoon:
        return '점심약';
      case DoseTime.evening:
        return '저녁약';
      case DoseTime.bedTime:
        return '취침 전 약';
    }
  }

  /// 버튼에 표시될 짧은 레이블
  String get buttonLabel {
    switch (this) {
      case DoseTime.wakeUp:
        return '일어나자마자';
      case DoseTime.morning:
        return '아침';
      case DoseTime.afternoon:
        return '점심';
      case DoseTime.evening:
        return '저녁';
      case DoseTime.bedTime:
        return '자기전';
    }
  }

  String get timeLabel {
    switch (this) {
      case DoseTime.wakeUp:
        return '06:00 AM';
      case DoseTime.morning:
        return '08:00 AM';
      case DoseTime.afternoon:
        return '12:00 PM';
      case DoseTime.evening:
        return '06:00 PM';
      case DoseTime.bedTime:
        return '10:00 PM';
    }
  }

  /// 현재 시각 기준으로 가장 가까운 DoseTime 반환.
  static DoseTime fromCurrentTime() {
    final hour = DateTime.now().hour;
    if (hour >= 4 && hour < 9)  return DoseTime.wakeUp;
    if (hour >= 9 && hour < 11) return DoseTime.morning;
    if (hour >= 11 && hour < 17) return DoseTime.afternoon;
    if (hour >= 17 && hour < 22) return DoseTime.evening;
    return DoseTime.bedTime;
  }
}

/// DoseTime 리스트의 표시 이름 생성 유틸.
String doseTimesDisplayName(List<DoseTime> doseTimes) {
  return doseTimes.map((dt) => dt.displayName).join(', ');
}

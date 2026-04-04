import 'package:flutter/material.dart';
import 'package:did_you_take_a_pill/l10n/app_localizations.dart';

/// 복용 시간대 구분.
enum DoseTime {
  wakeUp,    // 일어나자마자 (공복)
  morning,   // 아침식사
  afternoon, // 점심식사
  evening,   // 저녁식사
  bedTime,   // 자기전
}

extension DoseTimeExtension on DoseTime {
  /// 화면에 표시할 시간대 이름 — 로컬라이즈.
  String displayName(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    switch (this) {
      case DoseTime.wakeUp:
        return l10n.doseTimeWakeUp;
      case DoseTime.morning:
        return l10n.doseTimeMorning;
      case DoseTime.afternoon:
        return l10n.doseTimeAfternoon;
      case DoseTime.evening:
        return l10n.doseTimeEvening;
      case DoseTime.bedTime:
        return l10n.doseTimeBedTime;
    }
  }

  /// 버튼에 표시될 짧은 레이블 — 로컬라이즈.
  String buttonLabel(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    switch (this) {
      case DoseTime.wakeUp:
        return l10n.doseButtonWakeUp;
      case DoseTime.morning:
        return l10n.doseButtonMorning;
      case DoseTime.afternoon:
        return l10n.doseButtonAfternoon;
      case DoseTime.evening:
        return l10n.doseButtonEvening;
      case DoseTime.bedTime:
        return l10n.doseButtonBedTime;
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
    if (hour >= 4  && hour < 8)  return DoseTime.wakeUp;    // 04:00~07:59
    if (hour >= 8  && hour < 11) return DoseTime.morning;   // 08:00~10:59
    if (hour >= 11 && hour < 17) return DoseTime.afternoon; // 11:00~16:59
    if (hour >= 17 && hour < 22) return DoseTime.evening;   // 17:00~21:59
    return DoseTime.bedTime;                                 // 22:00~03:59
  }
}

/// DoseTime 리스트의 표시 이름 생성 유틸.
String doseTimesDisplayName(BuildContext context, List<DoseTime> doseTimes) {
  return doseTimes.map((dt) => dt.displayName(context)).join(', ');
}

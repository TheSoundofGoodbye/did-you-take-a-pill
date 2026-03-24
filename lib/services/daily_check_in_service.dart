import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:did_you_take_a_pill/models/dose_schedule.dart';

/// 약별 + 시간대별 복약 여부를 토글하고 SharedPreferences에 저장하는 서비스.
/// 반환 값은 bool 뿐이며, 의학적 판단을 포함하지 않음.
class DailyCheckInService {
  final SharedPreferences _prefs;

  DailyCheckInService(this._prefs);

  String _key(String medicationId, DoseTime doseTime) {
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    return 'taken_${medicationId}_${today}_${doseTime.name}';
  }

  /// 특정 약 + 시간대의 오늘 복약 여부를 반환.
  bool getStatus(String medicationId, DoseTime doseTime) {
    return _prefs.getBool(_key(medicationId, doseTime)) ?? false;
  }

  /// 특정 약 + 시간대의 오늘 복약 여부를 토글하고 새 상태 반환.
  Future<bool> toggle(String medicationId, DoseTime doseTime) async {
    final key = _key(medicationId, doseTime);
    final current = _prefs.getBool(key) ?? false;
    final newValue = !current;
    await _prefs.setBool(key, newValue);
    return newValue;
  }
}

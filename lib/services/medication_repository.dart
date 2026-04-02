import 'dart:convert';
import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:did_you_take_a_pill/models/medication.dart';
import 'package:did_you_take_a_pill/models/dose_schedule.dart';

/// 약 목록 CRUD — SharedPreferences에 JSON 배열로 저장.
/// 의학적 해석 없이 데이터 저장/조회만 수행.
class MedicationRepository {
  static const _storageKey = 'medications_list';

  final SharedPreferences _prefs;

  MedicationRepository(this._prefs);

  /// 모든 약 목록을 반환.
  List<Medication> getAll() {
    final jsonStr = _prefs.getString(_storageKey);
    if (jsonStr == null || jsonStr.isEmpty) return [];
    final List<dynamic> jsonList = json.decode(jsonStr) as List<dynamic>;
    return jsonList
        .map((e) => Medication.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// 약 목록을 저장.
  Future<void> _saveAll(List<Medication> medications) async {
    final jsonStr = json.encode(medications.map((m) => m.toJson()).toList());
    await _prefs.setString(_storageKey, jsonStr);
  }

  /// 새 약 추가.
  Future<void> add(Medication medication) async {
    final list = getAll();
    list.add(medication);
    await _saveAll(list);
  }

  /// 약 정보 업데이트.
  Future<void> update(Medication medication) async {
    final list = getAll();
    final index = list.indexWhere((m) => m.id == medication.id);
    if (index >= 0) {
      list[index] = medication;
      await _saveAll(list);
    }
  }

  /// 약 삭제.
  Future<void> delete(String id) async {
    final list = getAll();
    list.removeWhere((m) => m.id == id);
    await _saveAll(list);
  }

  /// ID로 약 조회.
  Medication? getById(String id) {
    final list = getAll();
    try {
      return list.firstWhere((m) => m.id == id);
    } catch (_) {
      return null;
    }
  }

  /// 특정 시간대에 복용해야 하는 약 목록.
  List<Medication> getForDoseTime(DoseTime doseTime) {
    return getAll().where((m) => m.shouldTakeAt(doseTime)).toList();
  }

  /// ID 생성 유틸 — 밀리초 + 랜덤 4자리로 충돌 방지.
  static String generateId() {
    final now = DateTime.now().millisecondsSinceEpoch;
    final rand = _random.nextInt(9999);
    return '${now}_$rand';
  }
  static final _random = Random();
}

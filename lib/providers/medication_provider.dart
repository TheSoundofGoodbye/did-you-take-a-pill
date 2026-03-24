import 'package:flutter/foundation.dart';
import 'package:did_you_take_a_pill/models/medication.dart';
import 'package:did_you_take_a_pill/models/dose_schedule.dart';
import 'package:did_you_take_a_pill/services/medication_repository.dart';
import 'package:did_you_take_a_pill/services/daily_check_in_service.dart';
import 'package:did_you_take_a_pill/services/inventory_deduction_service.dart';

/// 복약 상태와 약 목록을 UI에 노출하는 ChangeNotifier.
/// 상태(bool)와 수치(int)만 다루며, 의학적 판단을 포함하지 않음.
class MedicationProvider extends ChangeNotifier {
  final MedicationRepository _repository;
  final DailyCheckInService _checkInService;
  final InventoryDeductionService _inventoryService;

  MedicationProvider({
    required MedicationRepository repository,
    required DailyCheckInService checkInService,
    required InventoryDeductionService inventoryService,
  })  : _repository = repository,
        _checkInService = checkInService,
        _inventoryService = inventoryService;

  /// 전체 약 목록.
  List<Medication> get medications => _repository.getAll();

  /// 현재 시간 기반 DoseTime.
  DoseTime get currentDoseTime => DoseTimeExtension.fromCurrentTime();

  /// 특정 시간대에 복용해야 하는 약 목록.
  List<Medication> getMedsForDoseTime(DoseTime doseTime) {
    return _repository.getForDoseTime(doseTime);
  }

  /// 약이 1개 이상 등록된 시간대만 반환 (빈 시간대 숨기기용).
  List<DoseTime> get activeDoseTimes {
    return DoseTime.values
        .where((dt) => getMedsForDoseTime(dt).isNotEmpty)
        .toList();
  }

  /// 특정 약 + 시간대의 오늘 복약 여부.
  bool isTaken(String medicationId, DoseTime doseTime) {
    return _checkInService.getStatus(medicationId, doseTime);
  }

  /// 특정 시간대의 모든 약이 복용 완료인지 확인.
  bool isAllTaken(DoseTime doseTime) {
    final meds = getMedsForDoseTime(doseTime);
    if (meds.isEmpty) return false;
    return meds.every((m) => isTaken(m.id, doseTime));
  }

  /// 복약 토글: true → deduct, false → restore.
  Future<void> toggleFor(String medicationId, DoseTime doseTime) async {
    final newStatus = await _checkInService.toggle(medicationId, doseTime);
    if (newStatus) {
      await _inventoryService.deduct(medicationId);
    } else {
      await _inventoryService.restore(medicationId);
    }
    notifyListeners();
  }

  /// 새 약 추가.
  Future<void> addMedication({
    required String name,
    required int totalCount,
    required List<DoseTime> doseTimes,
  }) async {
    final med = Medication(
      id: MedicationRepository.generateId(),
      name: name,
      totalCount: totalCount,
      remainingCount: totalCount,
      doseTimes: doseTimes,
    );
    await _repository.add(med);
    notifyListeners();
  }

  /// 약 삭제.
  Future<void> removeMedication(String id) async {
    await _repository.delete(id);
    notifyListeners();
  }

  /// 약 정보 업데이트.
  Future<void> updateMedication(Medication medication) async {
    await _repository.update(medication);
    notifyListeners();
  }
}

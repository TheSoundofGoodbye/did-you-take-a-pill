import 'package:flutter/foundation.dart';
import 'package:did_you_take_a_pill/models/medication.dart';
import 'package:did_you_take_a_pill/models/dose_schedule.dart';
import 'package:did_you_take_a_pill/services/medication_repository.dart';
import 'package:did_you_take_a_pill/services/daily_check_in_service.dart';
import 'package:did_you_take_a_pill/services/inventory_deduction_service.dart';
import 'package:did_you_take_a_pill/services/image_storage_service.dart';

/// 복약 상태와 약 목록을 UI에 노출하는 ChangeNotifier.
/// 상태(bool)와 수치(int)만 다루며, 의학적 판단을 포함하지 않음.
class MedicationProvider extends ChangeNotifier {
  final MedicationRepository _repository;
  final DailyCheckInService _checkInService;
  final InventoryDeductionService _inventoryService;
  final ImageStorageService _imageService;

  MedicationProvider({
    required MedicationRepository repository,
    required DailyCheckInService checkInService,
    required InventoryDeductionService inventoryService,
    ImageStorageService? imageService,
  })  : _repository = repository,
        _checkInService = checkInService,
        _inventoryService = inventoryService,
        _imageService = imageService ?? ImageStorageService();

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
    required int totalDays,
    required List<DoseTime> doseTimes,
    String? imagePath,
  }) async {
    final totalCount = totalDays * doseTimes.length;
    final med = Medication(
      id: MedicationRepository.generateId(),
      name: name,
      totalDays: totalDays,
      totalCount: totalCount,
      remainingCount: totalCount,
      doseTimes: doseTimes,
      imagePath: imagePath,
    );
    await _repository.add(med);
    notifyListeners();
  }

  /// 약 삭제 (연관 이미지 파일도 정리).
  Future<void> removeMedication(String id) async {
    final med = _repository.getById(id);
    if (med != null) {
      await _imageService.deleteImage(med.imagePath);
    }
    await _repository.delete(id);
    notifyListeners();
  }

  /// 약 정보 업데이트.
  Future<void> updateMedication(Medication medication) async {
    await _repository.update(medication);
    notifyListeners();
  }

  /// 소진된 약 자동 삭제: depletedDate가 있고 현재 4AM 기준일 이전이면 삭제.
  /// "하루 기준" = 새벽 4시. 약이 0이 된 당일에는 삭제하지 않고,
  /// 다음 날 4AM 이후에 삭제.
  Future<void> purgeDepletedMedications() async {
    final now = DateTime.now();
    // 오늘의 4AM 기준선: 현재 4시 이전이면 어제 4시
    final todayReset = DateTime(now.year, now.month, now.day, 4);
    final currentDayBoundary = now.isBefore(todayReset)
        ? todayReset.subtract(const Duration(days: 1))
        : todayReset;

    final meds = _repository.getAll();
    bool changed = false;
    for (final med in meds) {
      if (med.depletedDate != null &&
          med.remainingCount <= 0 &&
          med.depletedDate!.isBefore(currentDayBoundary)) {
        await _imageService.deleteImage(med.imagePath);
        await _repository.delete(med.id);
        changed = true;
      }
    }
    if (changed) notifyListeners();
  }
}

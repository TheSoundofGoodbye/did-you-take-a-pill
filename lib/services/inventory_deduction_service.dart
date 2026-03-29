import 'package:did_you_take_a_pill/services/medication_repository.dart';

/// 약별 재고를 관리하는 서비스.
/// 수치(int)만 다루며, 의학적 해석을 포함하지 않음.
class InventoryDeductionService {
  final MedicationRepository _repository;

  InventoryDeductionService(this._repository);

  /// 남은 갯수를 1 차감. 0 미만 불가.
  /// 0이 되면 depletedDate를 기록하여 자동 삭제 대상으로 표시.
  Future<int> deduct(String medicationId) async {
    final med = _repository.getById(medicationId);
    if (med == null) return 0;

    final remaining = med.remainingCount;
    if (remaining <= 0) return 0;

    final newValue = remaining - 1;
    final updated = med.copyWith(
      remainingCount: newValue,
      depletedDate: newValue == 0 ? DateTime.now() : null,
    );
    await _repository.update(updated);
    return newValue;
  }

  /// 남은 갯수를 1 복원. totalCount 초과 불가.
  /// 복원 시 depletedDate 초기화.
  Future<int> restore(String medicationId) async {
    final med = _repository.getById(medicationId);
    if (med == null) return 0;

    final remaining = med.remainingCount;
    if (remaining >= med.totalCount) return med.totalCount;

    final newValue = remaining + 1;
    await _repository.update(
      med.copyWith(remainingCount: newValue, clearDepletedDate: true),
    );
    return newValue;
  }
}

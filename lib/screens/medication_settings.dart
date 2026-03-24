import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:did_you_take_a_pill/models/medication.dart';
import 'package:did_you_take_a_pill/models/dose_schedule.dart';
import 'package:did_you_take_a_pill/providers/medication_provider.dart';


/// 약 설정 화면 — 약 리스트 편집 + 추가/삭제/수정.
class MedicationSettings extends StatelessWidget {
  const MedicationSettings({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1A),
      appBar: AppBar(
        title: const Text(
          '약 설정',
          style: TextStyle(fontWeight: FontWeight.w700, color: Colors.white),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white70),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: SizedBox(
          width: double.infinity,
          height: 64,
          child: ElevatedButton.icon(
            key: const Key('add_medication_button'),
            onPressed: () => _showAddSheet(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4ECDC4),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
              elevation: 0,
            ),
            icon: const Icon(Icons.add, size: 26),
            label: const Text(
              '약 추가',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
            ),
          ),
        ),
      ),
      body: Consumer<MedicationProvider>(
        builder: (context, provider, _) {
          final meds = provider.medications;

          if (meds.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.medication_liquid_rounded,
                      size: 80, color: Colors.white.withValues(alpha: 0.15)),
                  const SizedBox(height: 20),
                  Text('등록된 약이 없습니다',
                      style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w600,
                          color: Colors.white.withValues(alpha: 0.5))),
                  const SizedBox(height: 10),
                  Text('아래 + 버튼을 눌러 추가하세요',
                      style: TextStyle(
                          fontSize: 18,
                          color: Colors.white.withValues(alpha: 0.35))),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
            itemCount: meds.length,
            itemBuilder: (context, index) =>
                _MedicationCard(medication: meds[index]),
          );
        },
      ),
    );
  }

  void _showAddSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1A1A2E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => const _MedicationFormSheet(),
    );
  }
}

/// 개별 약 카드 위젯 — 탭하면 수정 바텀시트 열림.
class _MedicationCard extends StatelessWidget {
  final Medication medication;
  const _MedicationCard({required this.medication});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showEditSheet(context),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A2E),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: const Color(0xFF7C83FD).withValues(alpha: 0.15)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // 알약 아이콘
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: const Color(0xFF7C83FD).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.medication_rounded,
                      color: Color(0xFF7C83FD), size: 32),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(medication.name,
                          style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: Colors.white)),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: [
                          _infoChip(
                            '남은 약 ${medication.remainingCount}/${medication.totalCount}',
                            medication.remainingCount <= 3
                                ? const Color(0xFFFF6B6B)
                                : const Color(0xFF4ECDC4),
                          ),
                          _infoChip(
                            doseTimesDisplayName(medication.doseTimes),
                            const Color(0xFF7C83FD),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // 수정/삭제 버튼
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _showEditSheet(context),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF7C83FD),
                      side: const BorderSide(color: Color(0xFF7C83FD), width: 1.5),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text('수정',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _confirmDelete(context),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFFF6B6B),
                      side: BorderSide(
                          color: const Color(0xFFFF6B6B).withValues(alpha: 0.5),
                          width: 1.5),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text('삭제',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showEditSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1A1A2E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => _MedicationFormSheet(medication: medication),
    );
  }

  Widget _infoChip(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(text,
          style: TextStyle(
              fontSize: 14, color: color, fontWeight: FontWeight.w600)),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('약 삭제',
            style:
                TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
        content: Text('\'${medication.name}\'을(를) 삭제하시겠습니까?',
            style: TextStyle(color: Colors.white.withValues(alpha: 0.6))),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('취소',
                style:
                    TextStyle(color: Colors.white.withValues(alpha: 0.5))),
          ),
          TextButton(
            onPressed: () {
              context
                  .read<MedicationProvider>()
                  .removeMedication(medication.id);
              Navigator.pop(ctx);
            },
            child: const Text('삭제',
                style: TextStyle(color: Color(0xFFFF6B6B))),
          ),
        ],
      ),
    );
  }
}

/// 약 추가/수정 공용 바텀시트.
/// medication이 null이면 추가 모드, 존재하면 수정 모드.
class _MedicationFormSheet extends StatefulWidget {
  final Medication? medication;
  const _MedicationFormSheet({this.medication});

  @override
  State<_MedicationFormSheet> createState() => _MedicationFormSheetState();
}

class _MedicationFormSheetState extends State<_MedicationFormSheet> {
  late final TextEditingController _nameController;
  late final TextEditingController _countController;
  bool get _isEditMode => widget.medication != null;

  late final Map<DoseTime, bool> _selectedTimes;

  @override
  void initState() {
    super.initState();
    final med = widget.medication;
    _nameController = TextEditingController(text: med?.name ?? '');
    _countController = TextEditingController(
        text: med != null ? med.totalCount.toString() : '');
    _selectedTimes = {
      DoseTime.morning: med?.doseTimes.contains(DoseTime.morning) ?? true,
      DoseTime.afternoon:
          med?.doseTimes.contains(DoseTime.afternoon) ?? false,
      DoseTime.evening: med?.doseTimes.contains(DoseTime.evening) ?? false,
    };
  }

  @override
  void dispose() {
    _nameController.dispose();
    _countController.dispose();
    super.dispose();
  }

  bool get _isValid {
    final hasName = _nameController.text.trim().isNotEmpty;
    final hasCount = (int.tryParse(_countController.text.trim()) ?? 0) > 0;
    final hasTime = _selectedTimes.values.any((v) => v);
    return hasName && hasCount && hasTime;
  }

  List<DoseTime> get _selectedDoseTimes {
    return _selectedTimes.entries
        .where((e) => e.value)
        .map((e) => e.key)
        .toList();
  }

  Future<void> _submit() async {
    if (!_isValid) return;
    final provider = context.read<MedicationProvider>();

    if (_isEditMode) {
      final updated = widget.medication!.copyWith(
        name: _nameController.text.trim(),
        totalCount: int.parse(_countController.text.trim()),
        doseTimes: _selectedDoseTimes,
      );
      await provider.updateMedication(updated);
    } else {
      await provider.addMedication(
        name: _nameController.text.trim(),
        totalCount: int.parse(_countController.text.trim()),
        doseTimes: _selectedDoseTimes,
      );
    }

    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
          24, 24, 24, 24 + MediaQuery.of(context).viewInsets.bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 핸들바
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(_isEditMode ? '약 수정' : '약 추가',
              style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Colors.white)),
          const SizedBox(height: 20),

          // 약 이름
          _buildLabel('약 이름'),
          const SizedBox(height: 8),
          _buildTextField(
            controller: _nameController,
            hint: '예: 고혈압약',
            key: 'medication_name_input',
          ),
          const SizedBox(height: 16),

          // 총 갯수
          _buildLabel('총 갯수'),
          const SizedBox(height: 8),
          _buildTextField(
            controller: _countController,
            hint: '예: 30',
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            key: 'medication_count_input',
          ),
          const SizedBox(height: 20),

          // 복용주기
          _buildLabel('복용주기'),
          const SizedBox(height: 8),
          Row(
            children: [
              _buildChip('매일', true, large: true),
              const SizedBox(width: 8),
              _buildChip('기타', false, large: false),
            ],
          ),
          const SizedBox(height: 16),

          // 복용시기 (체크박스)
          _buildLabel('복용시기'),
          const SizedBox(height: 8),
          Row(
            children: [
              _buildTimeCheckbox(DoseTime.morning),
              const SizedBox(width: 12),
              _buildTimeCheckbox(DoseTime.afternoon),
              const SizedBox(width: 12),
              _buildTimeCheckbox(DoseTime.evening),
            ],
          ),
          const SizedBox(height: 24),

          // 저장 버튼 (높이 두배)
          ElevatedButton(
            key: const Key('save_medication_button'),
            onPressed: _isValid ? _submit : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF7C83FD),
              disabledBackgroundColor: const Color(0xFF2A2A40),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 32),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
            child: Text(_isEditMode ? '수정' : '저장',
                style: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  Widget _buildChip(String label, bool isSelected, {bool large = true}) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: large ? 20 : 14,
        vertical: large ? 10 : 7,
      ),
      decoration: BoxDecoration(
        color: isSelected
            ? const Color(0xFF7C83FD).withValues(alpha: 0.2)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isSelected
              ? const Color(0xFF7C83FD)
              : Colors.white.withValues(alpha: 0.15),
          width: 1.5,
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: large ? 15 : 13,
          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
          color: isSelected
              ? const Color(0xFF7C83FD)
              : Colors.white.withValues(alpha: 0.35),
        ),
      ),
    );
  }

  Widget _buildTimeCheckbox(DoseTime doseTime) {
    final isChecked = _selectedTimes[doseTime] ?? false;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedTimes[doseTime] = !isChecked;
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: isChecked
                ? const Color(0xFF4ECDC4).withValues(alpha: 0.15)
                : const Color(0xFF0F0F1A),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isChecked
                  ? const Color(0xFF4ECDC4)
                  : Colors.white.withValues(alpha: 0.12),
              width: 1.5,
            ),
          ),
          child: Column(
            children: [
              Icon(
                isChecked
                    ? Icons.check_circle_rounded
                    : Icons.circle_outlined,
                size: 22,
                color: isChecked
                    ? const Color(0xFF4ECDC4)
                    : Colors.white.withValues(alpha: 0.25),
              ),
              const SizedBox(height: 6),
              Text(
                doseTime.displayName,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: isChecked ? FontWeight.w700 : FontWeight.w400,
                  color: isChecked
                      ? const Color(0xFF4ECDC4)
                      : Colors.white.withValues(alpha: 0.4),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(text,
        style: TextStyle(
            fontSize: 13,
            color: Colors.white.withValues(alpha: 0.5),
            letterSpacing: 1));
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
    String? key,
  }) {
    return TextField(
      key: key != null ? Key(key) : null,
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      onChanged: (_) => setState(() {}),
      style: const TextStyle(fontSize: 16, color: Colors.white),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.2)),
        filled: true,
        fillColor: const Color(0xFF0F0F1A),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide:
                const BorderSide(color: Color(0xFF7C83FD), width: 2)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }
}

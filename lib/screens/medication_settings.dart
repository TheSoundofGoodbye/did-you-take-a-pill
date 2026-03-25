import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:did_you_take_a_pill/models/medication.dart';
import 'package:did_you_take_a_pill/models/dose_schedule.dart';
import 'package:did_you_take_a_pill/providers/medication_provider.dart';
import 'package:did_you_take_a_pill/services/image_storage_service.dart';


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
    final medCount = context.read<MedicationProvider>().medications.length;
    if (medCount >= 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('약은 최대 4개까지 등록할 수 있습니다.',
              style: TextStyle(fontSize: 16)),
          backgroundColor: Color(0xFFFF6B6B),
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      enableDrag: false, // 실수로 닫히는 사고 방지
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
                // 약 사진 썸네일 또는 기본 아이콘 (크기 확대: 80x80)
                _buildThumbnail(),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                          medication.name.isNotEmpty
                              ? medication.name
                              : '약 (이름 없음)',
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
                            '남은 ${medication.remainingDays}일 / ${medication.totalDays}일분',
                            medication.remainingDays <= 3
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

  /// 약 사진 썸네일 또는 기본 알약 아이콘 (80x80).
  Widget _buildThumbnail() {
    final hasImage =
        medication.imagePath != null && medication.imagePath!.isNotEmpty;

    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        color: const Color(0xFF7C83FD).withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(16),
      ),
      clipBehavior: Clip.antiAlias,
      child: hasImage
          ? (kIsWeb
              ? Image.network(medication.imagePath!,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) =>
                      _defaultIcon())
              : Image.file(File(medication.imagePath!),
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) =>
                      _defaultIcon()))
          : _defaultIcon(),
    );
  }

  Widget _defaultIcon() {
    return const Center(
      child: Icon(Icons.medication_rounded,
          color: Color(0xFF7C83FD), size: 40),
    );
  }

  void _showEditSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      enableDrag: false, // 실수로 닫히는 사고 방지
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
    final displayName =
        medication.name.isNotEmpty ? medication.name : '이 약';
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('약 삭제',
            style:
                TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
        content: Text('\'$displayName\'을(를) 삭제하시겠습니까?',
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
  int _prescriptionDays = 7;
  bool get _isEditMode => widget.medication != null;

  late final Map<DoseTime, bool> _selectedTimes;
  final ImageStorageService _imageService = ImageStorageService();
  String? _selectedImagePath;

  // 유효성 검사 실패 시 하이라이트용 플래그
  bool _showValidationErrors = false;

  @override
  void initState() {
    super.initState();
    final med = widget.medication;
    _nameController = TextEditingController(text: med?.name ?? '');
    _prescriptionDays = med?.totalDays ?? 7;
    _selectedTimes = {
      DoseTime.wakeUp:    med?.doseTimes.contains(DoseTime.wakeUp) ?? false,
      DoseTime.morning:   med?.doseTimes.contains(DoseTime.morning) ?? true,
      DoseTime.afternoon: med?.doseTimes.contains(DoseTime.afternoon) ?? false,
      DoseTime.evening:   med?.doseTimes.contains(DoseTime.evening) ?? false,
      DoseTime.bedTime:   med?.doseTimes.contains(DoseTime.bedTime) ?? false,
    };
    _selectedImagePath = med?.imagePath;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  bool get _hasNameOrImage {
    final hasName = _nameController.text.trim().isNotEmpty;
    final hasImage =
        _selectedImagePath != null && _selectedImagePath!.isNotEmpty;
    return hasName || hasImage;
  }

  bool get _hasDays {
    return _prescriptionDays > 0;
  }

  bool get _hasTime {
    return _selectedTimes.values.any((v) => v);
  }

  bool get _isValid => _hasNameOrImage && _hasDays && _hasTime;

  List<DoseTime> get _selectedDoseTimes {
    return _selectedTimes.entries
        .where((e) => e.value)
        .map((e) => e.key)
        .toList();
  }

  /// 저장 버튼이 비활성일 때 누르면 → 필수입력란 하이라이트.
  void _onSavePressed() {
    if (_isValid) {
      _submit();
    } else {
      setState(() => _showValidationErrors = true);
    }
  }

  /// 이미지 소스 선택 바텀시트.
  void _showImageSourcePicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A2E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
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
              const Text('사진 등록 방법',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Colors.white)),
              const SizedBox(height: 16),
              _buildSourceOption(
                icon: Icons.camera_alt_rounded,
                label: '카메라로 촬영',
                onTap: () {
                  Navigator.pop(ctx);
                  _pickImage(ImageSource.camera);
                },
              ),
              const SizedBox(height: 8),
              _buildSourceOption(
                icon: Icons.photo_library_rounded,
                label: '갤러리에서 선택',
                onTap: () {
                  Navigator.pop(ctx);
                  _pickImage(ImageSource.gallery);
                },
              ),
              if (_selectedImagePath != null) ...[
                const SizedBox(height: 8),
                _buildSourceOption(
                  icon: Icons.delete_outline_rounded,
                  label: '사진 삭제',
                  color: const Color(0xFFFF6B6B),
                  onTap: () {
                    Navigator.pop(ctx);
                    setState(() => _selectedImagePath = null);
                  },
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSourceOption({
    required IconData icon,
    required String label,
    VoidCallback? onTap,
    Color color = const Color(0xFF4ECDC4),
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(width: 16),
            Text(label,
                style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    color: color)),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    final path = await _imageService.pickAndCropImage(
      context: context,
      source: source,
    );
    if (path != null) {
      setState(() {
        _selectedImagePath = path;
        _showValidationErrors = false;
      });
    }
  }

  Future<void> _submit() async {
    if (!_isValid) return;
    final provider = context.read<MedicationProvider>();
    final name = _nameController.text.trim();
    final totalDays = _prescriptionDays;

    if (_isEditMode) {
      final totalCount = totalDays * _selectedDoseTimes.length;
      final updated = widget.medication!.copyWith(
        name: name,
        totalDays: totalDays,
        totalCount: totalCount,
        doseTimes: _selectedDoseTimes,
        imagePath: _selectedImagePath,
        clearImage: _selectedImagePath == null,
      );
      await provider.updateMedication(updated);
    } else {
      await provider.addMedication(
        name: name,
        totalDays: totalDays,
        doseTimes: _selectedDoseTimes,
        imagePath: _selectedImagePath,
      );
    }

    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
          24, 24, 24, 24 + MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
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
            const SizedBox(height: 12),
            Text(_isEditMode ? '약 수정' : '약 추가',
                style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Colors.white)),
            const SizedBox(height: 12),

            // ── 사진 등록 영역 ──
            _buildLabel('약 사진 (선택)'),
            const SizedBox(height: 6),
            _buildImagePicker(),
            const SizedBox(height: 12),

            // 약 이름 (optional - 사진이 있으면 생략 가능)
            _buildLabel('약 이름 (사진이 있으면 생략 가능)'),
            const SizedBox(height: 6),
            _buildValidatedTextField(
              controller: _nameController,
              hint: '예: 고혈압약',
              key: 'medication_name_input',
              hasError: _showValidationErrors && !_hasNameOrImage,
              errorText: '사진 또는 이름을 입력하세요',
            ),
            const SizedBox(height: 12),

            // 처방 일수
            _buildLabel('처방 일수 (며칠 치 약인가요?)'),
            const SizedBox(height: 8),
            _buildDaysSelector(),
            const SizedBox(height: 12),

            // 언제 드시는 약인가요? (5개 버튼)
            const Text(
              '언제 드시는 약인가요?',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            if (_showValidationErrors && !_hasTime)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text('복용 시기를 하나 이상 선택하세요',
                    style: TextStyle(
                        fontSize: 14,
                        color: const Color(0xFFFF6B6B).withValues(alpha: 0.9))),
              ),
            const SizedBox(height: 8),
            _buildDoseTimeButtons(),
            const SizedBox(height: 16),

            // 저장 버튼 — 항상 활성, 미입력 시 하이라이트
            ElevatedButton(
              key: const Key('save_medication_button'),
              onPressed: _onSavePressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: _isValid
                    ? const Color(0xFF4ECDC4)   // 민트 — 불투명 고대비
                    : const Color(0xFF1E1E30),  // 비활성: 매우 어두운 배경
                foregroundColor: _isValid ? Colors.white : Colors.white38,
                shadowColor: _isValid
                    ? const Color(0xFF4ECDC4).withValues(alpha: 0.5)
                    : Colors.transparent,
                elevation: _isValid ? 6 : 0,
                padding: const EdgeInsets.symmetric(vertical: 20),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: _isValid
                      ? BorderSide.none
                      : BorderSide(
                          color: Colors.white.withValues(alpha: 0.2),
                          width: 1.5),
                ),
              ),
              child: Text(_isEditMode ? '수정' : '저장',
                  style: const TextStyle(
                      fontSize: 22, fontWeight: FontWeight.w800)),
            ),
          ],
        ),
      ),
    );
  }

  /// 사진 등록/미리보기 영역.
  Widget _buildImagePicker() {
    final hasImage =
        _selectedImagePath != null && _selectedImagePath!.isNotEmpty;

    return GestureDetector(
      onTap: _showImageSourcePicker,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: double.infinity,
        height: 120,
        decoration: BoxDecoration(
          color: const Color(0xFF0F0F1A),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: hasImage
                ? const Color(0xFF4ECDC4).withValues(alpha: 0.4)
                : (_showValidationErrors && !_hasNameOrImage)
                    ? const Color(0xFFFF6B6B).withValues(alpha: 0.6)
                    : Colors.white.withValues(alpha: 0.12),
            width: 1.5,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: hasImage ? _buildImagePreview() : _buildImagePlaceholder(),
      ),
    );
  }

  Widget _buildImagePlaceholder() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.add_a_photo_rounded,
            size: 40, color: Colors.white.withValues(alpha: 0.55)),
        const SizedBox(height: 10),
        Text('사진으로 등록  (터치)',
            style: TextStyle(
                fontSize: 17,
                color: Colors.white.withValues(alpha: 0.75),
                fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _buildImagePreview() {
    return Stack(
      fit: StackFit.expand,
      children: [
        kIsWeb
            ? Image.network(_selectedImagePath!,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                    _buildImagePlaceholder())
            : Image.file(File(_selectedImagePath!),
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                    _buildImagePlaceholder()),
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.black.withValues(alpha: 0.7),
                ],
              ),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.edit_rounded, color: Colors.white70, size: 18),
                SizedBox(width: 6),
                Text('터치하여 변경',
                    style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                        fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// 키보드 없이 일수를 조절하는 스텝퍼 + 프리셋 버튼
  Widget _buildDaysSelector() {
    Widget buildPresetChip(int days) {
      final isSelected = _prescriptionDays == days;
      return GestureDetector(
        onTap: () {
          setState(() {
            _prescriptionDays = days;
            _showValidationErrors = false;
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF4ECDC4) : const Color(0xFF2A2A3E),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected ? const Color(0xFF4ECDC4) : Colors.white.withValues(alpha: 0.2),
              width: 1.5,
            ),
          ),
          child: Text('$days일',
              style: TextStyle(
                fontSize: 16,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                color: isSelected ? const Color(0xFF0F0F1A) : Colors.white.withValues(alpha: 0.8),
              )),
        ),
      );
    }

    return Container(
      decoration: (_showValidationErrors && !_hasDays)
          ? BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFFF6B6B).withValues(alpha: 0.8), width: 1.5))
          : null,
      padding: (_showValidationErrors && !_hasDays) ? const EdgeInsets.all(6) : EdgeInsets.zero,
      child: Column(
        children: [
          // 1. 대형 스텝퍼 [ - ]  [ 7 일 ]  [ + ]
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildStepperButton(
                icon: Icons.remove_rounded,
                onTap: () {
                  if (_prescriptionDays > 1) {
                    setState(() {
                      _prescriptionDays--;
                      _showValidationErrors = false;
                    });
                  }
                },
              ),
              const SizedBox(width: 20),
              Container(
                alignment: Alignment.center,
                width: 70,
                child: Text(
                  '$_prescriptionDays 일',
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 20),
              _buildStepperButton(
                icon: Icons.add_rounded,
                onTap: () {
                  if (_prescriptionDays < 90) {
                    setState(() {
                      _prescriptionDays++;
                      _showValidationErrors = false;
                    });
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: 12),
          // 2. 자주 쓰는 프리셋 버튼 (3일, 7일, 14일, 30일)
          Wrap(
            spacing: 12,
            runSpacing: 10,
            alignment: WrapAlignment.center,
            children: [
              buildPresetChip(3),
              buildPresetChip(7),
              buildPresetChip(14),
              buildPresetChip(30),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStepperButton({required IconData icon, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF2A2A3E),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
        ),
        child: Icon(icon, size: 32, color: Colors.white),
      ),
    );
  }

  /// 언제 드시는 약인가요? — 3줄 고정 배치, 동일 크기 버튼.
  Widget _buildDoseTimeButtons() {
    final hasError = _showValidationErrors && !_hasTime;

    Widget chip(DoseTime dt) {
      final isSelected = _selectedTimes[dt] ?? false;
      return Expanded(
        child: GestureDetector(
          onTap: () => setState(() {
            _selectedTimes[dt] = !isSelected;
            _showValidationErrors = false;
          }),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 10),
            decoration: BoxDecoration(
              color: isSelected
                  ? const Color(0xFF4ECDC4).withValues(alpha: 0.2) // 선택: 밝은 녹색 배경
                  : const Color(0xFF2A2A3E),                        // 미선택: 회색 — 배경과 구분됨
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isSelected
                    ? const Color(0xFF4ECDC4)                       // 선택: 밝은 녹색 테두리
                    : Colors.white.withValues(alpha: 0.35),         // 미선택: 더 밝은 테두리
                width: isSelected ? 2.5 : 1.5,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  isSelected
                      ? Icons.check_circle_rounded
                      : Icons.circle_outlined,
                  size: 20,
                  color: isSelected
                      ? const Color(0xFF4ECDC4)
                      : Colors.white.withValues(alpha: 0.6),
                ),
                const SizedBox(width: 6),
                Text(
                  dt.buttonLabel,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected
                        ? Colors.white
                        : Colors.white.withValues(alpha: 0.80),   // 미선택도 선명하게
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final times = DoseTime.values; // wakeUp, morning, afternoon, evening, bedTime
    return Container(
      decoration: hasError
          ? BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                  color: const Color(0xFFFF6B6B).withValues(alpha: 0.6),
                  width: 1.5))
          : null,
      padding: hasError ? const EdgeInsets.all(6) : EdgeInsets.zero,
      child: Column(
        children: [
          // 1행 (3개): 아침식사 / 점심식사 / 저녁식사
          Row(
            children: [
              chip(times[1]),
              const SizedBox(width: 8),
              chip(times[2]),
              const SizedBox(width: 8),
              chip(times[3]),
            ],
          ),
          const SizedBox(height: 10),
          // 2행 (2개): 일어나자마자 / 자기전
          Row(
            children: [
              chip(times[0]),
              const SizedBox(width: 8),
              chip(times[4]),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(text,
        style: const TextStyle(
            fontSize: 16,
            color: Colors.white,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5));
  }

  /// 유효성 검사 에러 표시가 포함된 텍스트필드.
  Widget _buildValidatedTextField({
    required TextEditingController controller,
    required String hint,
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
    String? key,
    bool hasError = false,
    String? errorText,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          key: key != null ? Key(key) : null,
          controller: controller,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          onChanged: (_) => setState(() => _showValidationErrors = false),
          style: const TextStyle(fontSize: 16, color: Colors.white),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.35)),
            filled: true,
            fillColor: const Color(0xFF22223A),  // 배경보다 밝은 회색으로 필드 영역 구분
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.25))),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                    const BorderSide(color: Color(0xFF4ECDC4), width: 2)), // 포커스: 민트
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: hasError
                    ? BorderSide(
                        color: const Color(0xFFFF6B6B).withValues(alpha: 0.8),
                        width: 1.5)
                    : BorderSide(color: Colors.white.withValues(alpha: 0.25))),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
        if (hasError && errorText != null)
          Padding(
            padding: const EdgeInsets.only(top: 4, left: 4),
            child: Text(errorText,
                style: TextStyle(
                    fontSize: 12,
                    color: const Color(0xFFFF6B6B).withValues(alpha: 0.8))),
          ),
      ],
    );
  }
}

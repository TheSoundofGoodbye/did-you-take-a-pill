import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:did_you_take_a_pill/models/dose_schedule.dart';
import 'package:did_you_take_a_pill/models/medication.dart';
import 'package:did_you_take_a_pill/providers/medication_provider.dart';
import 'package:did_you_take_a_pill/screens/medication_settings.dart';

/// 메인 대시보드 — 날짜/시간 + 캡슐형 슬라이드 복약 토글.
class MainDashboard extends StatefulWidget {
  const MainDashboard({super.key});

  @override
  State<MainDashboard> createState() => _MainDashboardState();
}

class _MainDashboardState extends State<MainDashboard> {
  PageController? _pageController;
  late Timer _clockTimer;
  String _time = '';
  String _date = '';
  int _currentPage = 0;
  List<DoseTime> _activeDoseTimes = [];

  @override
  void initState() {
    super.initState();
    _updateClock();
    _clockTimer = Timer.periodic(
      const Duration(seconds: 1),
      (_) => _updateClock(),
    );
  }

  /// activeDoseTimes 변경 시 PageController 재생성.
  /// build 중 호출되므로 post-frame callback에서 setState.
  void _syncPageController(List<DoseTime> newActive) {
    if (_listEquals(newActive, _activeDoseTimes) &&
        _pageController != null) {
      return;
    }

    final oldActive = _activeDoseTimes;
    _activeDoseTimes = List.from(newActive);

    // 기존 페이지 위치 복원 시도: 이전에 보고 있던 DoseTime이 새 목록에도 있으면 유지
    int targetPage;
    if (oldActive.isNotEmpty &&
        _currentPage < oldActive.length &&
        newActive.contains(oldActive[_currentPage])) {
      targetPage = newActive.indexOf(oldActive[_currentPage]);
    } else {
      // 첫 진입이거나 이전 페이지의 doseTime이 없어진 경우 → 현재 시간 기준 (없으면 가장 가까운 이후 시간대)
      final currentDose = DoseTimeExtension.fromCurrentTime();
      int idx = newActive.indexOf(currentDose);
      
      if (idx == -1 && newActive.isNotEmpty) {
        final currentDoseIndex = DoseTime.values.indexOf(currentDose);
        for (int i = 1; i < DoseTime.values.length; i++) {
          final nextDoseIndex = (currentDoseIndex + i) % DoseTime.values.length;
          final nextDose = DoseTime.values[nextDoseIndex];
          if (newActive.contains(nextDose)) {
            idx = newActive.indexOf(nextDose);
            break;
          }
        }
      }
      targetPage = idx >= 0 ? idx : 0;
    }

    _pageController?.dispose();
    _pageController = PageController(
      initialPage: targetPage,
      viewportFraction: newActive.length == 1 ? 0.85 : 0.85,
    );
    _currentPage = targetPage;
  }

  bool _listEquals(List<DoseTime> a, List<DoseTime> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  void _updateClock() {
    final now = DateTime.now();
    setState(() {
      _time = DateFormat('HH:mm').format(now);
      _date = DateFormat('M월 d일 EEEE', 'ko_KR').format(now);
    });
  }

  @override
  void dispose() {
    _clockTimer.cancel();
    _pageController?.dispose();
    super.dispose();
  }

  Future<void> _navigateToSettings(BuildContext context) async {
    // 설정 진입 전 현재 보고 있던 페이지 저장
    final savedPage = _currentPage;
    final savedDoseTimes = List<DoseTime>.from(_activeDoseTimes);

    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const MedicationSettings()),
    );

    // 설정에서 돌아올 때: doseTimes 변경 감지하여 필요 시만 재생성
    if (mounted) {
      final provider = context.read<MedicationProvider>();
      final newActive = provider.activeDoseTimes;

      if (!_listEquals(newActive, savedDoseTimes)) {
        // 약 설정이 바뀐 경우 → 컨트롤러 재생성 (이전 위치 복원 시도는 _syncPageController에서)
        _activeDoseTimes = [];
        _pageController?.dispose();
        _pageController = null;
      } else {
        // 변경 없음 → 이전 페이지 위치 유지
        _currentPage = savedPage;
      }
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1A),
      body: SafeArea(
        child: Consumer<MedicationProvider>(
          builder: (context, provider, _) {
            final active = provider.activeDoseTimes;
            _syncPageController(active);

            return Column(
              children: [
                _buildTopBar(),
                const SizedBox(height: 8),
                _buildClock(),
                const SizedBox(height: 20),
                Expanded(
                  child: active.isNotEmpty
                      ? _buildMedicationView(provider)
                      : _buildEmptyState(context),
                ),
                // 하단 약 관리 버튼 (등록된 약이 있을 때만)
                if (active.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                    child: SizedBox(
                      width: double.infinity,
                      height: 64,
                      child: ElevatedButton.icon(
                        key: const Key('settings_button'),
                        onPressed: () => _navigateToSettings(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF7C83FD),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                          elevation: 0,
                        ),
                        icon: const Icon(Icons.settings_rounded, size: 24),
                        label: const Text(
                          '약 관리',
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          const Text(
            '오늘 약 드셨나요?',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 24,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClock() {
    return Column(
      children: [
        Text(
          _time,
          style: const TextStyle(
            fontSize: 72,
            fontWeight: FontWeight.w200,
            color: Colors.white,
            letterSpacing: 4,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          _date,
          style: TextStyle(
            fontSize: 20,
            color: Colors.white.withValues(alpha: 0.5),
            letterSpacing: 1,
          ),
        ),
      ],
    );
  }

  Widget _buildMedicationView(MedicationProvider provider) {
    return Column(
      children: [
        _buildDoseTimeIndicator(),
        const SizedBox(height: 12),
        Expanded(child: _buildCapsulePageView(provider)),
      ],
    );
  }

  Widget _buildDoseTimeIndicator() {
    if (_activeDoseTimes.length <= 1) return const SizedBox.shrink();
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(_activeDoseTimes.length, (index) {
        final isActive = index == _currentPage;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: isActive ? 24 : 8,
          height: 8,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            color: isActive
                ? const Color(0xFF4ECDC4)
                : Colors.white.withValues(alpha: 0.2),
          ),
        );
      }),
    );
  }

  Widget _buildCapsulePageView(MedicationProvider provider) {
    if (_pageController == null) return const SizedBox.shrink();
    return Stack(
      children: [
        PageView.builder(
          controller: _pageController,
          physics: const BouncingScrollPhysics(),
          onPageChanged: (page) => setState(() => _currentPage = page),
          itemCount: _activeDoseTimes.length,
          itemBuilder: (context, index) {
            final doseTime = _activeDoseTimes[index];
            final meds = provider.getMedsForDoseTime(doseTime);
            final allTaken = provider.isAllTaken(doseTime);

            return AnimatedBuilder(
              animation: _pageController!,
              builder: (context, child) {
                double scale = 0.7;
                double opacity = 0.5;

                if (_pageController!.position.haveDimensions) {
                  final page =
                      _pageController!.page ?? _currentPage.toDouble();
                  final diff = (page - index).abs();
                  scale = (1 - diff * 0.3).clamp(0.7, 1.0);
                  opacity = (1 - diff * 0.5).clamp(0.5, 1.0);
                }

                return Transform.scale(
                  scale: scale,
                  child: Opacity(
                    opacity: opacity,
                    child: _buildTimeSlot(
                      provider, doseTime, meds, allTaken,
                      index == _currentPage,
                    ),
                  ),
                );
              },
            );
          },
        ),
        if (_activeDoseTimes.length > 1) ...[
          // 왼쪽 화살표
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            width: 44,
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: () {
                if (_currentPage > 0) {
                  _pageController?.previousPage(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  );
                }
              },
              child: Center(
                child: AnimatedOpacity(
                  opacity: _currentPage > 0 ? 0.5 : 0.0,
                  duration: const Duration(milliseconds: 200),
                  child: const Icon(
                    Icons.chevron_left_rounded,
                    size: 36,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
          // 오른쪽 화살표
          Positioned(
            right: 0,
            top: 0,
            bottom: 0,
            width: 44,
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: () {
                if (_currentPage < _activeDoseTimes.length - 1) {
                  _pageController?.nextPage(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  );
                }
              },
              child: Center(
                child: AnimatedOpacity(
                  opacity: _currentPage < _activeDoseTimes.length - 1 ? 0.5 : 0.0,
                  duration: const Duration(milliseconds: 200),
                  child: const Icon(
                    Icons.chevron_right_rounded,
                    size: 36,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  /// 시간대별 슬롯: 약 갯수만큼 그리드 배치 (max 4, 2×2).
  Widget _buildTimeSlot(
    MedicationProvider provider,
    DoseTime doseTime,
    List<Medication> meds,
    bool allTaken,
    bool isActive,
  ) {
    final displayMeds = meds.take(4).toList();
    final count = displayMeds.length;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // 시간대 라벨 (어르신들에게 정확한 시간 표시는 혼란을 줄 수 있으므로 제거)
        Text(
          doseTime.displayName,
          style: TextStyle(
            fontSize: 34,
            fontWeight: FontWeight.w800,
            color: Colors.white.withValues(alpha: isActive ? 0.9 : 0.4),
            letterSpacing: 2.0,
          ),
        ),
        const SizedBox(height: 10),

        // 캡슐 그리드 영역 — LayoutBuilder로 공간 최대 활용
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final availW = constraints.maxWidth;
              final availH = constraints.maxHeight;

              // 그리드 행/열 계산
              final cols = count == 1 ? 1 : 2;
              final rows = (count / cols).ceil();

              // 캡슐 크기: 사용 가능한 공간을 최대한 활용 (좌우 너비를 기존 대비 85% 정도로 축소)
              final cellW = availW / cols;
              final cellH = availH / rows;
              final capsuleW = (cellW * 0.78).clamp(80.0, 300.0);
              final capsuleH = (cellH * 0.85).clamp(100.0, 280.0);

              // 폰트/아이콘 사이즈를 캡슐 크기에 비례 (가로/세로 중 작은 비율에 맞춤)
              final iconSize = (math.min(capsuleW * 0.38, capsuleH * 0.25)).clamp(28.0, 80.0);
              final nameSize = (math.min(capsuleW * 0.10, capsuleH * 0.08)).clamp(11.0, 18.0);

              return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: _buildGridRows(
                  provider, doseTime, displayMeds, isActive,
                  capsuleW: capsuleW,
                  capsuleH: capsuleH,
                  iconSize: iconSize,
                  nameSize: nameSize,
                ),
              );
            },
          ),
        ),

        // 상태 텍스트
        if (isActive)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: Text(
                allTaken ? '복약 완료 ✓' : '약을 터치해주세요',
                key: ValueKey(allTaken),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: allTaken
                      ? const Color(0xFF4ECDC4)
                      : Colors.white.withValues(alpha: 0.4),
                ),
              ),
            ),
          ),
      ],
    );
  }

  /// 그리드 행 빌드: 2열 기준으로 약을 배치.
  List<Widget> _buildGridRows(
    MedicationProvider provider,
    DoseTime doseTime,
    List<Medication> meds,
    bool isActive, {
    required double capsuleW,
    required double capsuleH,
    required double iconSize,
    required double nameSize,
  }) {
    final rows = <Widget>[];
    for (int i = 0; i < meds.length; i += 2) {
      final rowMeds = meds.skip(i).take(2).toList();
      final children = rowMeds.map((med) {
        final taken = provider.isTaken(med.id, doseTime);
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: _buildSingleCapsule(
              provider, med, doseTime, taken, isActive,
              capsuleW: capsuleW,
              capsuleH: capsuleH,
              iconSize: iconSize,
              nameSize: nameSize,
            ),
          ),
        );
      }).toList();

      // 홀수 행(3개일 때 마지막 1개): 빈 Expanded 추가로 폭 맞춤
      if (rowMeds.length == 1 && meds.length > 1) {
        children.add(const Expanded(child: SizedBox.shrink()));
      }

      rows.add(
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: children,
        ),
      );
      if (i + 2 < meds.length) {
        rows.add(const SizedBox(height: 6));
      }
    }
    return rows;
  }

  /// 개별 약 캡슐 버튼 — 너비는 부모 Expanded가 제어.
  Widget _buildSingleCapsule(
    MedicationProvider provider,
    Medication med,
    DoseTime doseTime,
    bool taken,
    bool isActive, {
    required double capsuleW, // borderRadius 계산용
    required double capsuleH,
    required double iconSize,
    required double nameSize,
  }) {
    return GestureDetector(
      onTap: isActive ? () => provider.toggleFor(med.id, doseTime) : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
        height: isActive ? capsuleH : capsuleH * 0.85,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(40),
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: taken
                ? [
                    const Color(0xFF4ECDC4).withValues(alpha: 0.9),
                    const Color(0xFF44B09E).withValues(alpha: 0.7),
                  ]
                : [
                    const Color(0xFF3A3A5A).withValues(alpha: 0.95),
                    const Color(0xFF2A2A45).withValues(alpha: 0.85),
                  ],
          ),
          boxShadow: taken && isActive
              ? [
                  BoxShadow(
                    color:
                        const Color(0xFF4ECDC4).withValues(alpha: 0.35),
                    blurRadius: 20,
                    spreadRadius: 3,
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
          border: Border.all(
            color: taken
                ? const Color(0xFF4ECDC4).withValues(alpha: 0.5)
                : Colors.white.withValues(alpha: 0.15),
            width: 1.5,
          ),
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 사진/아이콘 — 복용 후에도 사진 유지 (체크 오버레이)
              _buildCapsuleContent(med, iconSize, taken),
              // 약 이름: 사진 여부와 관계없이 활성화 상태일 때 항상 아래에 표시
              if (isActive) ...[
                const SizedBox(height: 6),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: Text(
                    med.name.isNotEmpty ? med.name : '약',
                    style: TextStyle(
                      fontSize: nameSize,
                      color: taken
                          ? Colors.white.withValues(alpha: 0.9)
                          : Colors.white.withValues(alpha: 0.5),
                      fontWeight: FontWeight.w700,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// 캡슐 내부 콘텐츠: 사진 → 큰 썸네일, 텍스트만 → 큰 텍스트.
  Widget _buildCapsuleContent(Medication med, double iconSize, bool taken) {
    final hasImage = med.imagePath != null && med.imagePath!.isNotEmpty;

    if (hasImage) {
      // 2.2 -> 1.9로 줄였으나 너무 작다는 피드백 반영, 중간인 2.05로 재조정
      final imageSize = iconSize * 2.05;
      return Stack(
        alignment: Alignment.center,
        children: [
          Container(
            key: const ValueKey('photo'),
            width: imageSize,
            height: imageSize,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: taken
                    ? Colors.white.withValues(alpha: 0.6)
                    : Colors.white.withValues(alpha: 0.3),
                width: 2,
              ),
            ),
            clipBehavior: Clip.antiAlias,
            child: kIsWeb
                ? Image.network(med.imagePath!,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        _defaultPillIcon(iconSize))
                : Image.file(File(med.imagePath!),
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        _defaultPillIcon(iconSize)),
          ),
          // 복용 완료 시 체크 오버레이
          if (taken)
            Container(
              width: imageSize,
              height: imageSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF4ECDC4).withValues(alpha: 0.5),
              ),
              child: Icon(
                Icons.check_rounded,
                size: iconSize * 0.7,
                color: Colors.white,
              ),
            ),
        ],
      );
    }

    // 사진 없음: 귀여운 알약 아이콘 표시
    final imageSize = iconSize * 2.05;
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          key: const ValueKey('cute_pill'),
          width: imageSize,
          height: imageSize,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: taken
                ? const Color(0xFF4ECDC4).withValues(alpha: 0.2)
                : Colors.white.withValues(alpha: 0.1),
            border: Border.all(
              color: taken
                  ? Colors.white.withValues(alpha: 0.6)
                  : Colors.white.withValues(alpha: 0.3),
              width: 2,
            ),
          ),
          child: Center(
            child: Icon(
              Icons.medication_liquid_rounded, // 귀여운 알약 아이콘
              size: iconSize * 1.2,
              color: taken
                  ? Colors.white.withValues(alpha: 0.9)
                  : Colors.white.withValues(alpha: 0.7),
            ),
          ),
        ),
        // 복용 완료 시 체크 오버레이
        if (taken)
          Container(
            width: imageSize,
            height: imageSize,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF4ECDC4).withValues(alpha: 0.6),
            ),
            child: Icon(
              Icons.check_rounded,
              size: iconSize * 0.7,
              color: Colors.white,
            ),
          ),
      ],
    );
  }

  Widget _defaultPillIcon(double iconSize) {
    return Icon(
      Icons.medication_rounded,
      key: const ValueKey('pill'),
      size: iconSize,
      color: Colors.white.withValues(alpha: 0.35),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.medication_rounded,
            size: 96,
            color: Colors.white.withValues(alpha: 0.15),
          ),
          const SizedBox(height: 28),
          Text(
            '등록된 약이 없어요',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              color: Colors.white.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: 240,
            height: 64,
            child: ElevatedButton.icon(
              onPressed: () => _navigateToSettings(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF7C83FD),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
              icon: const Icon(Icons.add_circle_outline, size: 28),
              label: const Text(
                '약 등록하기',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

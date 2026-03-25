import 'dart:async';
import 'package:flutter/material.dart';
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
    _activeDoseTimes = List.from(newActive);

    final currentDose = DoseTimeExtension.fromCurrentTime();
    final idx = _activeDoseTimes.indexOf(currentDose);
    final targetPage = idx >= 0 ? idx : 0;

    _pageController?.dispose();
    _pageController = PageController(
      initialPage: targetPage,
      viewportFraction: newActive.length == 1 ? 0.7 : 0.45,
    );
    _currentPage = targetPage;
  }

  /// 설정 화면에서 돌아올 때 강제 리셋.
  void _forceResetController() {
    _activeDoseTimes = [];
    _pageController?.dispose();
    _pageController = null;
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
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const MedicationSettings()),
    );
    // 설정에서 돌아올 때 컨트롤러 강제 리셋 → 다음 build에서 재생성
    _forceResetController();
    if (mounted) setState(() {});
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
    return Stack(
      alignment: Alignment.center,
      children: [
        // PageView (좌우 swipe 지원)
        if (_pageController != null)
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

        // 좌우 화살표 (상하로 긴 밝은 버튼)
        if (_activeDoseTimes.length > 1) ...[
          Positioned(
            left: 0,
            top: 40,
            bottom: 40,
            child: _currentPage > 0
                ? GestureDetector(
                    onTap: () {
                      _pageController?.previousPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    },
                    child: Container(
                      width: 56,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.08),
                        borderRadius: const BorderRadius.horizontal(
                          right: Radius.circular(12),
                        ),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.chevron_left_rounded,
                          size: 40,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  )
                : const SizedBox(width: 56),
          ),
          Positioned(
            right: 0,
            top: 40,
            bottom: 40,
            child: _currentPage < _activeDoseTimes.length - 1
                ? GestureDetector(
                    onTap: () {
                      _pageController?.nextPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    },
                    child: Container(
                      width: 56,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.08),
                        borderRadius: const BorderRadius.horizontal(
                          left: Radius.circular(12),
                        ),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.chevron_right_rounded,
                          size: 40,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  )
                : const SizedBox(width: 40),
          ),
        ],
      ],
    );
  }

  /// 시간대별 슬롯: 약 갯수만큼 개별 캡슐 표시 (max 3).
  Widget _buildTimeSlot(
    MedicationProvider provider,
    DoseTime doseTime,
    List<Medication> meds,
    bool allTaken,
    bool isActive,
  ) {
    final displayMeds = meds.take(3).toList();

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // 시간대 라벨
        Text(
          '${doseTime.displayName} (${doseTime.timeLabel})',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.white.withValues(alpha: isActive ? 0.7 : 0.3),
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 14),

        // 약별 개별 캡슐 버튼
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: displayMeds.map((med) {
            final taken = provider.isTaken(med.id, doseTime);
            return _buildSingleCapsule(
              provider, med, doseTime, taken, isActive,
              totalCount: displayMeds.length,
            );
          }).toList(),
        ),

        const SizedBox(height: 16),

        // 상태 텍스트
        if (isActive)
          AnimatedSwitcher(
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
      ],
    );
  }

  /// 개별 약 캡슐 버튼.
  Widget _buildSingleCapsule(
    MedicationProvider provider,
    Medication med,
    DoseTime doseTime,
    bool taken,
    bool isActive, {
    required int totalCount,
  }) {
    final double capsuleW =
        totalCount == 1 ? 120 : (totalCount == 2 ? 90 : 75);
    final double capsuleH =
        totalCount == 1 ? 190 : (totalCount == 2 ? 160 : 140);
    final double iconSize =
        totalCount == 1 ? 48 : (totalCount == 2 ? 38 : 32);
    final double nameSize =
        totalCount == 1 ? 16 : (totalCount == 2 ? 14 : 13);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 5),
      child: GestureDetector(
        onTap: isActive ? () => provider.toggleFor(med.id, doseTime) : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut,
          width: isActive ? capsuleW : capsuleW * 0.75,
          height: isActive ? capsuleH : capsuleH * 0.8,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(capsuleW / 2),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: taken
                  ? [
                      const Color(0xFF4ECDC4).withValues(alpha: 0.9),
                      const Color(0xFF44B09E).withValues(alpha: 0.7),
                    ]
                  : [
                      const Color(0xFF2A2A45).withValues(alpha: 0.9),
                      const Color(0xFF1A1A30).withValues(alpha: 0.7),
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
                  : Colors.white.withValues(alpha: 0.08),
              width: 1.5,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 체크 or 알약 아이콘
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: taken
                    ? Icon(
                        Icons.check_rounded,
                        key: const ValueKey('check'),
                        size: iconSize,
                        color: Colors.white,
                      )
                    : Icon(
                        Icons.medication_rounded,
                        key: const ValueKey('pill'),
                        size: iconSize,
                        color: Colors.white.withValues(alpha: 0.35),
                      ),
              ),
              // 약 이름 (캡슐 아래에 큰 폰트)
              if (isActive) ...[
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: Text(
                    med.name,
                    style: TextStyle(
                      fontSize: nameSize,
                      color: taken
                          ? Colors.white.withValues(alpha: 0.9)
                          : Colors.white.withValues(alpha: 0.5),
                      fontWeight: FontWeight.w700,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
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

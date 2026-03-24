import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:did_you_take_a_pill/providers/medication_provider.dart';
import 'package:did_you_take_a_pill/services/medication_repository.dart';
import 'package:did_you_take_a_pill/services/daily_check_in_service.dart';
import 'package:did_you_take_a_pill/services/inventory_deduction_service.dart';
import 'package:did_you_take_a_pill/screens/main_dashboard.dart';

/// 테스트 헬퍼: Provider가 주입된 앱 위젯.
Widget createTestApp(SharedPreferences prefs) {
  final repository = MedicationRepository(prefs);
  return ChangeNotifierProvider(
    create: (_) => MedicationProvider(
      repository: repository,
      checkInService: DailyCheckInService(prefs),
      inventoryService: InventoryDeductionService(repository),
    ),
    child: const MaterialApp(home: MainDashboard()),
  );
}

void main() {
  setUpAll(() async {
    await initializeDateFormatting('ko_KR', null);
  });

  testWidgets('MainDashboard shows empty state when no medications',
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(createTestApp(prefs));
    await tester.pumpAndSettle();

    // 빈 상태 안내 표시
    expect(find.text('등록된 약이 없어요'), findsOneWidget);
    expect(find.text('약 등록하기'), findsOneWidget);
  });

  testWidgets('MainDashboard shows clock and title',
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(createTestApp(prefs));
    await tester.pumpAndSettle();

    // 제목 표시
    expect(find.text('오늘 약 드셨나요?'), findsOneWidget);
    // 설정 버튼 표시
    expect(find.byKey(const Key('settings_button')), findsOneWidget);
  });
}

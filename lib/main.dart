import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:did_you_take_a_pill/l10n/app_localizations.dart';
import 'package:did_you_take_a_pill/providers/medication_provider.dart';
import 'package:did_you_take_a_pill/services/medication_repository.dart';
import 'package:did_you_take_a_pill/services/daily_check_in_service.dart';
import 'package:did_you_take_a_pill/services/inventory_deduction_service.dart';
import 'package:did_you_take_a_pill/screens/main_dashboard.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (!kIsWeb) {
    await MobileAds.instance.initialize();
  }
  await initializeDateFormatting('ko_KR', null);
  await initializeDateFormatting('en_US', null);
  final prefs = await SharedPreferences.getInstance();
  final repository = MedicationRepository(prefs);

  runApp(
    ChangeNotifierProvider(
      create: (_) => MedicationProvider(
        repository: repository,
        checkInService: DailyCheckInService(prefs),
        inventoryService: InventoryDeductionService(repository),
      ),
      child: const MedicationTrackerApp(),
    ),
  );
}

class MedicationTrackerApp extends StatelessWidget {
  const MedicationTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      onGenerateTitle: (context) => AppLocalizations.of(context)?.appTitle ?? '약 드셨나요?',
      debugShowCheckedModeBanner: false,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('ko'),
        Locale('en'),
      ],
      locale: null, // 기기 설정 따름
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0F0F1A),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF7C83FD),
          secondary: Color(0xFF4ECDC4),
          surface: Color(0xFF1A1A2E),
        ),
        useMaterial3: true,
      ),
      home: const MainDashboard(),
    );
  }
}

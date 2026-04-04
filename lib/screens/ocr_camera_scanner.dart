import 'package:flutter/material.dart';
import 'package:did_you_take_a_pill/l10n/app_localizations.dart';

/// OCR 카메라 스캐너 화면 — 약봉지 촬영 → 텍스트 인식 → 갯수 추출.
/// 현재는 스텁(stub) 구현. 추후 google_mlkit_text_recognition + image_picker 연동 예정.
class OcrCameraScanner extends StatelessWidget {
  const OcrCameraScanner({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1A),
      appBar: AppBar(
        title: Text(
          l10n.ocrScanTitle,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white70),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 카메라 아이콘 placeholder
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF1A1A2E),
                  border: Border.all(
                    color: const Color(0xFF7C83FD).withValues(alpha: 0.3),
                    width: 2,
                  ),
                ),
                child: Icon(
                  Icons.camera_alt_rounded,
                  size: 48,
                  color: Colors.white.withValues(alpha: 0.3),
                ),
              ),
              const SizedBox(height: 32),
              Text(
                l10n.ocrComingSoon,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: Colors.white.withValues(alpha: 0.6),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                l10n.ocrComingSoonDesc,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white.withValues(alpha: 0.3),
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 48),
              OutlinedButton(
                onPressed: () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF7C83FD),
                  side: const BorderSide(
                    color: Color(0xFF7C83FD),
                    width: 1.5,
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Text(
                  l10n.goBack,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

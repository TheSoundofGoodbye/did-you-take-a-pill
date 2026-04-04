import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/material.dart';
import 'package:did_you_take_a_pill/l10n/app_localizations.dart';

/// 약 사진 선택 → 크롭 → 앱 내부 저장을 담당하는 서비스.
/// 의학적 해석 없이 이미지 파일 경로(String)만 반환.
class ImageStorageService {
  final ImagePicker _picker = ImagePicker();

  /// 이미지 소스 선택 (카메라 / 갤러리).
  Future<String?> pickAndCropImage({
    required BuildContext context,
    required ImageSource source,
  }) async {
    final XFile? picked = await _picker.pickImage(
      source: source,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 85,
    );
    if (picked == null) return null;

    // 웹에서는 크롭 생략 → 바로 경로 반환
    if (kIsWeb) return picked.path;

    final l10n = AppLocalizations.of(context)!;

    // 네이티브: 크롭 화면 진입
    final croppedFile = await ImageCropper().cropImage(
      sourcePath: picked.path,
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: l10n.cropTitle,
          toolbarColor: const Color(0xFF1A1A2E),
          toolbarWidgetColor: Colors.white,
          backgroundColor: const Color(0xFF0F0F1A),
          activeControlsWidgetColor: const Color(0xFF4ECDC4),
          initAspectRatio: CropAspectRatioPreset.original,
          lockAspectRatio: false,
          hideBottomControls: false,
        ),
        IOSUiSettings(
          title: l10n.cropTitle,
          doneButtonTitle: l10n.cropDone,
          cancelButtonTitle: l10n.cropCancel,
        ),
      ],
    );
    if (croppedFile == null) return null;

    // 앱 내부 디렉토리에 복사 저장
    return await _saveToAppDirectory(croppedFile.path);
  }

  /// 크롭된 이미지를 앱 내부 documents/med_images/에 저장.
  Future<String> _saveToAppDirectory(String sourcePath) async {
    final appDir = await getApplicationDocumentsDirectory();
    final medImagesDir = Directory('${appDir.path}/med_images');
    if (!await medImagesDir.exists()) {
      await medImagesDir.create(recursive: true);
    }

    final fileName =
        'med_${DateTime.now().millisecondsSinceEpoch}.jpg';
    final destPath = '${medImagesDir.path}/$fileName';

    await File(sourcePath).copy(destPath);

    // 크롭 임시 파일 정리
    try {
      await File(sourcePath).delete();
    } catch (_) {}

    return destPath;
  }

  /// 약 삭제 시 연관 이미지 파일 정리.
  Future<void> deleteImage(String? imagePath) async {
    if (imagePath == null || imagePath.isEmpty) return;
    try {
      final file = File(imagePath);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (_) {}
  }
}

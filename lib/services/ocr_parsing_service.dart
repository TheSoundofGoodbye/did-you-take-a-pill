/// OCR 파싱 서비스 — 약봉지 텍스트에서 약 갯수를 추출.
/// 현재는 스텁(stub) 구현. 추후 google_mlkit_text_recognition 연동 예정.
///
/// 의학적 해석 없이 숫자(int)만 추출하여 반환.
class OcrParsingService {
  /// 이미지 파일에서 약 갯수를 파싱한다.
  /// 현재 스텁: 항상 null을 반환하여 수동 입력으로 안내.
  ///
  /// 추후 구현 시:
  /// - google_mlkit_text_recognition 으로 텍스트 인식
  /// - 정규식으로 "N일분", "N포", "N정" 패턴 매칭
  /// - 숫자만 추출하여 int 반환
  Future<int?> parseFromImagePath(String imagePath) async {
    // TODO: ML Kit 연동 구현
    // final inputImage = InputImage.fromFilePath(imagePath);
    // final recognizer = TextRecognizer();
    // final recognizedText = await recognizer.processImage(inputImage);
    // return _extractCount(recognizedText.text);
    return null;
  }

  /// 텍스트에서 약 갯수 패턴을 추출한다 (내부 유틸).
  /// 공개하여 단위 테스트가 가능하도록 한다.
  int? extractCountFromText(String text) {
    // "7일분", "14일분", "30포", "10정" 등의 패턴 매칭
    final patterns = [
      RegExp(r'(\d+)\s*일\s*분'),
      RegExp(r'(\d+)\s*포'),
      RegExp(r'(\d+)\s*정'),
      RegExp(r'(\d+)\s*캡슐'),
    ];

    for (final pattern in patterns) {
      final match = pattern.firstMatch(text);
      if (match != null) {
        return int.tryParse(match.group(1)!);
      }
    }
    return null;
  }
}

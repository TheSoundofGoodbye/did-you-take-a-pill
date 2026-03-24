# Project: Daily Medication Tracker MVP

## 1. Overview
매일 아침 약을 복용하는 사용자가 '오늘 약을 먹었는지'를 직관적으로 확인하고 기록할 수 있는 Android/iOS 모바일 어플리케이션.

## 2. Core Features (요구사항)
- **Feature A (원버튼 체크)**: 앱 메인 화면에서 원버튼으로 '오늘 복약 완료' 상태를 토글(Toggle)하는 기능.
- **Feature B (처방약 재고 트래킹)**: 며칠 치 처방약을 등록하면, Feature A 작동 시 자동으로 남은 약의 갯수를 1씩 차감하여 직관적으로 복약 여부를 파악하는 기능.
- **Feature C (카메라 OCR 연동)**: 약국 조제 약봉지의 텍스트를 카메라로 촬영하여, '며칠 치' 약인지 자동으로 파싱(Parsing)하고 Feature B에 등록하는 기능.

## 3. Constraints
- `@medical_safety.md` 규칙을 엄격하게 준수할 것.
- 타겟 사용자의 연령대를 고려하여, 복잡한 텍스트보다 시각적 요소(남은 갯수, 완료 아이콘)를 강조할 것.
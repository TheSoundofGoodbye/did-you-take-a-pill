# Dev Environment Setup Progress

**프로젝트**: Daily Medication Tracker MVP (`did-you-take-a-pill`)
**마지막 업데이트**: 2026-03-24

---

## 현재 상태 요약

`flutter doctor` 결과 기준 **이슈 2개 중 1개 미완료**.

| 체크 항목 | 상태 | 비고 |
|---|---|---|
| Flutter SDK | ✅ 완료 | Channel stable, 3.41.5 |
| Windows Version | ✅ 완료 | Win 11 Home 25H2 |
| Android SDK 경로 설정 | ✅ 완료 | `flutter config --android-sdk` 실행 완료 |
| Android Licenses | ❌ **미완료** | 아래 명령어 실행 필요 |
| Visual Studio C++ 컴포넌트 | ❌ **미완료** | CMake 설치 필요 (아래 참고) |
| Chrome / Connected device / Network | ✅ 완료 | 정상 |

---

## 다음에 할 일 (재개 시 순서대로)

### Step 1: Android Licenses 수락
```powershell
flutter doctor --android-licenses
```
> 실행 후 나오는 모든 항목에 `y` 입력

### Step 2: Visual Studio Installer로 CMake 설치
1. 시작 메뉴 → **"Visual Studio Installer"** 실행
2. `Visual Studio Community 2026 Insiders` 옆 **[수정]** 클릭
3. **"Desktop development with C++"** 워크로드 선택
4. 우측 세부 항목에서 아래 확인/체크:
   - `MSVC v143 - VS 2022 C++ x64/x86` (이미 있으면 OK)
   - ✅ **`C++ CMake tools for Windows`** ← 핵심, 추가 설치 필요
   - `Windows 11 SDK` (이미 있으면 OK)
5. **[수정]** 클릭 → 설치 완료 대기

### Step 3: 최종 확인
```powershell
flutter doctor
```
> 모든 항목 `[√]` 확인 후 앱 개발 시작

---

## 환경 정보

| 항목 | 값 |
|---|---|
| Flutter | 3.41.5 (stable) |
| Dart | 3.11.3 |
| Android SDK | `C:\Users\karbe\AppData\Local\Android\Sdk` |
| Android SDK Version | 36.1.0 |
| Visual Studio | Community 2026 Insiders |
| OS | Windows 11 Home 25H2 |

---

## 앱 개발 계획 (환경 세팅 완료 후)

`active_brief.md` 및 `system_map.json` 참고.

- **Feature A**: 원버튼 복약 체크 (Toggle)
- **Feature B**: 처방약 재고 자동 차감
- **Feature C**: 카메라 OCR로 약봉지 파싱 → 재고 등록

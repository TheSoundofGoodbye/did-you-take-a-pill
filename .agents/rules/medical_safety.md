---
trigger: always_on
---

# Rule: Medical Safety and Compliance
- **CRITICAL**: 이 애플리케이션의 유일한 목적은 '사용자의 복약 기록(단순 상태 저장)'과 '남은 약 갯수 트래킹'입니다.
- **PROHIBITED**: AI는 어떠한 경우에도 복약 지도, 증상 진단, 대체 약품 추천, 복용량 조절 등의 의학적 조언(Medical Advice)을 제공해서는 안 됩니다.
- **ENFORCEMENT**: 사용자 건강 데이터에 관여하는 모든 컴포넌트와 프롬프트는 의학적 해석 없이 오직 수치(Number)와 상태(Boolean)만을 반환하고 표시하도록 설계해야 합니다.
# 누적 목표 예측기 (GoalETA)

현재 진행 속도를 기반으로 목표 완료까지의 예상 시간을 계산하고 추적하는 Flutter 앱입니다.

## 📱 주요 기능

### 1. **목표 관리**
- ✅ 목표 생성: 제목, 단위(페이지/분/개/세트), 총량, 시작일 설정
- ✅ 목표 수정 및 삭제
- ✅ 주말 제외 옵션: 평일만 계산하여 더 정확한 ETA 제공

### 2. **일일 기록**
- ✅ 매일 달성량 기록
- ✅ 기록 추가/수정/삭제
- ✅ 메모 추가 가능

### 3. **ETA 계산**
- ✅ **단순 평균 ETA**: 시작일부터 누적된 진행률을 기반으로 계산
- ✅ 예상 완료일 표시
- ✅ 남은 일수 표시
- ✅ 일평균 진행량 표시

### 4. **진행 상황 시각화**
- ✅ 진행률 표시 (%)
- ✅ 최근 14일 막대 그래프
- ✅ 목표 리스트에서 한눈에 ETA 확인

## 🎨 UI/UX 설계 (Material 3)

### 화면 구성

#### **(A) Home Screen - 목표 리스트**
- 모든 목표를 카드 형태로 표시
- 각 카드에는:
  - 제목
  - 진행률 바 및 백분율
  - 남은 양 강조 표시
  - 예상 완료일(ETA) 또는 남은 일수
- FAB로 새 목표 추가
- 빈 상태(Empty state) 안내 메시지

#### **(B) Goal Detail Screen - 상세 정보**
- **상단**: 남은 양 (큰 숫자), ETA 정보
- **중단**: 
  - 진행 상황 (진행률 바, 백분율, 완료량/총량)
  - 일평균 진행량
  - 최근 14일 기록 차트
- **하단**: 
  - 전체 기록 리스트 (날짜, 값, 메모)
  - 기록 추가/수정/삭제

#### **(C) Add/Edit Goal Sheet**
- Bottom Sheet로 간단한 입력 흐름
- 필드:
  - 목표 제목
  - 단위 및 총량 (같은 줄)
  - 시작일 (날짜 선택)
  - 주말 제외 토글

#### **(D) Add Log Sheet**
- 일일 기록 추가/수정
- 필드:
  - 값 입력
  - 날짜 선택
  - 메모 (선택사항)

### Material 3 디자인 시스템

#### **색상 팔레트**
- **Primary Color**: #6200EE (보라색)
- **Dynamic Color**: Android 12+ 이상에서 자동으로 OS 팔레트 반영
- **밝은 모드 / 어두운 모드** 완벽 지원

#### **타이포그래피**
- **제목/ETA**: `headlineSmall`, `titleMedium`, `titleSmall`
- **본문**: `bodyLarge`, `bodyMedium`, `bodySmall`
- **라벨**: `labelSmall`

#### **레이아웃 & 컴포넌트**
- **격자**: 8dp 기반
- **카드**: `shape.medium` (12dp radius)
- **BottomSheet**: 12dp 상단 라운딩
- **Progress**: `LinearProgressIndicator`
- **Interaction**: 
  - 부드러운 전환 애니메이션
  - 플로팅 SnackBar
  - Modal BottomSheet

## 📂 프로젝트 구조

```
lib/
├── main.dart                          # 앱 진입점, Material 3 테마 설정
├── models/
│   └── goal.dart                      # Goal, LogEntry 모델
├── providers/
│   └── goal_provider.dart             # Riverpod 상태 관리
├── screens/
│   ├── home_screen.dart               # 목표 리스트 화면
│   └── goal_detail_screen.dart        # 목표 상세 화면
├── utils/
│   └── eta_calculator.dart            # ETA 계산 로직
└── widgets/
    ├── goal_card.dart                 # 목표 카드 위젯
    ├── add_edit_goal_sheet.dart       # 목표 추가/수정 BottomSheet
    └── add_log_sheet.dart             # 기록 추가/수정 BottomSheet
```

## 🛠 기술 스택

### 프레임워크 & 라이브러리
- **Flutter 3.0+**: 크로스 플랫폼 UI 프레임워크
- **Dart**: 프로그래밍 언어
- **Material 3**: Google의 최신 디자인 시스템

### 상태 관리
- **flutter_riverpod**: 의존성 주입 및 상태 관리
- **StateNotifier**: 상태 변화 처리

### 데이터 & 저장소
- **로컬 저장소**: 메모리 기반 저장소 (프로토타입)
- **Hive** (선택적): 영속성 저장을 위한 로컬 DB
- **UUID**: 고유 ID 생성

### 국제화 & 날짜/시간
- **intl**: 국제화 및 날짜 포매팅 (한국어 지원)

## 🚀 시작하기

### 필수 요구사항
- Flutter 3.0 이상
- Dart 3.0 이상

### 설치 및 실행

```bash
# 의존성 설치
flutter pub get

# 앱 실행
flutter run

# 릴리스 빌드
flutter build apk  # Android
flutter build ios  # iOS
```

## 📊 ETA 계산 로직

### 단순 평균 (Simple Average)

```
일일 평균 = 누적 완료량 / 경과 일수
남은 일수 = (총량 - 누적 완료량) / 일일 평균
예상 완료일 = 오늘 + 남은 일수
```

**예시:**
- 총량: 500 페이지
- 시작일: 2025년 1월 1일
- 오늘: 2025년 1월 15일 (15일 경과)
- 누적 완료: 100 페이지
- 일일 평균: 100 / 15 ≈ 6.7 페이지
- 남은 량: 500 - 100 = 400 페이지
- 남은 일수: 400 / 6.7 ≈ 60일
- 예상 완료일: 2025년 3월 16일

### 가중 평균 (Weighted Average) - 향후 확장

최근 14일 데이터를 기반으로 더 정확한 속도 변화를 반영합니다.

## 🎯 로드맵

### MVP (현재 완료)
- ✅ 목표 CRUD
- ✅ 기록 CRUD
- ✅ 단순 평균 ETA
- ✅ Material 3 UI
- ✅ 최근 14일 차트

### Phase 2 (향후)
- 🔄 가중 평균 ETA 알고리즘
- 🔄 Hive를 통한 영속성 저장소
- 🔄 더 고급스러운 차트 (fl_chart)
- 🔄 위젯 지원
- 🔄 알림 및 푸시 기능

### Phase 3 (장기)
- 🔄 클라우드 동기화
- 🔄 소셜 공유
- 🔄 통계 및 분석 대시보드
- 🔄 다중 기기 동기화

## 🐛 알려진 문제

- 현재 메모리 기반 저장소를 사용하여 앱 재실행 시 데이터 초기화됨
  → Hive 영속성 저장소 구현 예정

## 📝 라이선스

이 프로젝트는 MIT 라이선스 하에 배포됩니다.

## 👤 작성자

**GoalETA 팀**

---

**Made with ❤️ using Flutter & Material 3**

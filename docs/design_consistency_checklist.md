# 디자인 일관성 체크리스트

## 개요
농산물 직거래 플랫폼의 디자인 일관성을 유지하기 위한 체크리스트입니다.

---

## 1. 색상 시스템

### 1.1 DaisyUI 테마 색상
```javascript
{
  "primary": "#16a34a",    // 초록 (농업, 주요 액션)
  "secondary": "#f59e0b",  // 오렌지 (강조, 입금 대기)
  "success": "#10b981",    // 완료, 성공
  "warning": "#f59e0b",    // 경고, 타임아웃 임박
  "error": "#ef4444",      // 오류, 취소, 위험
  "info": "#3b82f6",       // 정보, confirmed 상태
}
```

### 1.2 상태별 배지 색상 일관성
- [x] **pending**: `badge-ghost` (회색)
- [x] **farmer_review**: `badge-warning` (오렌지/노랑)
- [x] **confirmed**: `badge-info` (파랑)
- [x] **payment_pending**: `badge-secondary` (오렌지)
- [x] **completed**: `badge-success` (초록)
- [x] **cancelled**: `badge-error` (빨강)

### 1.3 버튼 색상 일관성
- [x] **주요 액션**: `btn-primary` (초록)
- [x] **보조 액션**: `btn-ghost` (투명 배경)
- [x] **위험 액션**: `btn-error` (빨강)
- [x] **성공 액션**: `btn-success` (초록)

---

## 2. 타이포그래피

### 2.1 폰트 패밀리
- [x] Noto Sans KR (한글)
- [x] system-ui, sans-serif (영문 폴백)

### 2.2 폰트 크기
- [x] **페이지 제목**: `text-3xl font-bold` (30px)
- [x] **카드 제목**: `text-lg font-semibold` (18px)
- [x] **본문**: `text-base` (16px)
- [x] **보조 텍스트**: `text-sm text-base-content/70` (14px)
- [x] **작은 텍스트**: `text-xs` (12px)

### 2.3 폰트 웨이트
- [x] **제목**: `font-bold` (700)
- [x] **부제목**: `font-semibold` (600)
- [x] **강조**: `font-medium` (500)
- [x] **본문**: `font-normal` (400)

---

## 3. 간격 (Spacing)

### 3.1 페이지 레벨
- [x] **컨테이너 패딩**: `py-8` (상하), `px-4` (좌우, 모바일)
- [x] **섹션 간격**: `space-y-6` (24px)

### 3.2 컴포넌트 레벨
- [x] **카드 내부**: `card-body` (기본 패딩)
- [x] **버튼 그룹**: `gap-2` (8px)
- [x] **폼 필드**: `space-y-3` (12px)

### 3.3 인라인 요소
- [x] **아이콘 + 텍스트**: `gap-2` (8px)
- [x] **배지**: `badge-sm` (작은 패딩)

---

## 4. 레이아웃

### 4.1 컨테이너
- [x] 모든 페이지 `page-container` 클래스 사용
- [x] 최대 너비 제한 (max-w-7xl)
- [x] 중앙 정렬 (mx-auto)

### 4.2 그리드
- [x] **대시보드 통계**: `grid-cols-1 md:grid-cols-4`
- [x] **주요 섹션**: `grid-cols-1 lg:grid-cols-2`
- [x] **간격**: `gap-4` 또는 `gap-6`

### 4.3 플렉스
- [x] **헤더**: `flex flex-col md:flex-row justify-between`
- [x] **버튼 그룹**: `flex flex-wrap gap-2`

---

## 5. 컴포넌트

### 5.1 카드
- [x] `card bg-base-100 shadow-lg`
- [x] `card-body` 사용
- [x] 일관된 제목 스타일 (`card-title`)

### 5.2 테이블
- [x] `table` (DaisyUI 기본)
- [x] `table-zebra` (줄무늬)
- [x] `overflow-x-auto` 래퍼
- [x] 카드 안에 배치 (`card-body p-0`)

### 5.3 버튼
- [x] **크기**: `btn-sm` (작은), `btn` (기본)
- [x] **스타일**: `btn-primary`, `btn-ghost`, `btn-error`
- [x] **최소 터치 영역**: 44px

### 5.4 폼
- [x] `input input-bordered`
- [x] `select select-bordered`
- [x] `textarea textarea-bordered`
- [x] 레이블과 필드 연결 (for/id)

### 5.5 배지
- [x] `badge` (기본)
- [x] `badge-sm` (작은 크기)
- [x] 색상 일관성 유지

---

## 6. 반응형 디자인

### 6.1 브레이크포인트
- [x] **모바일**: 기본 (< 768px)
- [x] **태블릿**: `md:` (≥ 768px)
- [x] **데스크톱**: `lg:` (≥ 1024px)

### 6.2 모바일 우선
- [x] 기본 스타일은 모바일
- [x] md: 이상에서 데스크톱 레이아웃
- [x] 모바일에서 버튼/링크 크기 충분

### 6.3 네비게이션
- [x] 모바일: 드롭다운 메뉴
- [x] 데스크톱: 수평 메뉴

---

## 7. 페이지별 일관성

### 7.1 페이지 헤더
모든 페이지가 동일한 구조를 따릅니다:
```erb
<div class="page-container py-8 space-y-6">
  <div class="flex flex-col gap-3 md:flex-row md:items-center md:justify-between">
    <div>
      <h1 class="text-3xl font-bold">페이지 제목</h1>
      <p class="text-sm text-base-content/70">설명</p>
    </div>
    <div class="flex flex-wrap gap-2">
      <!-- 액션 버튼들 -->
    </div>
  </div>

  <!-- 페이지 콘텐츠 -->
</div>
```

### 7.2 빈 상태
- [x] 일관된 메시지 스타일
- [x] `card bg-base-100 shadow-lg`
- [x] `card-body text-sm text-base-content/70`

### 7.3 로딩 상태
- [x] DaisyUI `loading` 클래스 사용
- [x] 버튼: `btn-disabled loading`

### 7.4 에러 상태
- [x] `alert alert-error`
- [x] 명확한 에러 메시지

---

## 8. 인터랙션

### 8.1 호버 효과
- [x] 버튼: `hover:` 상태 자동 적용 (DaisyUI)
- [x] 링크: `link` 클래스 또는 `hover:underline`

### 8.2 포커스
- [x] Tailwind 기본 focus ring
- [x] 명확한 포커스 표시자

### 8.3 트랜지션
- [x] DaisyUI 기본 트랜지션 사용
- [x] 부드러운 색상 변화

---

## 9. 아이콘

### 9.1 아이콘 사용
- [x] 일관된 크기 (16px, 20px, 24px)
- [x] 텍스트와 수직 정렬
- [x] 적절한 간격 (`gap-2`)

### 9.2 아이콘 색상
- [x] 기본: 텍스트 색상 상속
- [x] 강조: primary/secondary 색상

---

## 10. 테스트 체크리스트

### 10.1 시각적 일관성
- [ ] 모든 페이지 헤더가 동일한 구조
- [ ] 버튼 스타일이 일관적
- [ ] 배지 색상이 상태별로 일관적
- [ ] 카드 스타일이 통일됨

### 10.2 반응형 테스트
- [ ] 모바일 (375px, 768px 이하)
- [ ] 태블릿 (768px - 1024px)
- [ ] 데스크톱 (1024px 이상)

### 10.3 브라우저 테스트
- [ ] Chrome
- [ ] Firefox
- [ ] Safari (모바일)
- [ ] Edge

---

## 참고 사항

### DaisyUI 유틸리티 우선 사용
- 가능한 한 DaisyUI 컴포넌트 사용
- 커스텀 CSS 최소화
- Tailwind 유틸리티 클래스 활용

### 네이밍 컨벤션
- `page-container`: 페이지 컨테이너
- `card-title`: 카드 제목
- `badge`: 상태 배지
- `btn-*`: 버튼 스타일

### 일관성 유지 팁
1. 기존 페이지를 참고하여 새 페이지 작성
2. ViewComponent 재사용
3. 정기적으로 이 체크리스트 검토

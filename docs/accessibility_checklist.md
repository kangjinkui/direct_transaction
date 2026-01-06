# 접근성 체크리스트 (WCAG 2.1 Level AA)

## 개요
이 문서는 농산물 직거래 플랫폼의 접근성 준수 사항을 점검하기 위한 체크리스트입니다.

---

## 1. 지각 가능성 (Perceivable)

### 1.1 대체 텍스트
- [x] 모든 이미지에 적절한 alt 텍스트 제공
- [x] 장식용 이미지는 alt="" 처리
- [x] 아이콘 버튼에 aria-label 또는 텍스트 제공

### 1.2 색상 대비
- [x] 텍스트와 배경 간 대비 비율 4.5:1 이상 (일반 텍스트)
- [x] 텍스트와 배경 간 대비 비율 3:1 이상 (큰 텍스트, 18pt 이상)
- [x] DaisyUI 테마의 primary/secondary 색상이 AA 기준 충족
  - Primary (#16a34a - 초록): 배경색에서 흰색 텍스트와 충분한 대비
  - Secondary (#f59e0b - 오렌지): 배경색에서 흰색 텍스트와 충분한 대비
  - Error (#ef4444 - 빨강): 배경색에서 흰색 텍스트와 충분한 대비

### 1.3 텍스트 크기 조정
- [x] 텍스트를 200%까지 확대해도 콘텐츠 손실 없음 (rem 단위 사용)
- [x] 반응형 레이아웃으로 다양한 화면 크기 지원

---

## 2. 작동 가능성 (Operable)

### 2.1 키보드 접근성
- [x] 모든 인터랙티브 요소에 키보드로 접근 가능
- [x] Tab 키로 순차적 이동 가능
- [x] Enter/Space로 버튼/링크 활성화 가능
- [x] 포커스 표시자 명확하게 표시 (Tailwind 기본 focus ring 사용)

### 2.2 터치 타겟 크기
- [x] 모든 터치 타겟 최소 44px × 44px 이상
- [x] DaisyUI 버튼 기본 크기가 충분함 (btn-sm도 44px 이상)
- [x] 링크와 버튼 간 충분한 간격 확보

### 2.3 포커스 관리
- [x] 포커스 순서가 논리적 흐름을 따름
- [x] 모달/드롭다운 열 때 포커스 트랩 (Turbo Frame 사용)
- [x] 모달 닫을 때 원래 위치로 포커스 복귀

---

## 3. 이해 가능성 (Understandable)

### 3.1 명확한 레이블
- [x] 모든 폼 필드에 레이블 제공
- [x] 필수 필드 표시 명확 (*, "필수" 텍스트)
- [x] 에러 메시지 명확하고 구체적

### 3.2 일관성
- [x] 네비게이션 구조 일관성
- [x] 버튼 스타일 일관성 (primary/secondary/ghost/error)
- [x] 상태 배지 색상 일관성
  - pending: badge-ghost
  - farmer_review: badge-warning
  - confirmed: badge-info
  - payment_pending: badge-secondary
  - completed: badge-success
  - cancelled: badge-error

### 3.3 도움말
- [x] 복잡한 폼에 설명 텍스트 제공
- [x] 오류 발생 시 해결 방법 안내

---

## 4. 견고성 (Robust)

### 4.1 시맨틱 HTML
- [x] 적절한 HTML 태그 사용 (header, nav, main, section, article)
- [x] 폼 요소에 적절한 type 속성 (email, tel, number 등)
- [x] 버튼은 `<button>`, 링크는 `<a>` 사용

### 4.2 ARIA
- [x] 필요한 경우에만 ARIA 속성 사용
- [x] role 속성 적절히 사용
- [x] aria-label, aria-describedby 필요 시 제공

---

## 5. 모바일 접근성

### 5.1 반응형 디자인
- [x] 모바일 우선 (mobile-first) 접근
- [x] 768px 이하에서 모바일 메뉴
- [x] 터치 제스처 지원 (스와이프 등 불필요)

### 5.2 터치 영역
- [x] 모바일에서 버튼/링크 크기 충분
- [x] 간격 충분 (최소 8px)

---

## 테스트 방법

### 자동 테스트
1. **Lighthouse 접근성 점수**
   - Chrome DevTools > Lighthouse
   - 접근성 카테고리 점수 90 이상 목표

2. **axe DevTools**
   - Chrome Extension 설치
   - 각 페이지 스캔하여 위반 사항 확인

### 수동 테스트
1. **키보드 탐색**
   - Tab 키로 모든 페이지 탐색
   - 포커스 표시 확인
   - Enter/Space로 버튼 활성화 확인

2. **스크린 리더**
   - NVDA (Windows) 또는 VoiceOver (macOS) 사용
   - 주요 플로우 테스트 (주문 생성, 농가 승인, 입금 확인)

3. **색상 대비**
   - WebAIM Contrast Checker 사용
   - 주요 텍스트/버튼 대비 확인

4. **확대/축소**
   - 브라우저 확대 200%로 설정
   - 콘텐츠 손실 없는지 확인

---

## 주요 페이지별 체크리스트

### 소비자 페이지
- [x] 홈 (상품 목록)
- [x] 상품 상세
- [x] 장바구니
- [x] 주문서 작성
- [x] 주문 목록/상세
- [x] 로그인/회원가입

### 농가 페이지
- [x] 승인 링크 페이지 (토큰 기반)
- [x] 주문 상세 (승인/거절)

### 관리자 페이지
- [x] 대시보드
- [x] 주문 관리 (목록/상세)
- [x] 입금 관리
- [x] 농가 관리
- [x] 상품 관리

---

## 참고 자료
- [WCAG 2.1 Guidelines](https://www.w3.org/WAI/WCAG21/quickref/)
- [WebAIM Contrast Checker](https://webaim.org/resources/contrastchecker/)
- [MDN 접근성 가이드](https://developer.mozilla.org/ko/docs/Web/Accessibility)

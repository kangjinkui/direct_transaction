# 강남구청 농수산물 직거래 사이트 디자인 가이드

## 📋 개요
한국도자기 웹사이트 디자인을 참고하여 깔끔하고 고급스러운 농수산물 직거래 사이트 디자인

---

## 🎨 컬러 팔레트

### Primary Colors
```css
--primary-white: #FFFFFF;
--primary-cream: #F8F7F5;
--primary-mint: #A8D8D8;      /* 청량한 민트 계열 - 신선함 표현 */
--primary-green: #6B8E23;      /* 자연스러운 올리브 그린 - 농산물 */
--primary-gold: #D4AF37;       /* 포인트 골드 - 프리미엄 */
```

### Secondary Colors
```css
--secondary-gray-light: #F5F5F5;
--secondary-gray-medium: #E0E0E0;
--secondary-gray-dark: #757575;
--secondary-text: #333333;
--secondary-text-light: #666666;
```

### Accent Colors
```css
--accent-orange: #FF6B35;      /* CTA 버튼 */
--accent-blue: #4A90E2;        /* 링크 */
--accent-red: #E74C3C;         /* 할인/특가 */
```

---

## 📐 레이아웃 구조

### Grid System
```css
/* 12 Column Grid */
.container {
  max-width: 1200px;
  margin: 0 auto;
  padding: 0 20px;
}

.row {
  display: grid;
  grid-template-columns: repeat(12, 1fr);
  gap: 24px;
}
```

### Spacing System
```css
--spacing-xs: 4px;
--spacing-sm: 8px;
--spacing-md: 16px;
--spacing-lg: 24px;
--spacing-xl: 32px;
--spacing-xxl: 48px;
--spacing-xxxl: 64px;
```

### Breakpoints
```css
--breakpoint-mobile: 320px;
--breakpoint-tablet: 768px;
--breakpoint-desktop: 1024px;
--breakpoint-wide: 1440px;
```

---

## 🔤 타이포그래피

### Font Family
```css
--font-primary: 'Noto Sans KR', -apple-system, BlinkMacSystemFont, sans-serif;
--font-secondary: 'Nanum Myeongjo', serif;  /* 헤드라인용 */
--font-english: 'Montserrat', sans-serif;   /* 영문/숫자용 */
```

### Font Sizes
```css
--font-size-h1: 48px;      /* 메인 타이틀 */
--font-size-h2: 36px;      /* 섹션 타이틀 */
--font-size-h3: 28px;      /* 서브 타이틀 */
--font-size-h4: 24px;      /* 카드 타이틀 */
--font-size-body: 16px;    /* 본문 */
--font-size-small: 14px;   /* 캡션, 라벨 */
--font-size-tiny: 12px;    /* 메타 정보 */
```

### Font Weights
```css
--font-weight-light: 300;
--font-weight-regular: 400;
--font-weight-medium: 500;
--font-weight-bold: 700;
```

### Line Heights
```css
--line-height-tight: 1.2;
--line-height-normal: 1.5;
--line-height-relaxed: 1.8;
```

---

## 🧭 네비게이션

### Header Navigation
```
구조:
┌─────────────────────────────────────────────────┐
│ [로고]          [메뉴]         [검색] [아이콘]    │
└─────────────────────────────────────────────────┘

메뉴 항목:
- 회사소개 (COMPANY)
- 상품안내 (PRODUCT)
- 브랜드 (BRANDS)
- 이벤트 (EVENT)
- 커뮤니티 (COMMUNITY)
- 고객센터 (CUSTOMER)
```

### Navigation Styles
```css
/* Header */
.header {
  background: white;
  border-bottom: 1px solid #E0E0E0;
  height: 80px;
  position: sticky;
  top: 0;
  z-index: 1000;
  box-shadow: 0 2px 4px rgba(0,0,0,0.05);
}

/* Menu Items */
.nav-item {
  font-size: 16px;
  font-weight: 500;
  color: #333;
  padding: 0 24px;
  transition: color 0.3s ease;
}

.nav-item:hover {
  color: #6B8E23;
}
```

---

## 🖼️ Hero Section

### 메인 히어로 디자인
```
레이아웃:
┌──────────────────────────────────────────────┐
│                                               │
│         [대형 제품 이미지 - 슬라이더]           │
│                                               │
│         오늘의 신선한 농산물                    │
│         "자연의 축복"                          │
│                                               │
│         [◀]                            [▶]    │
└──────────────────────────────────────────────┘
```

### Hero Styles
```css
.hero {
  position: relative;
  height: 600px;
  overflow: hidden;
}

.hero-image {
  width: 100%;
  height: 100%;
  object-fit: cover;
  filter: brightness(0.95);
}

.hero-text {
  position: absolute;
  bottom: 80px;
  left: 80px;
  color: var(--primary-mint);
  font-family: var(--font-secondary);
  font-size: 48px;
  font-weight: 300;
  text-shadow: 0 2px 4px rgba(0,0,0,0.1);
}

.hero-navigation {
  position: absolute;
  bottom: 40px;
  left: 50%;
  transform: translateX(-50%);
}
```

---

## 📦 카드 디자인

### Product Card
```
구조:
┌─────────────────┐
│                 │
│   [제품 이미지]   │
│                 │
├─────────────────┤
│  제품명          │
│  가격 정보       │
│  [상세보기]      │
└─────────────────┘
```

### Card Styles
```css
.product-card {
  background: white;
  border-radius: 8px;
  overflow: hidden;
  transition: all 0.3s ease;
  box-shadow: 0 2px 8px rgba(0,0,0,0.08);
}

.product-card:hover {
  transform: translateY(-8px);
  box-shadow: 0 8px 24px rgba(0,0,0,0.12);
}

.product-card-image {
  width: 100%;
  aspect-ratio: 1/1;
  object-fit: cover;
}

.product-card-content {
  padding: 20px;
}

.product-title {
  font-size: 18px;
  font-weight: 500;
  color: #333;
  margin-bottom: 8px;
}

.product-price {
  font-size: 20px;
  font-weight: 700;
  color: #6B8E23;
  font-family: var(--font-english);
}
```

---

## 📸 이미지 갤러리

### Grid Layout
```css
/* 3열 그리드 레이아웃 */
.gallery-grid {
  display: grid;
  grid-template-columns: repeat(3, 1fr);
  gap: 24px;
  padding: 48px 0;
}

@media (max-width: 768px) {
  .gallery-grid {
    grid-template-columns: repeat(2, 1fr);
    gap: 16px;
  }
}

@media (max-width: 480px) {
  .gallery-grid {
    grid-template-columns: 1fr;
  }
}
```

### Image Styles
```css
.gallery-item {
  position: relative;
  overflow: hidden;
  border-radius: 8px;
  aspect-ratio: 1/1;
}

.gallery-image {
  width: 100%;
  height: 100%;
  object-fit: cover;
  transition: transform 0.3s ease;
}

.gallery-item:hover .gallery-image {
  transform: scale(1.05);
}

.gallery-overlay {
  position: absolute;
  bottom: 0;
  left: 0;
  right: 0;
  background: linear-gradient(transparent, rgba(0,0,0,0.6));
  padding: 20px;
  color: white;
  transform: translateY(100%);
  transition: transform 0.3s ease;
}

.gallery-item:hover .gallery-overlay {
  transform: translateY(0);
}
```

---

## 🎯 섹션 레이아웃

### HOT ISSUE Section
```
┌───────────────────────────────────────────┐
│              HOT ISSUE                     │
├───────────────────────────────────────────┤
│  [이미지1]  [이미지2]  [이미지3]           │
│  [이미지4]  [이미지5]  [이미지6]           │
└───────────────────────────────────────────┘
```

### Section Styles
```css
.section {
  padding: 80px 0;
}

.section-title {
  text-align: center;
  font-size: 36px;
  font-weight: 300;
  letter-spacing: 2px;
  margin-bottom: 48px;
  position: relative;
}

.section-title::after {
  content: '';
  position: absolute;
  bottom: -16px;
  left: 50%;
  transform: translateX(-50%);
  width: 60px;
  height: 2px;
  background: var(--primary-green);
}
```

---

## 🔘 버튼 스타일

### Button Variants
```css
/* Primary Button */
.btn-primary {
  background: var(--primary-green);
  color: white;
  padding: 12px 32px;
  border-radius: 4px;
  border: none;
  font-size: 16px;
  font-weight: 500;
  cursor: pointer;
  transition: all 0.3s ease;
}

.btn-primary:hover {
  background: #5a7a1d;
  transform: translateY(-2px);
  box-shadow: 0 4px 12px rgba(107, 142, 35, 0.3);
}

/* Secondary Button */
.btn-secondary {
  background: transparent;
  color: var(--primary-green);
  padding: 12px 32px;
  border-radius: 4px;
  border: 1px solid var(--primary-green);
  font-size: 16px;
  font-weight: 500;
  cursor: pointer;
  transition: all 0.3s ease;
}

.btn-secondary:hover {
  background: var(--primary-green);
  color: white;
}

/* Text Button */
.btn-text {
  background: none;
  border: none;
  color: var(--secondary-text-light);
  font-size: 14px;
  text-decoration: underline;
  cursor: pointer;
  transition: color 0.3s ease;
}

.btn-text:hover {
  color: var(--primary-green);
}
```

---

## 📝 폼 요소

### Input Styles
```css
.form-group {
  margin-bottom: 24px;
}

.form-label {
  display: block;
  font-size: 14px;
  font-weight: 500;
  color: #333;
  margin-bottom: 8px;
}

.form-input {
  width: 100%;
  padding: 12px 16px;
  border: 1px solid #E0E0E0;
  border-radius: 4px;
  font-size: 16px;
  transition: border-color 0.3s ease;
}

.form-input:focus {
  outline: none;
  border-color: var(--primary-green);
  box-shadow: 0 0 0 3px rgba(107, 142, 35, 0.1);
}

.form-input::placeholder {
  color: #999;
}
```

---

## 🎭 시각적 효과

### Shadows
```css
--shadow-sm: 0 1px 3px rgba(0,0,0,0.08);
--shadow-md: 0 2px 8px rgba(0,0,0,0.12);
--shadow-lg: 0 8px 24px rgba(0,0,0,0.15);
--shadow-xl: 0 16px 48px rgba(0,0,0,0.2);
```

### Borders
```css
--border-thin: 1px solid #E0E0E0;
--border-medium: 2px solid #E0E0E0;
--border-accent: 2px solid var(--primary-green);
```

### Border Radius
```css
--radius-sm: 4px;
--radius-md: 8px;
--radius-lg: 12px;
--radius-xl: 16px;
--radius-round: 50%;
```

### Transitions
```css
--transition-fast: 0.15s ease;
--transition-base: 0.3s ease;
--transition-slow: 0.5s ease;
```

---

## 🦶 Footer Design

### Footer Structure
```
┌────────────────────────────────────────────────┐
│  [로고]                                         │
│                                                 │
│  회사정보 | 이용약관 | 개인정보처리방침         │
│                                                 │
│  연락처: 02-xxxx-xxxx                          │
│  주소: 서울시 강남구 ...                        │
│                                                 │
│  © 2024 강남구청 농수산물 직거래               │
└────────────────────────────────────────────────┘
```

### Footer Styles
```css
.footer {
  background: #2C3E50;
  color: white;
  padding: 48px 0 24px;
  margin-top: 80px;
}

.footer-content {
  max-width: 1200px;
  margin: 0 auto;
  padding: 0 20px;
}

.footer-logo {
  font-size: 24px;
  font-weight: 700;
  margin-bottom: 24px;
}

.footer-links {
  display: flex;
  gap: 24px;
  margin-bottom: 24px;
}

.footer-link {
  color: rgba(255,255,255,0.7);
  font-size: 14px;
  transition: color 0.3s ease;
}

.footer-link:hover {
  color: white;
}

.footer-info {
  font-size: 14px;
  color: rgba(255,255,255,0.6);
  line-height: 1.8;
}

.footer-copyright {
  text-align: center;
  padding-top: 24px;
  margin-top: 24px;
  border-top: 1px solid rgba(255,255,255,0.1);
  font-size: 12px;
  color: rgba(255,255,255,0.5);
}
```

---

## 📱 반응형 디자인

### Mobile (320px - 767px)
```css
@media (max-width: 767px) {
  .header {
    height: 60px;
  }
  
  .hero {
    height: 400px;
  }
  
  .hero-text {
    font-size: 32px;
    bottom: 40px;
    left: 20px;
  }
  
  .section {
    padding: 48px 0;
  }
  
  .section-title {
    font-size: 28px;
  }
  
  .gallery-grid {
    grid-template-columns: 1fr;
  }
}
```

### Tablet (768px - 1023px)
```css
@media (min-width: 768px) and (max-width: 1023px) {
  .gallery-grid {
    grid-template-columns: repeat(2, 1fr);
  }
  
  .hero {
    height: 500px;
  }
}
```

---

## 🎨 디자인 원칙

### 1. 깔끔함 (Cleanliness)
- 넉넉한 여백 사용
- 미니멀한 디자인 요소
- 명확한 시각적 계층구조

### 2. 고급스러움 (Premium Feel)
- 절제된 컬러 팔레트
- 고품질 이미지 사용
- 세련된 타이포그래피

### 3. 신선함 (Freshness)
- 민트/그린 계열 컬러로 신선함 표현
- 깨끗한 흰색 배경
- 밝은 이미지 사용

### 4. 사용자 친화성 (User Friendly)
- 명확한 네비게이션
- 직관적인 정보 구조
- 빠른 로딩 속도

---

## 📐 적용할 페이지 구조

### 1. 메인 페이지
- Hero 슬라이더 (신선한 농산물 이미지)
- 추천 상품 섹션 (HOT ISSUE)
- 카테고리별 상품 그리드
- 고객 후기 섹션
- 공지사항/이벤트 섹션

### 2. 상품 리스트 페이지
- 필터/정렬 옵션
- 상품 카드 그리드
- 페이지네이션

### 3. 상품 상세 페이지
- 대형 상품 이미지 갤러리
- 상품 정보 (원산지, 가격, 설명)
- 구매 옵션
- 관련 상품 추천

### 4. 장바구니/주문 페이지
- 주문 상품 리스트
- 배송 정보 입력 폼
- 결제 정보

---

## 🎯 핵심 디자인 요소 요약

1. **컬러**: 화이트 베이스 + 민트/그린 포인트 + 골드 액센트
2. **레이아웃**: 12컬럼 그리드, 넉넉한 여백
3. **타이포그래피**: Noto Sans KR (본문), Nanum Myeongjo (타이틀)
4. **이미지**: 고품질, 1:1 비율, 깔끔한 배경
5. **카드**: 둥근 모서리, 부드러운 그림자, 호버 효과
6. **버튼**: 명확한 CTA, 부드러운 전환 효과
7. **네비게이션**: 스티키 헤더, 심플한 메뉴
8. **반응형**: 모바일 우선, 유연한 그리드

---

## 📚 참고 자료

- 원본 디자인: 한국도자기 웹사이트
- 컬러 팔레트: 자연/농산물 테마에 맞게 조정
- 타이포그래피: 한글 가독성 최적화
- 레이아웃: 전자상거래 베스트 프랙티스 적용

---

## 🔗 기능별 UI 가이드 (plan 연계)

- 상태 배지/타임라인: 주문 상태(pending/farmer_review/confirmed/payment_pending/payment_confirmed/preparing/completed/cancelled/rejected)별 컬러 배지 정의. 예: pending=gray, farmer_review=amber, confirmed=blue, payment_confirmed=green, cancelled/rejected=red. 마이페이지·농가 화면·관리자 대시보드에서 동일 계통 사용.
- 정책 안내 표기: 주문/결제 섹션에 “입금 기한”, “자동 승인/수동 승인” 등 정책 스냅샷을 카드 형태로 노출. 자동취소 시각과 남은 시간 카운트다운 배지 표시.
- 계좌/민감 정보 마스킹: 알림/화면 모두 계좌 뒤 4자리만 노출. 전체 계좌는 인증된 화면에서 “보기” 버튼 + 모달로 노출(모달에 마스킹 해제 토글).
- 농가 A 토큰/핀 흐름: 토큰 만료/재사용/디바이스 불일치 시 전용 가드 페이지(중립색 배경 + 경고 아이콘 + “재발급 요청” 버튼), PIN 입력 모달은 고컨트라스트/숫자패드 레이아웃.
- 농가 B 자동 승인: 주문 카드에 “자동 승인됨” 라벨과 재고/한도 초과 시 경고 배지(amber/red). 요약 SMS 안내를 화면에도 배지로 중복 표기.
- 관리자 대시보드 카드: 미응답/알림 실패/입금 불일치/정책 위반(한도 초과) 등을 숫자 배지+컬러 코드로 표시, 필터 칩과 함께 배치.
- 알림 실패/재발송: “재발송” 버튼은 secondary 스타일 + 진행 스피너, 실패 이유 툴팁 추가.
- 업로드 UI: 입금 증빙/상품 이미지 업로드 영역에 드래그앤드롭 + 파일 제한 안내(확장자/용량), 업로드 후 썸네일/삭제 버튼.
- 접근성/모바일: 모든 버튼/터치 영역 최소 44px, 폰트 대비 WCAG AA, 포커스 링 커스텀, 스티키 헤더는 모바일에서 높이 축소.

---

**작성일**: 2024-01-15  
**버전**: 1.1 (plan 정합성/보안·정책 UI 반영 추가)  
**프로젝트**: 강남구청 농수산물 직거래 사이트

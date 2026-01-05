# Frontend 개발 계획 검토 및 결정사항

**작성일**: 2025-12-18
**목적**: Frontend Phase F1 착수 전 핵심 이슈 검토 및 해결 방안 정리

---

## 📋 Executive Summary

### 주요 결정사항
1. ✅ **주문 구조**: 단일 농가 주문 유지, 여러 주문 생성 가능 (스키마 변경 불필요)
2. ✅ **이메일 로그인**: 이미 활성화됨 (Devise 뷰만 생성하면 완료)
3. ✅ **메시지 발송**: 개발 중에는 목서비스 사용, 런칭 전에만 실연동
4. 🔄 **UI 템플릿**: DaisyUI + Tailwind CSS 추천

### 블로커 상태
- ❌ **개발 블로커 없음** - 즉시 Frontend 작업 시작 가능
- 🟡 **런칭 블로커**: 알리고 계약, 이용약관 작성 (런칭 전 해결 필요)

---

## 1. 주문 구조 분석 및 결정

### 1.1 코덱스가 지적한 문제

**핵심 이슈:**
```
현재 스키마: orders.farmer_id (단일 농가만 가능)
PRD 요구사항: "장바구니 → 주문 생성" (다농가 혼합 가능으로 해석 가능)
```

### 1.2 현재 스키마 구조

```sql
-- db/schema.rb (line 100-126)
create_table "orders" do |t|
  t.integer "user_id", null: false
  t.integer "farmer_id", null: false  -- ⚠️ 한 주문 = 한 농가
  t.integer "total_amount", default: 0
  t.string "status", default: "pending"
  -- ...
end

create_table "order_items" do |t|
  t.integer "order_id", null: false
  t.integer "product_id", null: false
  -- ...
end
```

### 1.3 두 가지 옵션 비교

#### 옵션 A: 단일 농가 주문 (현재 스키마 유지) ⭐ **선택됨**

**동작 방식:**
```
장바구니
├── 김씨 농가 섹션
│   ├── 사과 10kg
│   └── 배 5kg
│   └── [김씨 농가 주문하기] 버튼
│
└── 박씨 농가 섹션
    ├── 고구마 3kg
    └── [박씨 농가 주문하기] 버튼

결과:
→ Order #1234 (김씨 농가)
→ Order #1235 (박씨 농가)
```

**장점:**
- ✅ 스키마 변경 불필요
- ✅ 입금 명확 (농가별 계좌가 다름)
- ✅ 승인 플로우 단순
- ✅ 타임아웃/취소 로직 명확
- ✅ 정산 간단
- ✅ 구현 완료됨

**단점:**
- ❌ 사용자가 농가마다 따로 주문
- ❌ 결제 횟수 증가

**필요 작업:**
- PRD 문서화 (30분)
- UI 변경: 농가별 섹션 표시 (2시간)
- 사용자 안내 문구 작성 (1시간)

**총 소요: 반나절**

#### 옵션 B: 다농가 주문 (스키마 재설계)

**필요한 변경:**
```sql
-- 새 구조
create_table "orders" do |t|
  t.integer "user_id", null: false
  -- farmer_id 삭제
  t.string "order_number"
end

create_table "sub_orders" do |t|
  t.integer "order_id", null: false
  t.integer "farmer_id", null: false
  t.string "status"
  -- 기존 orders의 농가 관련 필드들
end

create_table "order_items" do |t|
  t.integer "sub_order_id", null: false  -- order_id → sub_order_id
  -- ...
end
```

**단점:**
- ❌ 대규모 스키마 재설계 (4-5일)
- ❌ 기존 코드 전부 수정
- ❌ 복잡한 상태 관리 (부분 취소 등)
- ❌ 입금 UI 복잡
- ❌ 테스트 전체 재작성

**총 소요: 2주**

### 1.4 최종 결정

**선택: 옵션 A (단일 농가 주문)**

**근거:**
1. MVP는 빠른 검증이 목표
2. 실제 사용자 경험도 나쁘지 않음 (쿠팡, 네이버 쇼핑도 판매자별 분리)
3. 입금이 훨씬 명확 (농가별 계좌)
4. 향후 확장 가능 (MVP 검증 후 필요시 추가)

---

## 2. 로그인 시스템 검토

### 2.1 현재 상태

```ruby
# app/models/user.rb (line 4-12)
class User < ApplicationRecord
  devise :database_authenticatable,      # ✅ 이메일/비밀번호 로그인
         :registerable,                   # ✅ 회원가입
         :recoverable,                    # ✅ 비밀번호 찾기
         :rememberable,
         :validatable,
         :trackable,
         :timeoutable,
         :omniauthable,                   # ✅ OAuth (카카오/네이버)
         omniauth_providers: %i[kakao naver]
end
```

### 2.2 필요한 작업

**✅ 이미 완료:**
- Devise 설정
- OAuth 연동
- 이메일/비밀번호 인증

**📝 남은 작업:**
```bash
# 1. Devise 뷰 생성 (5분)
rails generate devise:views

# 2. 커스터마이징 필요 (1-2일)
- 회원가입 폼 (이름, 전화번호 필드 추가)
- 이용약관/개인정보처리방침 체크박스
- 비밀번호 찾기 이메일 템플릿
- 이메일 발송 설정 (SMTP or AWS SES)
```

**블로커:**
- 🟡 이용약관/개인정보처리방침 문서 (법무 검토 필요)

---

## 3. 메시지 발송 시스템

### 3.1 코덱스 지적사항

**원래 계획의 문제점:**
- "알리고 1일이면 된다" ← 너무 낙관적
- 실제 일정:
  - 발신번호 등록: 영업일 1-3일
  - 구청 명의 추가 서류: +1-2일
  - 카카오 알림톡 템플릿 심사: 영업일 3-7일
  - 예산 승인 절차
  - 공공기관 벤더 선정 절차

### 3.2 수정된 전략

**핵심 인사이트: 개발과 런칭 분리**

#### Phase 1: 개발 (지금 ~ 2-3주)
```ruby
# app/services/sms_service.rb
class SmsService
  def self.send_sms(phone, message)
    if Rails.env.production? && ENV['ALIGO_API_KEY'].present?
      # 프로덕션: 실제 발송
      send_via_aligo(phone, message)
    else
      # 개발/테스트: 로그만
      Rails.logger.info "📱 SMS to #{phone}: #{message}"
    end
  end
end
```

**이렇게 하면:**
- ✅ 전체 플로우 개발 가능
- ✅ 테스트 가능
- ✅ UI 확인 가능
- ✅ 메시지 발송 계약 없이도 작업 진행

#### Phase 2: 런칭 준비 (프로덕션 배포 전)
```
필요한 것:
1. 알리고 계약 및 발신번호 등록
2. 카카오 알림톡 템플릿 승인
3. 예산 승인
4. 실제 발송 테스트

예상 일정: 1-2주
```

### 3.3 알리고 무료 체험 (선택사항)

**시험용으로 실제 테스트하고 싶다면:**
```
1. 회원가입: https://smartsms.aligo.in
2. 무료 크레딧: 500원 (SMS 약 60건)
3. 발신번호: 본인 휴대폰 즉시 가능
4. 테스트 가능
```

---

## 4. 관리자 OTP 시스템

### 4.1 현재 구현 상태

```ruby
# app/models/user.rb (line 32-34)
def needs_admin_otp?(window: 7.days)
  admin_like? && (last_otp_verified_at.nil? || last_otp_verified_at < window.ago)
end
```

### 4.2 필요한 구현

```ruby
# app/services/admin_otp_service.rb
class AdminOtpService
  def self.generate_and_send(user)
    otp = SecureRandom.random_number(100_000..999_999).to_s
    Redis.current.setex("admin_otp:#{user.id}", 300, otp)

    SmsService.send_sms(
      user.phone,
      "[구청 직거래] 관리자 인증번호: #{otp} (5분간 유효)"
    )
  end

  def self.verify(user, otp)
    stored = Redis.current.get("admin_otp:#{user.id}")
    return false unless stored == otp

    user.update!(last_otp_verified_at: Time.current)
    Redis.current.del("admin_otp:#{user.id}")
    true
  end
end
```

### 4.3 보안 정책 (문서화 필요)

**결정 필요:**
- OTP 실패 제한 (5회? 10회?)
- 계정 잠금 정책
- 잠금 해제 절차
- "주 1회" vs "행사 중 매번" 분기 처리

**예상 소요: 1일**

---

## 5. UI 템플릿 선택

### 5.1 레퍼런스 사이트 분석

#### 농사랑 (nongsarang.co.kr)
- 전통적인 쇼핑몰 레이아웃
- 카테고리 중심 네비게이션
- 지역 농산물 브랜드 강조

#### 마켓수 (marketsoo.kr)
- ⭐ 모바일 우선 반응형
- 미니멀하고 깔끔한 UI
- 버건디 컬러 (#5e0120)
- 하단 네비게이션

#### 못난이마켓 (motnany.com)
- 스토리텔링 중심
- 큰 고품질 이미지
- 농가 프로필 강조

### 5.2 추천 템플릿

#### 옵션 1: DaisyUI + Tailwind CSS ⭐ **강력 추천**

**장점:**
- Rails 7/8과 완벽 호환
- 이미 Tailwind 사용 계획
- ViewComponent와 통합 쉬움
- 농수산물 쇼핑몰에 적합한 컴포넌트
- 무료

**컬러 스킴 제안:**
```javascript
// tailwind.config.js
colors: {
  primary: '#16a34a',    // 자연스러운 초록 (농업)
  secondary: '#f59e0b',  // 따뜻한 오렌지 (친근함)
  success: '#10b981',    // 승인/완료
  warning: '#f59e0b',    // 대기/확인 필요
  danger: '#ef4444',     // 취소/거절
}
```

#### 옵션 2: Flowbite Pro

**장점:**
- 관리자 대시보드 컴포넌트 풍부
- Hotwire/Turbo 호환
- 유료 ($299)

#### 옵션 3: Tailwind UI

**장점:**
- 최고 품질
- 공식 컴포넌트

**단점:**
- 유료 ($299)

### 5.3 권장 UI 구조

```html
<!-- 장바구니 예시 (농가별 섹션) -->
<div class="cart">
  <h2>장바구니</h2>

  <!-- 김씨 농가 섹션 -->
  <div class="farmer-section">
    <h3>🌾 김씨네 농장</h3>
    <ul>
      <li>사과 10kg - 30,000원</li>
      <li>배 5kg - 25,000원</li>
    </ul>
    <div class="total">소계: 55,000원</div>
    <button>김씨네 농장 상품 주문하기</button>
  </div>

  <!-- 박씨 농가 섹션 -->
  <div class="farmer-section">
    <h3>🥔 박씨네 밭</h3>
    <ul>
      <li>고구마 3kg - 15,000원</li>
    </ul>
    <div class="total">소계: 15,000원</div>
    <button>박씨네 밭 상품 주문하기</button>
  </div>

  <p class="notice">
    ℹ️ 농가별로 별도 주문이 생성되며, 각 농가의 계좌로 입금하셔야 합니다.
  </p>
</div>
```

---

## 6. 수정된 개발 로드맵

### 6.1 즉시 시작 가능 (블로커 없음)

| Phase | 작업 | 예상 시간 | 선행 조건 |
|-------|------|----------|-----------|
| **F0** | SMS 목서비스 구현 | 10분 | 없음 |
| **F0** | Devise 뷰 생성 | 5분 | 없음 |
| **F1** | Tailwind + DaisyUI 설치 | 1시간 | 없음 |
| **F1** | 컬러/폰트 토큰 설정 | 2시간 | 없음 |
| **F1** | ViewComponent 기본 컴포넌트 | 1일 | 없음 |
| **F2** | 장바구니 UI (농가별 섹션) | 4시간 | F1 완료 |
| **F2** | 주문 플로우 UI | 1일 | F1 완료 |
| **Admin OTP** | Redis + OTP 로직 | 1일 | 없음 |

### 6.2 런칭 전 필요 (나중에)

| 항목 | 담당 | 소요 | 선행 조건 |
|------|------|------|-----------|
| 알리고 계약 | 구청 | 3-5일 | 예산 승인 |
| 발신번호 등록 | 구청 | 1-3일 | 알리고 계약 |
| 카카오 템플릿 승인 | 구청 | 3-7일 | 알리고 계약 |
| 이용약관 작성 | 법무팀 | 1주? | - |
| 개인정보처리방침 | 법무팀 | 1주? | - |

### 6.3 우선순위

#### Level 1: 즉시 착수 (개발자)
1. ✅ SMS 목서비스 구현
2. ✅ Tailwind + DaisyUI 설치
3. ✅ ViewComponent 기본 컴포넌트
4. ✅ 장바구니 UI
5. ✅ Devise 뷰 커스터마이징

#### Level 2: 병행 가능 (구청 담당자)
1. 🟡 알리고 계약 절차 시작
2. 🟡 이용약관/개인정보처리방침 작성 의뢰

#### Level 3: 런칭 직전
1. 🔵 실제 SMS 연동 테스트
2. 🔵 약관 페이지 통합
3. 🔵 프로덕션 배포

---

## 7. 핵심 인사이트 (코덱스 리뷰 반영)

### 7.1 과도한 낙관주의 경계

**원래 계획의 문제:**
- "PRD 수정만" → 실제로는 이해관계자 합의 + 문서화 + UI 변경
- "알리고 1일" → 실제로는 3-5일 + 행정 절차
- "이메일 로그인 0분 완료" → 실제로는 Devise 뷰 + 약관 + 이메일 설정
- "관리자 OTP 2시간" → 실제로는 1일 + 보안 정책 문서화

### 7.2 개발 vs 런칭 분리

**핵심 전략:**
- ✅ 개발은 목서비스/시뮬레이션으로 진행
- ✅ 기술적 구현 완료
- ✅ 런칭 전에만 실제 연동 (SMS, 약관 등)

### 7.3 정책 vs 기술 분리

**기술적으로 해결 가능:**
- 주문 구조
- 로그인 시스템
- OTP 로직
- UI 구현

**정책적으로 결정 필요:**
- 메시지 발송 벤더 선정
- 예산 승인
- 약관 작성
- 보안 정책

---

## 8. 다음 단계

### 8.1 즉시 시작 가능한 작업

```bash
# 1. SMS 목서비스 구현 (10분)
# app/services/sms_service.rb 생성

# 2. Devise 뷰 생성 (5분)
rails generate devise:views

# 3. Tailwind + DaisyUI 설치 (1시간)
yarn add daisyui
# tailwind.config.js 수정

# 4. ViewComponent 컴포넌트 시작
# app/components/button_component.rb
# app/components/badge_component.rb
# app/components/card_component.rb
```

### 8.2 구청 담당자 확인 사항 (선택)

**런칭 일정을 앞당기려면:**
1. 알리고 계약 절차 시작 가능한지?
2. 이용약관/개인정보처리방침 누가 작성하는지?
3. 예산 승인 절차는?

**하지만 개발에는 영향 없음**

---

## 9. 요약

### ✅ 확정된 사항
1. **주문 구조**: 단일 농가 주문, 스키마 변경 없음
2. **로그인**: Devise 이미 설정됨, 뷰만 생성
3. **메시지 발송**: 개발 중 목서비스, 런칭 전 실연동
4. **UI 템플릿**: DaisyUI + Tailwind CSS

### 🚀 개발 가능 여부
- **블로커: 없음**
- **Frontend Phase F1 즉시 시작 가능**

### 🟡 런칭 블로커 (나중에 해결)
- 알리고 계약 (3-5일)
- 이용약관 작성 (1주)
- 실제 SMS 연동 (1-2일)

### 📊 예상 일정
- Frontend 개발: 2-3주 (목서비스로)
- 런칭 준비: +1-2주 (실연동)
- **총: 4-5주**

---

## 10. 참고 문서

- [MVP PRD](./prd_mvp.md)
- [구현 계획](./plan_mvp.md)
- [스키마](../db/schema.rb)

---

**작성**: Claude Code
**검토**: 코덱스 의견 반영
**상태**: ✅ 개발 착수 가능

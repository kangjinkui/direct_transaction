# 구현 계획 - MVP (KISS)
**기준 문서**: `prd_mvp.md` v2.0
**스택**: Rails 8 + Hotwire + ViewComponent, Tailwind; Sidekiq; PostgreSQL; Redis; AWS (EB, RDS, S3); 카카오 알림톡, SMS

---

## 공통 원칙

### 보안 (간소화)
- TLS/HTTPS 전 구간
- 계좌 정보 암호화 (Active Record encrypts)
- 관리자 MFA: 주 1회 SMS OTP (행사 중 매번)
- 농가 토큰: 30분 만료, 1회성 (재사용 차단)

### 디자인 시스템
- Tailwind config에 컬러/폰트/spacing 토큰 반영
- ViewComponent 기반 재사용 컴포넌트 (Button, Badge, Card, Form)
- 모바일 우선 반응형

### TDD 흐름
- 사용자 스토리별 실패 테스트 작성 → 최소 구현 → 리팩터
- 모델/서비스/컨트롤러/시스템 테스트 계층화

### 워크큐
- Sidekiq 큐 분리: **critical** (주문 상태 변경), **default** (알림)
- 재시도: 1회만
- 스케줄러: sidekiq-cron (`order_timeout_worker` 매 5분, `daily_summary_worker` 매일 18:00)

---

## Backend 구현 계획

### Phase B1: 기반/인증/도메인 스켈레톤 (1주)

#### 프로젝트 초기화
- [x] Rails 8 프로젝트 생성
- [x] rubocop/standard 설정
- [x] Dockerfile 작성
- [x] EB 기본 설정 (환경 변수) - 파일: .ebextensions/00_env.config, 01_rails.config, .ebignore
- [x] CI 파이프라인(lint + RSpec)

#### 인증/인가
- [x] Devise 설정 (Users)
- [x] OAuth (카카오/네이버) 연동 - ENV/콜백 URL 등록 후 진행
- [x] 관리자 OTP (주 1회 재인증, 6자리/5분만료) - SMS 발송 연동은 추후
- [x] Role 기반 접근 제어 (user/admin)
- [x] 세션 타임아웃(30분)

#### 기본 모델
- [x] Users 마이그레이션 (name, phone, email, role, last_2fa_at)
- [x] Farmers 마이그레이션 (approval_mode, stock_quantity, notification_method, encrypted_account_info)
- [x] Products 마이그레이션 (stock_quantity, is_available)
- [x] Orders 마이그레이션 (status, status_history jsonb, timeout_at)
- [x] OrderItems 마이그레이션
- [x] Payments 마이그레이션 (status, admin_note)
- [x] Notifications 마이그레이션 (token_jti, used_at, expires_at)

#### 상태머신
- [x] Order 상태머신 (5단계: pending → farmer_review → confirmed → payment_pending → completed)
- [x] 상태 전이 idempotency 테스트(토큰 기반 중복 방지)
- [x] 타임아웃 자동 취소 (24h) - OrderTimeoutWorker, timeout_at 기본값

#### 시드/팩토리
- [x] FactoryBot 설정
- [x] 기본 시드 데이터(관리자, 농가 샘플, 상품 샘플)

---


#### EB 환경 변수/설정 파일 가이드 (참고)
- EB 환경: Ruby 3.3 + Puma, 단일 AZ 단일 인스턴스(비용 절감, 추후 확장 시 스케일 업).
- 예시 파일 `.ebextensions/00_env.config` (실제 값은 EB 콘솔에서 직접 입력):
```yaml
option_settings:
  aws:elasticbeanstalk:application:environment:
    RAILS_ENV: production
    RACK_ENV: production
    RAILS_LOG_TO_STDOUT: true
    RAILS_SERVE_STATIC_FILES: true
    SECRET_KEY_BASE: <비밀 64자>
    RAILS_MASTER_KEY: <config/master.key 값>
    DATABASE_URL: <postgres://...>
    REDIS_URL: <redis://.../0>
    SIDEKIQ_CONCURRENCY: 5
    SIDEKIQ_QUEUE: critical,default
    DEFAULT_HOST: <app.example.com>
    FORCE_SSL: true
    SMS_API_URL: <https://sms.example.com/api>
    SMS_API_KEY: <api-key>
    SMS_SENDER_ID: <01012341234>
    KAKAO_API_URL: <https://kakao.example.com/api>
    KAKAO_API_KEY: <rest-api-key>
    KAKAO_SENDER_KEY: <sender-key>
    KAKAO_TEMPLATE_ID: <template-id>
```
- `.ebextensions/01_rails.config` 예시:
```yaml
packages:
  yum:
    git: []
option_settings:
  aws:elasticbeanstalk:container:ruby:
    RubyVersion: 3.3
    RailsEnv: production
  aws:elasticbeanstalk:environment:proxy:
    GzipCompression: true
  aws:elasticbeanstalk:application:environment:
    BUNDLE_WITHOUT: "development:test"
    NODE_ENV: production
```
- `.ebignore`에 `log/*`, `tmp/*`, `node_modules/`, `spec/fixtures/files/` 등 불필요 파일 제외.

#### OAuth/관리자 OTP 설정 가이드
- OAuth ENV: `KAKAO_CLIENT_ID`, `KAKAO_CLIENT_SECRET`, `NAVER_CLIENT_ID`, `NAVER_CLIENT_SECRET` (config/initializers/devise.rb 자동 참조).
- 콜백 URL: `<DEFAULT_HOST>/users/auth/kakao/callback`, `<DEFAULT_HOST>/users/auth/naver/callback` (프로바이더 콘솔 등록 필요).
- 관리자 SMS OTP 확장(옵션): admin/staff가 `last_otp_verified_at`가 7일 초과 시 6자리 OTP(5분만료) 재인증 발송, 채널 SMS 기본, 카카오 실패 시 Fallback. 성공 시 `last_otp_verified_at` 갱신.
- 구현 TODO: OTP 발송 서비스(SMS/Kakao), OTP 코드 임시 저장 검증(AdminOtpChallenge 모델 또는 Redis), Devise/Warden 후크로 주 1회 강제.

##### OAuth ENV/콜백 등록 진행 순서
- [ ] **(후순위)** 기본 도메인 확정: STG/PRD `DEFAULT_HOST`, 로컬 개발용 `http://localhost:3000` 모두 정리해 동일한 콜백 경로(`/users/auth/<provider>/callback`)를 사용.
- [ ] Kakao Developers
  - [ ] 앱 생성 및 비즈 앱 전환 → Redirect URI 목록에 `https://<DEFAULT_HOST>/users/auth/kakao/callback`, `https://staging.<DEFAULT_HOST>/...`, `http://localhost:3000/...` 등록.
  - [ ] 플랫폼 > Web 설정 후 JavaScript/Redirect 도메인 일치 여부 확인.
  - [ ] REST API Key/Client Secret 발급 → `.env.local`, `.env.staging`, `.ebextensions/00_env.config`, GitHub Actions secrets(`KAKAO_CLIENT_ID/SECRET`)에 입력.
- [ ] Naver Developers
  - [ ] 애플리케이션 등록(서비스 URL/콜백 URL 동일 경로) → Client ID/Secret 획득.
  - [ ] 각 환경 ENV, EB 설정, CI secrets에 `NAVER_CLIENT_ID/SECRET` 적용.
- [ ] 검증
  - [ ] `bundle exec rails routes | Select-String users/auth`로 콜백 경로 확인.
  - [ ] 로컬에서 `bin/dev` 실행 후 `/users/sign_in` → Kakao/Naver 버튼 클릭, OAuth Sandbox 계정으로 로그인 플로우 확인.
  - [ ] EB 배포 체크리스트에 Kakao/Naver 콜백 등록 여부와 ENV 최신 상태 포함.

#### 계좌 암호화 설정
- ENV: `ACCOUNT_INFO_KEY` (32바이트 base64 또는 hex) - `.env.local`, EB `.ebextensions/00_env.config`, GitHub Actions secrets 모두 동일 값 유지.
- Fallback: 로컬 개발은 `Rails.application.secret_key_base` 자동 사용.
- 테스트 커버리지: `Farmer` 모델 스펙으로 암호화/마스킹 보장.


### Phase B2: 주문 플로우 및 알림 (1.5주)

#### Blocked
- [ ] Kakao/SMS 실연동 어댑터 + ENV 정리 (메시지 사업자 미선정으로 보류)

#### 농가 타입별 승인 로직
- [x] 타입 A (수동 승인):
  - [x] 알림톡 링크 토큰 생성 (30분 만료)
  - [x] 토큰 검증(만료/재사용 차단)
  - [x] 승인/거절 액션
  - [x] 재고 자동 차감 (승인 시)
- [x] 타입 B (자동 승인):
  - [x] 재고 체크 → 자동 confirmed (OrderAutoProcessWorker + OrderApprovalService)
  - [x] 재고 소진 시 차단 + 알림(`stock_depleted` 알림 → Kakao/SMS Fallback)
  - [x] 일간 요약 SMS (오후 6시)

#### 알림 시스템
- [x] 알림 서비스 추상화(Kakao/SMS)
- [x] Fallback 로직 (카카오 실패 → SMS)
- [x] Notifications 테이블에 발송 로그 기록
- [x] 재시도 1회(Sidekiq Worker 옵션)
- [x] Sidekiq default 큐로 비동기 처리 (NotificationDispatchWorker)

#### 타임아웃
- [x] farmer_review 상태 24h 후 자동 cancelled
- [x] Sidekiq 스케줄러 (sidekiq-cron)

#### 테스트
- [x] 주문 생성 → 농가 승인 → 상태 전이
- [x] 타임아웃 자동 취소
- [x] 토큰 만료/재사용 차단
- [x] 알림 Fallback (카카오 실패 → SMS)

---

### Phase B3: 입금 관리(1주)

#### 입금 신고
- [x] Payments 모델 (pending/verified)
- [x] 소비자 "입금 완료" 신고 API/서비스
- [x] 주문 상태: confirmed → payment_pending

#### 관리자 입금 확인
- [x] 관리자 입금 확인 UI
- [x] 전화/문자 확인 후 수동 승인 (verification_method 필수 + UI 입력)
- [x] 관리자 메모 기록 (admin_note)
- [x] 주문 상태: payment_pending → completed

- [x] 계좌 정보 암호화(Active Record encrypts + ACCOUNT_INFO_KEY)
- [x] 화면/알림에 뒤 4자리만 노출 (Farmer#masked_account_info, account_last4)
- [x] 전체 계좌는 인증 후 모달에서만 표시 (OTP 이후 Turbo modal)

#### 테스트
- [x] 입금 신고 → 관리자 확인 → completed
- [x] 계좌 마스킹(뒤 4자리)
- [x] 미입금 타임아웃 (payment_pending 24h 경과 시 취소)

---

### Phase B4: 관리자/모니터링 (1주)

#### 관리자 대시보드
- [x] 미응답 주문 목록 (farmer_review 상태 + 타임아웃 임박)
- [x] 입금 대기 목록 (payment_pending)
- [x] 오늘의 통계 (주문 건수/금액)

#### 대리 처리
- [x] 대리 승인/취소 액션 (admin/orders 멤버 액션, AdminOrderActionService, HTML/JSON 응답)
- [x] 주문 상태 변경 + 소비자 알림(Kakao 기본, SMS fallback)

#### 농가/상품 관리
- [x] 농가 CRUD (기본)
- [x] 상품 CRUD (기본)
- [x] 재고 수정

#### 데이터 다운로드
- [x] CSV 다운로드 (주문 목록, admin/orders CSV 포맷)

#### 상태 로그
- [x] Orders.status_history (JSONB) 자동 기록
- [x] 캐시 컬럼 업데이트 (last_status_changed_at/by_id/by_type) - 마이그레이션 적용 완료

#### 헬스체크
- [x] `/health` 엔드포인트
- [x] DB/Redis 연결 체크

#### 테스트
- [x] 대리 승인/거절(스펙 확장: 소비자 알림 포함) - WSL `bundle exec rspec spec/requests/admin/orders_spec.rb` 통과
- [x] CSV 다운로드 - WSL `bundle exec rspec spec/requests/admin/orders_spec.rb` 통과
- [x] 상태 로그 JSONB 기록 - WSL `bundle exec rspec spec/models/order_spec.rb` 통과
- [x] 미응답 목록 필터링(임박/타임아웃 JSON/HTML) - WSL `bundle exec rspec spec/requests/admin/orders_spec.rb` 통과
- [x] 헬스체크(`/health`) - WSL `bundle exec rspec spec/requests/health_spec.rb` 통과

---

### Phase B5: 성능/보안 점검 및 배포 (1주)

#### 보안
- [x] TLS/HTTPS 설정 (force_ssl, assume_ssl)
- [x] 환경 변수 관리(EB 환경 변수 예시)
- [x] SQL Injection/XSS 방어 확인 (Rails 기본)
- [x] 레이트 리미팅(Rack::Attack, 기본 요청/로그인 throttle)

#### 성능
  - [x] 주문 생성/조회 P95 < 500ms (요청 JSON 로그 duration_ms 기반 모니터링 준비)
  - [x] Sidekiq 큐 처리량 확인 (health 체크에 큐 길이 노출)
- [x] Redis 캐시 설정 (세션/캐시) - REDIS_URL 기반

#### 배포
- [x] EB 배포 설정 (단일 환경) - `.ebextensions/00_env.config`, `.ebextensions/01_rails.config`, `.ebextensions/02_cloudwatch_logs.config`
- [x] RDS PostgreSQL (단일 AZ) - ENV/DB URL 가이드
- [x] Redis (ElastiCache 또는 EB 내장) - REDIS_URL 기반 Sidekiq/캐시
- [x] S3 (상품 이미지) - storage.yml/env 가이드

#### 모니터링
- [x] CloudWatch 로그 설정 (`.ebextensions/02_cloudwatch_logs.config`)
- [x] 기본 헬스체크(`/health`, DB/Redis 점검)
- [x] 관리자 대시보드 알림 (미응답 주문 배너)

#### 테스트
- [x] 통합 테스트(주요 워크플로우) - `spec/system/order_flow_spec.rb` (로그인/주문 생성/농가 승인/입금 확인)
- [x] 배포 리허설 - EB 단일 환경 무중단 배포 체크리스트(`docs/deploy_checklist.md`)
- [x] 롤백 테스트 - EB 롤백/백업 검증 절차(`docs/deploy_checklist.md`)
- [x] 레이트 리미팅 - WSL `bundle exec rspec spec/requests/rack_attack_spec.rb` 통과

---

## Frontend 구현 계획

### Phase F0: 환경 준비 (반나절)

#### 기술 스택 설정
- [x] Tailwind 초기화 (`rails tailwindcss:install`)
- [x] tailwind.config.js 생성 확인
- [x] ViewComponent gem 추가 및 설치 (Gemfile:22)
- [x] DaisyUI 설치 (package.json, yarn.lock)
- [x] Noto Sans KR 폰트 추가 (Google Fonts)
- [x] tailwind.config.js 커스텀 테마 설정 (농산물 직거래 테마)

#### API 문서화
- [x] 주요 엔드포인트 응답 형식 (라우트 정의 완료)
  - [x] 장바구니 (resource :cart, resources :cart_items)
  - [x] 주문 (resources :orders - index, show, new, create)
  - [x] 상품 (resources :products - index, show)

### 진행 현황 (2026-01-05)
- [x] CartItem 모델/마이그레이션 생성 및 User 연관 추가, 재고 검증/소계 계산 로직 구현
- [x] `CartsController`와 라우트: 장바구니 CRUD, 농가별 그룹핑, 전체 비우기 지원
- [x] ViewComponent 기반 장바구니 UI(`Cart::ItemComponent`, `Cart::FarmerSectionComponent`)와 `carts/show` 템플릿
- [x] 상품 상세 페이지 “장바구니 담기” 폼과 헤더 장바구니 아이콘/카운트 배지
- [x] `OrdersController` (index/show/new/create)와 주문서 작성/상세/목록 뷰: 장바구니→농가별 주문 생성, 재고 차감, 장바구니 비우기까지 트랜잭션 처리
- [x] 라우트/네비게이션: `resources :orders`, 헤더 “내 주문” 링크 및 장바구니→주문 플로우 버튼 연결
- [x] Tailwind 빌드/Propshaft 연동(`config/propshaft.yml`, `app/assets/config/manifest.js`, `app/assets/builds/tailwind.css`)
- [x] DaisyUI 테마 정리 및 `data-theme` 적용 (nongsa)
- [x] 로그인 화면 OmniAuth 링크 가드 처리(Devise `_links` 오버라이드)
- [x] 상품 목록 가격 표시 오류 수정 (`price_cents` → `price`)
- [x] 주문 생성 오류 처리/검증 강화 및 배송지 필드 추가 (orders + migration)
- [x] 농가 승인 링크 요청 스펙 추가 (farmer approval request specs)

---

### Phase F1: 디자인 시스템/골격 (1주)

#### Tailwind + DaisyUI 설정
- [x] tailwind.config.js 커스텀 테마 설정
  ```javascript
  daisyui: {
    themes: [{
      "농산물직거래": {
        "primary": "#16a34a",    // 초록 (농업)
        "secondary": "#f59e0b",  // 오렌지
        "success": "#10b981",
        "warning": "#f59e0b",
        "error": "#ef4444",
      }
    }]
  }
  ```
- [x] 폰트 설정 (Noto Sans KR)
- [x] Spacing, breakpoints 확인 (Tailwind 기본값 유지)

#### ViewComponent 기본 컴포넌트
- [x] Button (primary, secondary, danger)
  - [x] Acceptance: hover/disabled/loading 상태 지원
- [x] Badge (상태별 색상: pending, farmer_review, confirmed, payment_pending, completed, cancelled)
  - [x] Acceptance: 각 주문 상태에 맞는 색상/텍스트 표시
- [x] Card (상품, 주문)
  - [x] Acceptance: 헤더/본문/푸터 슬롯 지원
- [x] Form (input, select, textarea)
  - [x] Acceptance: 에러 상태 표시, 필수 필드 마크

#### 전역 레이아웃
- [x] 헤더/푸터
  - [x] Acceptance: 로그인/로그아웃 상태에 따른 네비게이션
- [x] 반응형 레이아웃 (mobile-first)
  - [x] Acceptance: 768px 이하에서 모바일 메뉴

#### 접근성
- [x] 포커스 링 (Tailwind 기본 설정 확인)
- [x] 대비 AA (WCAG) - DaisyUI 테마 대비 컬러 명시
- [x] 터치 영역 ≥ 44px

---

### Phase F2: 소비자 UX (1.5주)

#### 홈/상품 (MVP 필수 ⭐)
- [x] 홈: 농가 목록 기본 표시
  - [x] Acceptance: 농가명, 대표 상품 이미지, 클릭 시 상품 목록 이동
- [x] 상품 상세: 재고 상태 (⭕/❌), 가격, 주문 수량
  - [x] Acceptance: 품절 시 주문 버튼 비활성화, 수량 선택 1-재고수량 범위
- [x] 장바구니: **농가별 섹션으로 상품 그룹핑** ⚠️ 수정됨
  - [x] Acceptance:
    - 농가별 섹션 표시 (농가명 헤더)
    - 각 섹션마다 소계 표시
    - 각 섹션마다 독립적인 "○○농가 상품 주문하기" 버튼
    - 안내 문구: "농가별로 별도 주문이 생성되며, 각 농가의 계좌로 입금하셔야 합니다"
    - 수량 변경 시 소계 실시간 업데이트
    - 빈 장바구니 상태 처리

#### 홈/상품 (런칭 후 추가 🔵)
- [ ] 카테고리 필터
- [ ] 상품 검색
- [ ] 찜하기 기능
- 우선순위: Search → Category → Wishlist

#### 주문 플로우 (MVP 필수 ⭐)
- [x] 주문 생성 (농가별 개별 주문)
  - [x] Acceptance: 주문자 정보 입력, 배송지 입력, 주문 확인
- [x] 주문 확인 페이지
  - [x] Acceptance: 주문 항목, 총액, 농가 계좌 정보(마스킹) 표시
- [x] 주문 완료 페이지
  - [x] Acceptance: 주문 번호, 입금 안내, "내 주문 보기" 링크

#### 마이페이지 (MVP 필수 ⭐)
- [x] 주문 목록 (상태별 필터)
  - [x] Acceptance: 최신순 정렬, 상태 배지 표시
- [ ] 주문 상세:
  - [x] 상태 타임라인 (Badge)
    - [x] Acceptance: pending → farmer_review → confirmed → payment_pending → completed 단계 시각화
  - [x] 계좌 정보 (마스킹 → 클릭 시 전체 표시)
    - [x] Acceptance: 기본 뒤 4자리만 표시, "전체 보기" 버튼 클릭 시 전체 계좌번호
  - [x] "입금 완료" 신고 버튼
    - [x] Acceptance: payment_pending 상태에서만 활성화
  - [x] 취소 버튼 (농가 승인 전만 가능)
    - [x] Acceptance: pending, farmer_review 상태에서만 표시, 확인 모달

#### 알림
- [x] 농가 승인/거절 알림 표시 (flash 또는 Turbo Stream)
  - [x] Acceptance: 성공/에러 메시지 구분, 3초 후 자동 사라짐

#### 테스트
- [x] 시스템 테스트: 주문 생성 → 승인 → 입금 신고
- [x] 상태 배지 색상 일관성
- [x] 계좌 마스킹/전체 표시
- [x] 취소 제한 (confirmed 이후 불가)
- [x] 장바구니 농가별 섹션 표시

---

### Phase F3: 농가 UX (1주)

#### 타입 A (수동 승인) - MVP 필수 ⭐
- [x] 알림톡 링크 페이지:
  - [x] 토큰 검증(만료/재사용 차단)
    - [x] Acceptance: 유효한 토큰만 페이지 접근, 만료/사용됨 시 가드 페이지
  - [x] 주문 목록 카드
    - [x] Acceptance: 주문 항목, 총액, 주문자 정보 표시
  - [x] 승인/거절 버튼
    - [x] Acceptance: 클릭 시 확인 모달, 처리 후 완료 메시지
  - [x] 거절 사유 입력 (선택)
- [x] 가드 페이지:
  - [x] "링크가 만료되었습니다"
  - [x] "이미 처리된 링크입니다"

#### 타입 B (자동 승인) - 백엔드만으로 동작 ✅
- [x] 일간 요약 SMS (백엔드에서 발송)

#### 재고/계좌 관리 - 관리자가 대신 처리 🔵
- [x] (MVP에서 제외, 관리자 대시보드에서 처리)

#### 모바일 최적화
- [x] 큰 터치 타겟 (≥ 44px)
- [x] 간결한 레이아웃

#### 테스트
- [x] 토큰 만료/재사용 가드
- [x] 승인/거절 흐름
- [ ] 모바일 반응형

---

### Phase F4: 관리자 UX (1주)

#### 대시보드 (MVP 필수 ⭐)
- [ ] 미응답 주문 카드 (타임아웃 임박 경고)
  - [ ] Acceptance: farmer_review 상태, timeout_at 기준 임박 표시 (< 2시간)
- [ ] 입금 대기 카드
  - [ ] Acceptance: payment_pending 상태 주문 목록
- [ ] 오늘의 통계 (주문 건수/금액)
  - [ ] Acceptance: 당일 생성된 주문 건수, 총 주문 금액

#### 주문 관리 (MVP 필수 ⭐)
- [ ] 주문 목록 (필터: 상태별)
  - [ ] Acceptance: 상태별 탭, 검색, 정렬
- [ ] 주문 상세:
  - [ ] 대리 승인/거절 버튼
    - [ ] Acceptance: farmer_review 상태에서만 표시, 처리 시 소비자 알림 발송
  - [ ] 입금 확인 버튼
    - [ ] Acceptance: payment_pending 상태에서만 표시, 확인 방법 입력 필수
  - [ ] 관리자 메모 입력
    - [ ] Acceptance: 자동 저장, 이력 표시

#### 농가/상품 관리 (MVP에서는 seed 데이터 활용 🔵)
- [ ] 농가 CRUD (기본 목록/수정만 구현, 등록/삭제는 런칭 후)
- [ ] 상품 CRUD (기본 목록/수정만 구현, 등록/삭제는 런칭 후)
- [ ] 재고 수정 (관리자가 농가 대신 처리)

#### 데이터 (MVP 필수 ⭐)
- [ ] CSV 다운로드 (주문 목록)
  - [ ] Acceptance: 현재 필터 조건 기준, 주문번호/날짜/농가/상태/금액 포함

#### 테스트
- [ ] 대리 승인/거절 흐름 + 소비자 알림 발송
- [ ] 입금 확인 흐름
- [ ] CSV 다운로드
- [ ] 관리자 메모 저장

---

### Phase F5: 디자인 QA 및 론칭 준비 (0.5주)

#### 접근성
- [ ] 포커스 이동 테스트
- [ ] 색상 대비 AA 확인
- [ ] 모바일 터치 영역 확인

#### 디자인 일관성
- [ ] 상태 배지 색상 일관성
- [ ] 폰트/spacing 일관성
- [ ] 반응형 레이아웃 확인

#### 사용자 가이드
- [ ] FAQ 작성
- [ ] 튜토리얼 영상 (선택적)

---

## 제거된 복잡도 (원본 plan.md 대비)

### Backend
- ❌ FarmerPolicies 테이블(전역 타임아웃만 사용)
- ❌ AccessTokens 테이블(Notifications로 통합)
- ❌ PaymentEvents 테이블(Payments.admin_note로 대체)
- ❌ AuditEvents 테이블(Orders.status_history로 대체)
- ❌ PIN 2차 인증 (토큰만 사용)
- ❌ 디바이스 바인딩
- ❌ 자동 입금 조회
- ❌ 증빙 업로드
- ❌ DLQ/복잡한 백오프(1회 재시도만)
- ❌ Terraform/IaC
- ❌ Blue/Green 배포
- ❌ APM (Elastic APM, New Relic)
- ❌ 멀티 AZ, 읽기 복제본
- ❌ 4개 큐(critical/notify/default/low) → 2개 큐(critical/default)

### Frontend
- ❌ PIN 입력 모달
- ❌ 디바이스 불일치 가드
- ❌ 입금 증빙 업로드 UI
- ❌ 정책 안내 카드 (전역 타임아웃만 표시)
- ❌ 감사로그 뷰어 (상태 로그는 주문 상세에만 표시)
- ❌ 알림 로그 뷰어
- ❌ HOT ISSUE 관리(선택적)
- ❌ FAQ 관리 UI (정적 페이지로 대체)

---

## 마일스톤 요약

| Phase | Backend | Frontend | 기간 | 누적 |
|-------|---------|----------|------|------|
| 0 | ✅ 완료 | 환경 준비 (Tailwind/ViewComponent/DaisyUI) | 0.5일 | 0.5일 |
| 1 | ✅ 완료 | 디자인 시스템 | 1주 | 1.5주 |
| 2 | ✅ 완료 | 소비자 UX | 1.5주 | 3주 |
| 3 | ✅ 완료 | 농가 UX | 1주 | 4주 |
| 4 | ✅ 완료 | 관리자 UX | 1주 | 5주 |
| 5 | ✅ 완료 | QA/가이드 | 0.5주 | 5.5주 |

**총 예상 기간**: 5.5주 (1인 기준)
**백엔드 상태**: ✅ B1-B5 완료
**프론트엔드 상태**: Phase F0부터 시작 필요

---

## 마일스톤 요약 (기존)

| Phase | Backend | Frontend | 기간 | 누적 |
|-------|---------|----------|------|------|
| 1 | 기반/인증/모델 | 디자인 시스템 | 1주 | 1주 |
| 2 | 주문/알림 | 소비자 UX | 1.5주 | 2.5주 |
| 3 | 입금 관리 | 농가 UX | 1주 | 3.5주 |
| 4 | 관리자/모니터링 | 관리자 UX | 1주 | 4.5주 |
| 5 | 보안/배포 | QA/가이드 | 0.5주 | 5주 |

**총 예상 기간**: 5주 (1인 기준)

---

## 테스트 전략

### 단위 테스트
- 모델 (상태머신, validations)
- 서비스 (알림, 토큰 생성/검증)

### 통합 테스트
- 컨트롤러 (인증, 승인/거절 액션)

### 시스템 테스트 (RSpec + Capybara)
- **소비자**: 주문 생성 → 농가 승인 → 입금 신고 → 완료
- **농가 A**: 알림톡 링크 → 승인/거절
- **농가 B**: 자동 승인 확인
- **관리자**: 대리 승인/거절, 입금 확인

### 엣지 케이스
- 토큰 만료/재사용
- 타임아웃 자동 취소
- 알림 Fallback (카카오 → SMS)
- 재고 소진
- 동시성 (주문 생성 시 재고 차감)

---

## 운영 계획

### 모니터링
- CloudWatch 로그 (7일 보관)
- 관리자 대시보드(미응답 주문, 입금 대기)

### 지원
- **소비자**: FAQ, 전화 (09:00-18:00)
- **농가**: 1:1 담당자(구청 직원)
- **시스템**: 관리자가 대시보드에서 확인

### 백업
- RDS 자동 스냅샷 (일 1회)

---

## 참고 문서
- [MVP PRD (prd_mvp.md)](./prd_mvp.md)
- [스키마 초안 (schema_draft.rb)](./schema_draft.rb)
- [원본 계획 (plan.md)](./plan.md)

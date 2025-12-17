# 구현 계획 (Frontend / Backend)
- 기준 문서: `prd_final.md` v1.2, `design.md` v1.1
- 스택: Rails 8 + Hotwire + ViewComponent, Tailwind; Sidekiq; PostgreSQL; Redis; AWS (EB, RDS, S3, SES); Kakao톡/SMS

## 공통 원칙
- 보안: 전 구간 TLS, 비밀은 SSM/Secrets Manager, RBAC+MFA(관리/구청), 필드 암호화(계좌/PII), 토큰 1회성+단기 만료.
- 디자인 시스템: `design.md` 컬러팔레트/그리드/타이포그래피/컴포넌트 토큰을 Tailwind config(ViewComponent helpers)로 반영, 상태 배지/버튼/폼/배경 등 일관 유지.
- TDD 흐름: 사용자 스토리별 Given/When/Then → 실패 테스트 작성 → 최소 구현 → 리팩터 → 회귀 테스트 묶음 실행. 모델/서비스/컨트롤러/시스템 테스트 계층화.
- 품질: RSpec/Capybara 시스템 테스트, ViewComponent 테스트, 모델/서비스 유닛 테스트, 배포 전 staging E2E 시나리오.
- 워크큐: Sidekiq 큐 분리(critical: 상태전이, notify: 알림, default: 기타, low: 통계), DLQ/재시도.

## Backend 구현 계획 (TDD 적용)
1) 프로젝트/인프라
   - Rails 8 초기화, rubocop/standard 설정, Dockerfile/CI 스크립트, EB 기본 설정, Secrets Manager 연동.
   - Terraform/Terragrunt(IaC)로 EB/RDS/Redis/S3/SSM, CloudWatch 대시보드/알람 템플릿 정의. S3 버전닝/암호화 enforce.
   - CI에서 lint+RSpec 병렬 실행, 테스트 패커(seed 데이터 최소화), Terraform plan 검증.
2) 인증/인가
   - Devise(or Authlogic) + MFA(관리/구청), OAuth(Kakao/네이버) for 소비자, 휴대폰 인증 플로우 rate-limit.
   - Roles: user/admin/staff/viewer. Pundit/Cancan 정책 정의. 세션 타임아웃.
   - 테스트: 세션 타임아웃, MFA 필수 경로, 레이트리밋에서 429 반환.
3) 농가 단기 링크 & PIN
   - AccessTokens 테이블(JWT jti, expires_at, used_at, device_fingerprint). 단기 JWT 발급/검증 훅.
   - PIN 등록/검증 + rate-limit + 잠금. 승인/거절 시 PIN 필수.
   - 테스트: 링크 단일 사용, 만료 토큰 거부, 디바이스 불일치 거부, PIN 잠금.
4) 정책 엔진
   - FarmerPolicies 모델: approval_mode, timeout_minutes, daily_order_limit, product_limit, allow_partial, escalation_target.
   - 정책 스냅샷을 주문에 저장(policy_snapshot_json).
   - 테스트: 정책별 승인/타임아웃/한도 분기.
5) 도메인 모델/상태머신
   - Orders 상태머신 (pending→farmer_review→confirmed→payment_pending→payment_confirmed→preparing→completed; rejected/cancelled).
   - Payments 모델 및 상태 (pending/verified/failed/refunded), PaymentEvents.
   - Idempotency keys로 중복 전이 방지.
   - 테스트: 전이 가드, 중복 호출 idempotency, 취소/거절 레이스 컨디션 방지.
6) 알림/메시징
   - 알림 서비스 추상화(Kakao/SMS), 템플릿/locale 관리. 마스킹된 계좌만 노출.
   - 알림 발송 로그(Notifications), 재시도/DLQ, 실패 대시보드 데이터 제공 API.
   - 테스트: 채널 페일오버, 재시도/backoff, 마스킹 여부.
7) 입금 처리
   - 수기 입금 신고 API(증빙 업로드 옵션), 자동입금조회(배치/웹훅) 훅, PG 연동 확장 포인트만 인터페이스로 분리.
   - 불일치/부분/초과 입금 분기, 기한 초과 자동 취소 잡.
   - 테스트: 입금 불일치/부분/초과 시 상태·알림 분기, 기한 경과 자동 취소.
8) 재고/한도
   - Products 재고, max_per_order, 재고/한도 체크 서비스. 타입 B 자동 승인 로직.
   - 테스트: 재고 부족/한도 초과 차단, 자동 승인/차단 케이스.
9) 관리자/구청 기능
   - 농가/상품 CRUD, 정책 변경, 대리 승인/거절, 계좌 변경(감사로그 필수), 통계 API(집계/카운터 캐시) + 차후 OLAP 확장 포인트.
   - 테스트: RBAC 권한 매트릭스, 감사로그 생성, 계좌 버전 불일치 경고.
10) 관제/로그
   - AuditEvents/ AdminActions 홀딩, 구조화 로그(PII 마스킹), 헬스체크/metrics 엔드포인트, 알림 실패/미응답/입금 불일치 알람 훅, CloudWatch/Elastic APM 지표 연동.
   - 테스트: 헬스/메트릭스 응답, PII 마스킹 확인, 알람 트리거 조건.

11) 운영지원 API
   - FAQ/고객 문의/농가 지원 상태를 관리자 대시보드와 연동하는 경량 API, 운영 체크리스트/리포트 생성 스크립트.
   - 테스트: RBAC 가드, 리포트 스케줄링, 운영 지표 계산 정확도.

## Frontend 구현 계획 (Hotwire + Tailwind, TDD/시스템 테스트)
1) 공통
   - Tailwind 설정: design.md 컬러 변수, 폰트(`Noto Sans KR`, `Nanum Myeongjo`), spacing, breakpoints, 그림자/버튼 토큰을 config에 매핑. ViewComponent 기반 UI 라이브러리(Button, Badge, Card, Form, Hero) 제작.
   - 글로벌 레이아웃: 12-col grid, 스티키 헤더/푸터, hero/section spacing 적용.
   - 테스트: 접근성 핵심 요소(포커스 이동, aria-label), 반응형 레이아웃 스냅샷, 디자인 토큰 스냅샷(Storybook or ViewComponent preview diff).
2) 소비자 흐름
   - 홈/카테고리/상품 상세: Hero 슬라이더, HOT ISSUE/카테고리 그리드, design.md 카드/배지 스타일, 재고 상태 아이콘.
   - 주문 생성 폼: design.md 폼/버튼 가이드 반영, 주소/연락처 확인, 정책별 안내문구(입금 기한 카드, 카운트다운 배지).
   - 마이페이지: 상태 타임라인(컬러 배지), 입금 신고 업로드 UI(드래그앤드롭, 썸네일), 취소 버튼(전이 제약).
   - 테스트: 주요 사용자 시나리오(주문→승인→입금 신고), 취소 가능/불가 분기, 계좌 마스킹, 상태 배지 색상/텍스트 접근성.
3) 농가 타입 A UI
   - 토큰 기반 단일 페이지(모바일 최적화): 주문 리스트 카드, 승인/거절, PIN 입력 다이얼로그(고대비 숫자패드), design.md 상태 배지/경고 색상 적용.
   - 타임아웃/링크 만료/디바이스 불일치 시 가드 페이지(중립 배경 + 재발급 버튼).
   - 테스트: 만료/사용됨 링크 차단, PIN 실패/성공 흐름, 디바이스 불일치 경고, 접근성(큰 터치 타겟).
4) 농가 타입 B UI
   - (선택) 간소 리스트/요약 화면; 기본은 자동 승인, 재고 수정/요약 SMS 안내.
   - 테스트: 자동 승인 표시, 재고 수정 반영.
5) 관리자/구청
   - 대시보드: design.md 카드/타이포/배지 가이드 기반 미응답/알림 실패/입금 불일치/KPI 타일, 필터 칩, 재발송/대리 처리 버튼.
   - 농가/상품/정책 폼, 계좌 관리(마스킹/변경 이력 표시), HOT ISSUE/공지/FAQ 관리 화면.
   - 감사로그/알림 로그/운영 리포트 뷰어(페이징/필터, CSV 다운로드).
   - 테스트: RBAC 뷰 접근 제어, 대리 처리 흐름, 알림 재발송 버튼 동작, KPI 계산 정확, 다크/라이트 대비.
6) 알림/토큰 UX
   - 알림 문구 템플릿 관리, 링크 만료/사용됨/장치 불일치 시 design.md 가이드 페이지, 계좌 모달 마스킹/보기 버튼 UX.
   - 테스트: 가드 페이지 시나리오, 템플릿 렌더링, 모달 포커스 트랩.
7) 파일 업로드
   - ActiveStorage + S3 직업로드, 입금 증빙/상품 이미지. 소비자용 압축/리사이즈 가이드.
   - 테스트: 업로드 제한(확장자/용량), 실패 메시지, 썸네일 표시.

8) 운영/지원 UI
   - 고객 FAQ/문의, 농가 지원 체크리스트, 일일/주간/행사 후 리포트 생성 화면. design.md 카드/리스트/폼 스타일 사용.
   - 테스트: RBAC 가드, 리포트 필터·CSV 내보내기, 체크리스트 저장, 반응형(모바일/태블릿) 레이아웃.

## 테스트/배포
- 테스트: 모델/서비스 단위, 상태머신 idempotency, 정책 엔진, 알림 서비스 mock, 시스템 테스트(주요 플로우 1~2 경로), 토큰 재사용/만료/핀 잠금 케이스. 실패 테스트 선작성(TDD).
- 부하: 알림 발송/주문 생성 시 큐 처리량 체크, 읽기 캐시/리드레플리카 검증, KPI 대시보드 쿼리 부하 측정.
- CI/CD: lint+test → Terraform plan/apply → staging 배포 → E2E → prod Blue/Green. 마이그레이션 롤백/재실행 체크. CloudWatch/Sentry 알람 검증.

## 우선순위/마일스톤 (Phase별 체크리스트)

### Backend Roadmap

#### Phase B1: 기반/인증/도메인 스켈레톤
- [x] Rails 8 프로젝트/환경 설정, CI lint+RSpec 파이프라인
- [x] Devise+OAuth(카카오/네이버) 소비자 로그인, 세션 타임아웃 테스트
- [x] 관리자/구청 RBAC(MFA 포함) + Pundit/Cancan 정책
- [x] 기본 모델/마이그레이션: Users/Farmers/Products/Orders/OrderItems/Payments skeleton
- [x] Orders 상태머신 뼈대 + idempotency key 테스트
- [x] 필수 시드/팩토리 정비(팩토리 기반 TDD)

#### Phase B2: 농가 링크/정책/주문 플로우
- [ ] AccessTokens(JWT jti/만료/1회성/디바이스 바인딩) 발급·검증
- [ ] 농가 PIN 등록/검증, 잠금 및 rate-limit 테스트
- [ ] FarmerPolicies(승인 모드/타임아웃/한도) 적용, 주문 생성 시 정책 스냅샷 저장
- [ ] 타입 A 승인/거절/타임아웃 로직, 타입 B 자동 승인·한도 차단 로직
- [ ] 알림 서비스 추상화(Kakao/SMS) + 알림 로그/재시도
- [ ] 시스템 테스트: 주문 생성→승인→상태 전이, 토큰 만료/재사용 가드

#### Phase B3: 결제/입금 처리 및 타임아웃
- [ ] Payments/PaymentEvents 모델, 상태 전이(pending→verified/failed/refunded)
- [ ] 입금 신고 API(증빙 업로드 옵션) + 자동입금조회 훅 스텁/인터페이스
- [ ] 부분/초과/불일치 케이스 분기, 기한 초과 자동 취소 잡
- [ ] 계좌 정보 버전 관리/마스킹 표시, 알림에는 마스킹만
- [ ] 테스트: 입금 불일치 분기, 자동 취소, 계좌 버전 불일치 경고

#### Phase B4: 관리자/관제/모니터링/운영
- [ ] 관리 대시보드/정책/계좌/통계 API, KPI 계산 로직
- [ ] 감사로그/AuditEvents 뷰어 API, 계좌/정책 변경 로깅
- [ ] 헬스/메트릭스 엔드포인트, CloudWatch/Elastic APM 지표 송출
- [ ] 알림 실패/미응답/입금 불일치 알람 훅
- [ ] FAQ/문의/지원 체크리스트/리포트 API

#### Phase B5: 성능/보안 점검 및 론칭 준비
- [ ] 부하: 알림/주문 생성 시 큐 처리량, 캐시/리드레플리카 검증
- [ ] 보안 점검: TLS/HSTS, 비밀 주입, 필드 암호화 확인, 레이트리밋 캡처
- [ ] 배포: Terraform plan/apply, Blue/Green 시나리오 리허설, 마이그레이션 롤백/재실행 체크
- [ ] 운영 플레이북(타임아웃, 대리 처리, 알림 실패/입금 불일치 대응, KPI 수집) 문서화 및 자동 리포트 스케줄링

### Frontend Roadmap

#### Phase F1: 디자인 시스템/골격
- [ ] Tailwind/ViewComponent 디자인 토큰(`design.md` 컬러/폰트/spacing/버튼/배지) 구성
- [ ] 전역 레이아웃, 스티키 헤더/푸터, Hero/HOT ISSUE 틀, 반응형 grid 세팅
- [ ] 접근성 기본 가이드(포커스 링, 키보드 내비게이션, 콘트라스트 체크) 스캐폴드

#### Phase F2: 소비자 UX
- [ ] 홈/카테고리/상품 상세: Hero 슬라이더, 추천/HOT ISSUE, 상품 카드, 재고 배지, 필터/정렬
- [ ] 주문 플로우/폼: design.md 폼/버튼 스타일, 정책 안내 카드, 상태 타임라인
- [ ] 마이페이지: 주문 리스트/필터, 상태 배지, 입금 신고 업로드 UI, 취소 제한 UX
- [ ] 시스템 테스트: 주문→승인→입금 신고 happy path, 상태/정책 안내 노출, 접근성 검사

#### Phase F3: 농가/입금 UX
- [ ] 농가 타입 A 토큰 페이지: 주문 카드, 승인/거절, PIN 모달, 만료·재사용·디바이스 불일치 가드 화면
- [ ] 농가 타입 B 요약/재고 수정 UI + 자동 승인 라벨
- [ ] 입금 신고 업로드/계좌 모달/정책 안내 UI, 계좌 마스킹 보기 토글
- [ ] 모바일 최적화/큰 터치 타겟 검증, 관련 시스템 테스트

#### Phase F4: 관리자/운영 UX
- [ ] 관리 대시보드: 미응답/알림 실패/입금 불일치 카드, KPI 타일, 필터, 재발송/대리 처리 버튼
- [ ] 농가/상품/정책/계좌 폼, 감사로그/알림 로그 뷰어, HOT ISSUE/FAQ/공지 관리
- [ ] 운영 체크리스트/리포트 UI, CSV/엑셀 내보내기, FAQ/문의 테이블
- [ ] 시스템 테스트: RBAC 가드, KPI/리포트 렌더링, 알림 재발송 UX

#### Phase F5: 디자인 QA 및 론칭 준비
- [ ] 접근성/모바일 UX 폴리시시(핵심 화면) 시스템 테스트
- [ ] 디자인 QA(컬러 대비, 폰트/spacing, 반응형, 상태 배지 일관성)
- [ ] 사용자 교육용 캡처/가이드(소비자/농가/관리자) 생성, FAQ/튜토리얼 연동

# 강남구 설맞이 직거래 장터 온라인 시스템 PRD (개선안)
- 버전: 1.1 (보안/확장성/엣지케이스 보강)
- 작성일: 2025-11
- 기술 스택: Ruby on Rails 8, Hotwire, PostgreSQL, Redis, Sidekiq, AWS (EC2/Beanstalk, RDS, S3), SES
- 대상: 소비자, 농가(타입 A/B), 구청 관리자

## 0. 주요 변경 사항 (v1.1)
- 농가 알림 링크 보안 강화: 단기 JWT + 1회성 + 디바이스 바인딩 + PIN 2차 확인
- RBAC + MFA: 관리자/구청 계정 최소권한, 모든 상태 전이·조회 감사로그 의무화
- 결제/입금 추상화: 현금입금 + 자동입금조회 기반 초기 모델, PG 전환 가능한 결제 상태 확장
- 정책 엔진화: 농가별 정책 프로필(타입 A/B/커스텀)로 승인 방식·타임아웃·한도 설정
- 알림/워크 큐 분리: 알림 전용 큐, 비즈니스 전용 큐, 재시도·DLQ, 모니터링
- PII/계좌 보호: 필드 암호화, 알림 내 계좌 마스킹, 최신 계좌 버전 확인
- 가용성/관제: 멀티AZ RDS, S3 버전닝, 헬스체크 + APM + 알림 실패 관제, 백업·복구 리허설

## 1. 핵심 요구사항
- 소비자: 회원가입/OAuth, 상품 조회·주문, 입금 신고, 주문 취소(농가 확인 전), 알림 수신
- 농가 타입 A: 알림톡/웹 링크로 승인/거절, PIN 2차 확인, 재고/계좌 관리
- 농가 타입 B: 사전 재고 기반 자동 승인, 한도 초과 차단, 일간 요약 알림
- 구청 관리자: 농가/상품 등록, 정책 프로필 설정, 대리 처리(승인/거절), 통계, 감사로그 조회

## 2. 보안/프라이버시 요구사항
- 인증/인가
  - 관리자·구청: 이메일/비밀번호+MFA, RBAC(관리자/스태프/조회 전용), 세션 타임아웃 30분.
  - 농가 링크: 서명된 단기 JWT(만료 30분) + 1회성 토큰 저장, 최초 클릭 후 디바이스 바인딩, 승인/거절 시 6자리 PIN 재확인.
  - 소비자: OAuth(카카오/네이버) 또는 휴대폰 인증, 로그인 시 레이트리밋/캡차.
- 데이터 보호
  - PII/계좌정보 필드 수준 암호화(예: Lockbox/AttrEncrypted) + S3 객체 암호화 + 전송 TLS1.2+.
  - 알림 메시지에는 계좌번호 일부(마지막 4자리)만 노출, 전체 계좌는 인증된 화면에서만.
  - 로그 내 PII 마스킹, 접근 로그 180일 보관.
- 감사/이상 탐지
  - 모든 상태 전이·결제·계좌 조회·정책 변경을 `AdminActions`/`AuditEvents`에 기록(누가/언제/무엇을/이전→이후).
  - 알림 링크 재사용·이상 다중 실패 시 계정 잠금·알림.
- 레이트리밋/봇 방어
  - 로그인/핀 검증/SMS 요청에 IP·계정 단위 rate limit, 임계 초과 시 쿨다운.

## 3. 아키텍처 개요
- Web: Rails + Hotwire, ViewComponent.
- Worker: Sidekiq(큐 분리: critical=상태전이, notify=알림, default=기타, low=통계).
- 데이터: PostgreSQL(RDS 멀티AZ), Redis(세션/캐시/큐), S3(이미지/증빙).
- 관제: 헬스체크, APM(Sentry/NewRelic 등), CloudWatch/Elastic APM 지표·알람, 알림 실패 대시보드.
- 배포: Blue/Green 혹은 Rolling, IaC(Terraform/EB 설정), 비밀은 AWS SSM/Secrets Manager.

## 4. 데이터 모델 (확장)
```text
Users: id, name, phone, address, email, oauth_provider, role(user/admin/staff/viewer), mfa_secret, last_login_at
Farmers: id, business_name, owner_name, phone, account_info_enc, farmer_type(A/B/custom), notification_method(kakao/sms/auto), pin_digest
FarmerPolicies: id, farmer_id, approval_mode(auto/manual/mixed), timeout_minutes, daily_order_limit, product_limit, allow_partial?, escalation_target(admin_id)
Products: id, farmer_id, name, description, price, category, stock_quantity, stock_status, max_per_order
Orders: id, user_id, farmer_id, total_amount, status, order_number, confirmed_at, paid_at, completed_at, cancelled_at, rejection_reason, policy_snapshot_json
OrderItems: id, order_id, product_id, quantity, price
Payments: id, order_id, method(manual_transfer/pg), amount, state(pending/verified/failed/refunded), reference(입금자명/PG txn), verified_at, evidence_url
PaymentEvents: id, payment_id, event_type(webhook/manual_check/user_report), payload_json
Notifications: id, farmer_id, order_id, type(kakao/sms/email), channel_msg_id, sent_at, status(sent/failed/retried), retry_count, token_id
AccessTokens: id, farmer_id, jwt_jti, expires_at, used_at, device_fingerprint, revoked_at
AdminActions/AuditEvents: id, actor_id, action_type, target_type, target_id, before_json, after_json, ip, ua, created_at
```

## 5. 상태 머신
```text
Order:
  pending -> farmer_review (자동 생성 시)
  farmer_review -> confirmed (농가 승인; idempotent key)
  farmer_review -> rejected (농가 거절; 사유 필수)
  pending/farmer_review -> cancelled (고객 취소, 타임아웃)
  confirmed -> payment_pending (입금 대기 상태 명시)
  payment_pending -> payment_confirmed (자동입금조회 or PG webhook or 관리자 확인)
  payment_confirmed -> preparing -> completed

Payment:
  pending -> verified (입금 일치/PG 승인)
  pending -> failed (불일치/기한 초과)
  verified -> refunded (관리자/PG 환불)
```

## 6. 주요 워크플로우 (개선)
- 소비자 주문
  1) 로그인/OAuth → 장바구니→ 주문 생성(pending→farmer_review).  
  2) 농가 승인 시 알림, 계좌 마스킹 노출 + 입금 기한 표시.  
  3) 소비자 “입금 신고” 시 증빙 업로드(선택); 실제 상태 전이는 자동입금조회/관리자 확인 시에만.  
  4) 기한 초과 시 자동 취소(정책별).
- 농가 타입 A
  1) 알림톡 링크: 단기 JWT + 1회성 + 디바이스 바인딩.  
  2) 승인/거절 시 PIN 입력, idempotent 처리.  
  3) 계좌/재고 변경은 별도 인증된 세션에서만 가능.  
  4) 미응답 타임아웃: 12h 재알림 → 24h 구청 알림 → 48h 구청 대리 처리/자동 취소.
- 농가 타입 B
  - 사전 재고/한도 내 자동 승인; 초과 시 차단+구청 알림. 일간 요약 SMS. 정책은 FarmerPolicies로 운영 중 변경 가능.
- 구청/관리자
  - RBAC, MFA 필수.  
  - 대리 승인/거절, 정책 변경, 계좌 변경 시 감사로그.  
  - 알림 실패/미응답/입금 불일치 대시보드 제공.

## 7. 알림/채널 설계
- 채널 우선순위: 카카오(성공) → SMS(실패 시) → 전화 안내(옵션). 채널별 재시도/backoff, DLQ.
- 알림 메시지: 주문번호/상태/마스킹 계좌/기한 포함, 링크는 https + 서명 토큰.
- 알림 실패/지연 이벤트를 모니터링하고 경고 발송.

## 8. 비기능 요구사항
- 보안: OWASP ASVS L2 준수, 전 구간 TLS, 비밀은 SSM/Secrets Manager, 정기 취약점 점검.
- 가용성: 99.5% 목표(행사 기간 99.9%), RDS 멀티AZ, 백업 일 1회+주복구 리허설.
- 성능: P95 페이지 응답 < 500ms(캐시 사용), 대량 알림 발송 시 워커 오토스케일.
- 감사/로그: 알림/주문/결제 이벤트 중심 구조화 로그, PII 마스킹, 180일 보관.

## 9. 리스크 및 대응 (보강)
- 농가 미응답: 다중 채널+타임아웃+구청 대리 처리, 정책 기반 자동 승인(타입 B) 유지.
- 주문 폭주: 알림 큐 분리, 대기열/재고 한도, 오토스케일, 읽기 부하는 캐시/리드레플리카.
- 입금 불일치/지연: 자동입금조회로 1차 검증, 불일치 시 관리자 승인 대기, 부분/초과/불일치 분기 정의.
- 계좌 변경 오입금: 알림에 계좌 버전 포함, 화면 진입 시 최신 버전 확인·불일치 경고.

## 10. 향후 확장 고려
- PG 연동 시 Payment 상태 확장으로 무중단 전환.
- 리뷰/평점, 정산 자동화, 통계 OLAP 분리(리드레플리카/ETL).
- 앱 출시 시 동일 정책/권한/토큰 체계를 재사용.

## 11. 개정 이력
- 1.1 (2025-11): 보안 강화, 정책 엔진, 결제 상태 확장, 알림/관제 보강

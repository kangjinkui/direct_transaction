# 강남구 설맞이 직거래 장터 온라인 시스템 PRD (통합본)
- 버전: 1.2 (1.0 + 1.1 개선 통합)
- 작성일: 2025-11
- 기술 스택: Ruby on Rails 8, Hotwire, PostgreSQL, Redis, Sidekiq, AWS(EC2/EB, RDS, S3, SES), 카카오/네이버 OAuth, Kakao 알림톡/SMS
- 대상: 소비자, 농가(타입 A/B), 구청 관리자

## 1. 프로젝트 개요
- 목표: 전화/수기 주문 비효율 해소, 고령 농가 고려한 하이브리드 주문/승인, 구청의 중개·관제 효율화.
- 핵심 가치: 24시간 온라인 주문, 농가 최소 조작 승인, 구청 대리 처리/정책 기반 운영.

## 2. 사용자 페르소나
- 소비자: 30-60대, 온라인 주문/알림 니즈.
- 농가 타입 A(상위 10개): 50-70대, 낮은 디지털 친숙도, 알림톡 링크+간소 웹 승인 필요.
- 농가 타입 B(70개): 60-80대, 자동 승인/구청 지원, 요약 안내.
- 구청 관리자: 모니터링/대리 처리/데이터 분석, RBAC+MFA 필요.

## 3. 기능 요구사항
### 3.1 소비자
- 가입/로그인: OAuth(카카오/네이버) 또는 휴대폰 인증, 레이트리밋/캡차.
- 상품 조회/주문: 농가/카테고리별 브라우징, 재고 상태(⭕/⚠️/❌/💬) 표시, 장바구니.
- 주문 관리: 상태 필터, 계좌(마스킹) 확인, 입금 신고(증빙 선택), 농가 확인 전 취소 가능.
- 알림: 승인/취소/입금 마감 임박 알림.

### 3.2 농가
- 타입 A: 알림톡 링크(단기 JWT+1회성+디바이스 바인딩), PIN 2차 확인으로 승인/거절, 재고/계좌 관리.
- 타입 B: 사전 재고 기반 자동 승인, 한도 초과 차단, 일간 요약 SMS, 구청 개입 조건.
- 공통: 타임아웃 정책(12h 재알림→24h 구청 알림→48h 대리 처리/자동 취소), 재고 수정, 계좌 관리.

### 3.3 구청 관리자
- 농가/상품/정책 관리(FarmerPolicies): 승인 모드/타임아웃/한도/부분 허용/에스컬레이션 설정.
- 주문 관제: 미응답/알림 실패/입금 불일치 대시보드, 대리 승인/거절, 재발송.
- 데이터/리포트: 판매/주문 통계, 엑셀 다운로드, 감사로그 조회.

## 4. 보안/프라이버시
- 인증/인가: 관리자·구청 MFA+RBAC(user/admin/staff/viewer), 세션 타임아웃 30분. 농가 링크는 단기 JWT(30분)+1회성, 승인/거절 시 6자리 PIN, 디바이스 바인딩. 레이트리밋/캡차 적용.
- 데이터 보호: 계좌/PII 필드 암호화, S3 암호화, 전 구간 TLS. 알림/화면은 계좌 뒤 4자리만 노출; 전체 계좌는 인증 후 모달에서만 표시.
- 감사/이상 탐지: 모든 상태 전이·계좌 조회·정책/계좌 변경을 AuditEvents에 기록(ip/ua/before/after). 토큰 재사용, PIN 실패 다중 시 잠금+알림.

## 5. 시스템 아키텍처
- Web: Rails + Hotwire(ViewComponent).
- Worker: Sidekiq 큐 분리(critical=상태전이, notify=알림, default=기타, low=통계/DLQ).
- 데이터: PostgreSQL(RDS 멀티AZ), Redis(세션/캐시/큐), S3(이미지·증빙, 버전닝).
- 관제: 헬스체크, APM, 구조화 로그(PII 마스킹), 알림 실패/미응답/입금 불일치 알람, CloudWatch/Elastic APM 대시보드.
- 배포/IaC: Terraform/Elastic Beanstalk 설정, Blue/Green 또는 Rolling; 비밀은 SSM/Secrets Manager.

## 6. 데이터 모델 (요약)
Users(id,name,phone,address,email,oauth_provider,role,mfa_secret,last_login_at)  
Farmers(id,business_name,owner_name,phone,account_info_enc,farmer_type,notification_method,pin_digest)  
FarmerPolicies(id,farmer_id,approval_mode,timeout_minutes,daily_order_limit,product_limit,allow_partial,escalation_target)  
Products(id,farmer_id,name,description,price,category,stock_quantity,stock_status,max_per_order)  
Orders(id,user_id,farmer_id,total_amount,status,order_number,confirmed_at,paid_at,completed_at,cancelled_at,rejection_reason,policy_snapshot_json)  
OrderItems(id,order_id,product_id,quantity,price)  
Payments(id,order_id,method,amount,state,reference,verified_at,evidence_url)  
PaymentEvents(id,payment_id,event_type,payload_json)  
Notifications(id,farmer_id,order_id,type,channel_msg_id,sent_at,status,retry_count,token_id)  
AccessTokens(id,farmer_id,jwt_jti,expires_at,used_at,device_fingerprint,revoked_at)  
AdminActions/AuditEvents(id,actor_id,action_type,target_type,target_id,before_json,after_json,ip,ua,created_at)

## 7. 상태 머신
Order: pending → farmer_review → confirmed → payment_pending → payment_confirmed → preparing → completed; rejected/cancelled 분기, 전이 idempotent.  
Payment: pending → verified/failed; verified → refunded.

## 8. 핵심 워크플로우
- 소비자: 주문 생성(pending→farmer_review) → 농가 승인 알림 → 입금 신고(선택) → 자동입금조회/관리자 확인 시 payment_confirmed → 준비/완료. 기한 초과 자동 취소.
- 농가 A: 알림톡 링크 접속(만료/재사용 차단) → PIN 입력 → 승인/거절. 미응답 타임아웃 체계.
- 농가 B: 재고/한도 내 자동 승인, 초과 시 차단+구청 알림, 일간 요약 SMS.
- 구청: 미응답/불일치/알림 실패 관제, 대리 승인/거절, 정책·계좌 변경.

## 9. 알림/채널
- 우선순위: Kakao → SMS → 전화(옵션). 재시도/backoff, DLQ.  
- 알림 내용: 주문번호/상태/마스킹 계좌/기한, 링크는 https+서명 토큰.  
- 재발송/지연/실패 모니터링 및 알람.

## 10. 비기능 요구사항
- 보안: OWASP ASVS L2, TLS/HSTS, 취약점 점검 주기.  
- 가용성: 99.5%(행사 99.9%), 백업/복구 리허설.  
- 성능: P95 < 500ms, 알림 워커 오토스케일, 동시접속/주문 몰림 대비.  
- 접근성: 모바일 우선, 글자 ≥16px, 대비 AA, 터치 영역 ≥44px.  
- 로그: 구조화, PII 마스킹, 180일 보관.

## 11. 리스크 및 대응
- 농가 미응답: 다중 채널+타임아웃+구청 대리 처리, 타입 B 자동 승인 유지.
- 주문 폭주: 큐 분리, 재고/한도/대기열, 오토스케일, 캐시/리드레플리카.
- 입금 불일치/지연: 자동입금조회, 부분/초과/불일치 분기, 기한 초과 자동 취소.
- 계좌 변경 오입금: 알림에 계좌 버전 포함, 화면 진입 시 최신 확인·불일치 경고.

## 12. 로드맵/마일스톤 (요약)
- 기존 MVP/고도화/테스트 일정(Phase 1~3) 기반, plan.md의 Phase 1~5 체크리스트로 진행.                             
- TDD: 각 사용자 스토리 실패 테스트 선작성 → 구현 → 리팩터.
- IaC/관제: Terraform/EB 파이프라인, 알림 실패/미응답/입금 불일치 대시보드 및 알람 구성 포함.

## 13. 운영/지원 계획
- 고객 지원: FAQ, 채팅(09~18시), 전화(긴급), 이메일(비긴급) 채널 운영.
- 농가 지원: 사전 교육/튜토리얼 영상, 1:1 담당자, 주간 모니터링/체크리스트.
- 시스템 모니터링: 일일(미처리 주문/에러 로그/알림 실패)·주간(지표 요약/이슈)·행사 후(데이터 분석/개선안) 리포트 루틴.

## 14. 성공 지표 (KPI)
- 주문 전환율 > 15%, 농가 응답률(24h) > 90%, 주문 완료율 > 85%.
- 시스템 가동률 > 99%(행사 99.5~99.9%), 평균 주문 처리 시간 < 48h.
- 정성/운영: 소비자 만족도 > 4.0/5.0, 농가 > 3.5/5.0, 구청 운영 효율 체감.

## 15. 주요 화면/UX 개요
- 소비자: 메인/카테고리/상품 상세(재고 아이콘 ⭕/⚠️/❌/💬), 장바구니, 주문 흐름, 마이페이지(상태 타임라인·입금 신고·취소 제한).
- 농가 타입 A: 알림톡 링크 → 모바일 주문 리스트, 전체/개별 승인·거절, PIN 입력, 만료/재사용 가드 안내.
- 농가 타입 B: 자동 승인 기반 요약/재고 수정(선택적), 일간 요약 SMS 안내.
- 구청/관리: 대시보드(미응답·알림 실패·입금 불일치), 재발송/대리 처리, 농가/상품/정책 관리, 감사로그/알림 로그 뷰어.

## 16. 개정 이력
- 1.0 (2025-11): 초기 PRD
- 1.1 (2025-11): 보안/확장성/정책/결제 상태 강화
- 1.2 (2025-11): 통합본, plan.md 정합성 반영 (정책 엔진, 토큰/핀, 알림/큐 분리, 비기능/운영/KPI/UX 보강)

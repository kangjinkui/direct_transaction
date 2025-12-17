## EB 단일 환경 무중단 배포 체크리스트 (요약)

- 사전
  - `RAILS_MASTER_KEY`, `DATABASE_URL`, `REDIS_URL`, `SMS/KAKAO` 키 등 ENV 준비
  - `.ebextensions/00_env.config`, `01_rails.config`, `02_cloudwatch_logs.config` 최신화
  - `sidekiq.yml` 스케줄 확인 (`order_timeout_worker`, `daily_summary_worker`, `payment_timeout_worker`)
- 배포 단계
  1) `bundle exec rake assets:precompile` (또는 EB 빌드에서 처리)
  2) EB 환경 업데이트: `eb deploy <env>` (변경분만)
  3) 헬스체크 확인: `/health` (DB/Redis/Sidekiq 큐 길이)
  4) 레이트 리미팅 설정 확인: Rack::Attack 초기화 로그/429 응답
  5) 백그라운드 워커 기동 확인: EB 로그/CloudWatch에서 Sidekiq 부팅 메시지 확인
- 무중단 고려
  - Rolling update 설정 사용, 최소/최대 인스턴스 1→2 임시 확장 후 롤링
  - 마이그레이션 포함 배포 시: `eb deploy --staged` 전에 `db:migrate` 실행(또는 deploy 후 run)
  - 자산/환경 차이 없는지 사전 `bundle exec rspec` 통과 확인
- 모니터링
  - CloudWatch Logs: 7일 보관 설정 확인
  - `/health` 응답 + Sidekiq 큐 길이 확인
  - 응답 로그(`event: "request"`, duration_ms) 수집해 P95 모니터링

## EB 롤백 절차 및 백업 검증

1) 롤백 시나리오
   - `eb deploy` 이전 버전 리비전으로 롤백: `eb deploy --version <previous_version>`
   - 또는 EB 콘솔에서 이전 리비전 선택/배포
2) 데이터 백업/검증
   - RDS 스냅샷: 자동 일일 백업 활성화, 롤백 전 스냅샷 생성
   - 롤백 후 헬스체크 `/health` 확인, 주요 플로우 점검(로그인/주문 조회)
3) 마이그레이션 역방향 고려
   - 스키마 호환성 유지: 롤백 시 호환되지 않는 마이그레이션 여부 확인
   - 필요 시 `rails db:rollback STEP=1` 실행(테이블/컬럼 드롭 주의)
4) 검증
   - CloudWatch 로그 에러 모니터링
   - Admin 대시보드 타임아웃 주문 배너/큐 상태 확인

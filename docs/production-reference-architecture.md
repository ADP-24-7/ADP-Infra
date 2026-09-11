# Production Reference Architecture

## 범위

이 문서는 ADP Gateway를 NCP 또는 On-premise에 도입할 때 필요한 목표 배치를 정의한다. 현재 Terraform이 관리하는 것은
NCP QA VPC, private subnet, empty runtime ACG, private Object Storage bucket 두 개뿐이다. Runtime Server, Cloud DB, NAT/Egress,
Load Balancer, Container Registry, KMS, Monitoring, Backup Restore는 생성하거나 검증하지 않았다.

## 목표 Topology

```text
Private Admin / Workload Network
  -> Central API Gateway / Private Load Balancer
       -> OIDC Admin Session
       -> mTLS Service Identity
  -> ADP Gateway Runtime (2+ instances, private subnet)
       -> HA PostgreSQL (private DB subnet)
       -> Private Object Storage
       -> Egress Proxy / NAT + destination allowlist
            -> NVIDIA / Digital Asset Provider
       -> Private Prometheus / Alertmanager -> Institution SIEM
```

Public ingress가 필요하더라도 Runtime instance와 DB를 public subnet에 직접 두지 않는다. API Gateway/WAF/TLS 계층만 외부
요청을 받고, 관리자 UI와 Runtime API는 별도 route/auth policy를 적용한다. On-premise 배치는 동일 책임을 기관의 ingress,
IdP, DB, HSM/KMS, egress firewall, SIEM으로 매핑한다.

## 현재와 목표 리소스

| 영역 | 현재 QA Foundation | Production Reference |
| --- | --- | --- |
| Network | VPC, private subnet | ingress/DB/management zone 분리, route/ACL 검토 |
| Runtime ACG | 존재, rule 없음 | ingress source와 egress destination 최소 허용 |
| Runtime | 없음 | immutable image digest, 2개 이상 instance, readiness rollout |
| Database | Console bootstrap 경험만 존재 | private HA PostgreSQL, encryption, backup, failover |
| Object Storage | private artifact/state bucket | versioning, retention, scoped runtime identity |
| Secret | 로컬 ignored env | Secret Manager/KMS reference, rotation, audit |
| Egress | 없음 | proxy/NAT/firewall allowlist와 DNS/IP 통제 |
| Monitoring | 없음 | private scrape, Alertmanager, log/SIEM export |
| DR | state recovery runbook | DB/Object restore drill과 RTO/RPO evidence |

## Identity와 Secret

- Admin은 OIDC Authorization Code flow와 IdP MFA/conditional access를 사용한다.
- Runtime workload는 mTLS 또는 short-lived workload identity를 사용하며 장기 API Key를 image에 넣지 않는다.
- Terraform, DB, Object Storage, Provider credential은 각각 별도 identity와 rotation 주기를 갖는다.
- Secret 값은 Terraform variable/state/output, plan artifact, Compose rendering, GitHub log에 기록하지 않는다.
- KMS/HSM이 필요한 transform key와 Digital Asset private key/custody는 Gateway 일반 Secret과 분리한다.

## Network와 Egress

BE의 server-owned destination과 SSRF guard는 애플리케이션 1차 통제다. 최종 통제는 ACG/NACL만으로 넓은 인터넷을 허용하는
방식이 아니라 Egress Proxy 또는 firewall의 `host:443` allowlist다. Provider endpoint 변경은 application profile과 network
policy를 함께 review하며 caller가 destination URL을 전달할 수 없게 유지한다.

Management endpoint와 Prometheus scrape는 별도 management route에서만 허용한다. `/actuator/prometheus`를 public ingress에
노출하지 않고 전용 scraper identity와 Security Group을 사용한다.

## Database와 Migration

- Runtime DML, Flyway DDL, Operations read role을 분리한다.
- Migration은 Runtime rollout 전에 단일 Job으로 실행하고 additive/forward-compatible 변경만 허용한다.
- DB connection pool 총합은 instance 수와 DB connection limit 안에서 계산한다.
- Backup retention, PITR, cross-zone 정책은 기관 SLA에 따라 결정한다.
- Restore drill과 failover 측정 전에는 HA/DR 완료를 주장하지 않는다.

## 배포와 Rollback 순서

1. CI Security Gate와 SBOM을 통과한 image digest를 Registry에 고정한다.
2. QA에서 schema compatibility와 Golden/Failure E2E를 검증한다.
3. Production migration job을 실행하고 Flyway current를 확인한다.
4. 새 Runtime을 소수 instance에 배포해 readiness와 핵심 metric을 확인한다.
5. 점진적으로 traffic을 전환하고 failure/recovery backlog를 관찰한다.
6. 실패 시 이전 image digest로 traffic을 복구한다. 적용된 migration을 임의 down migration하지 않는다.
7. `SENT_UNKNOWN`은 reconciliation을 완료한 뒤 후속 조치한다.

## Backup, Restore, DR

Terraform remote state 복구는 애플리케이션 DB 복구가 아니다. DB backup, Object version, Terraform state를 서로 다른 보존
대상으로 관리한다. Restore drill은 격리 환경에서 backup digest, schema version, row-level invariant, Runtime smoke test를
검증하고 RTO/RPO를 실제 측정한다. 현재는 이 Cloud drill을 수행하지 않았다.

## Optional NCP 재개 Gate

1. Cloud 비용과 QA 환경 유지 기간 승인
2. 현재 Console DB 유지/폐기 결정 및 Terraform import 계획
3. Registry와 immutable Runtime image 준비
4. Secret Manager/KMS 및 workload identity 결정
5. Private ingress/egress/management network 설계 review
6. Runtime, HA DB, Monitoring을 별도 Terraform module로 추가
7. Flyway, Golden/Failure/Recovery E2E와 restore smoke 실행
8. 검증 Evidence가 생긴 항목만 Cloud verified로 변경

현재 사용할 수 있는 표현은 `Local Product E2E`, `Production Reference Architecture`, `NCP QA Foundation`,
`NCP Object Storage Handoff`다. `Production 배포 완료`, `HA 검증`, `DR 검증`, `Cloud Release Candidate`는 사용할 수 없다.

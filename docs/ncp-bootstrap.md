# NCP QA bootstrap adoption

This runbook adopts the resources created in the NCP console on 2026-09-08. It
does not create Cloud DB, NAT Gateway, Server, Container Registry, KMS, or a
monitoring instance.

## Inventory

| Resource | Name | Import ID |
| --- | --- | --- |
| VPC | `adp-qa-vpc` (`10.20.0.0/16`) | `147670` |
| Private subnet | `adp-qa-private-kr1` (`10.20.10.0/24`, `KR-1`) | `321923` |
| Runtime ACG | `adp-qa-runtime-acg` (no rules) | `393431` |
| Data/artifact bucket | `adp-qa-data-artifacts` | bucket name |
| Terraform state bucket | `adp-qa-tfstate` | bucket name |

The NCP provider supports importing all five resource types. The import blocks
are committed in `environments/qa/imports.tf`; do not run ad-hoc imports to a
different address.

## Credential boundary

Create a QA-only NCP sub-account immediately before adoption and grant only the
permissions needed to read/manage this inventory. Keep credentials in the shell
or an approved secret manager. Never put them in `.tf`, `.tfvars`, state,
Docker images, command history, logs, or Notion.

For repeatable local Docker commands, use the dedicated credential file rather
than the generic Compose `.env`. The dedicated name prevents Terraform
credentials from being mixed with unrelated application settings:

```sh
make env
chmod 600 .env.terraform.local
```

Then edit `.env.terraform.local` locally. Its committed example contains only
empty values:

```dotenv
NCLOUD_ACCESS_KEY=
NCLOUD_SECRET_KEY=
NCLOUD_REGION=KR
```

The file is ignored by Git and automatically loaded by the Makefile. Never put
real values in `.env.terraform.local.example`.

Do not paste the output of `docker compose config` after adding real values: the
rendered Compose configuration contains the expanded credential environment.

For the import and zero-change plan, assign the system-managed
`NCP_VPC_SERVER_VIEWER` policy or an equivalent user-defined policy containing
all of these read actions:

- `View/getVPCList`
- `View/getVPCDetail`
- `View/getSubnetList`
- `View/getSubnetDetail`
- `View/getACGList`
- `View/getACGDetail`

The NCP provider reads the VPC's default ACG while refreshing `ncloud_vpc`, so
`View/getACGList` is required even before the standalone runtime ACG import is
reached. Object Storage list/detail access is also required. Prefer Viewer
permissions during adoption; grant change permissions only for a separately
reviewed Terraform change that truly needs to modify cloud resources.

`compose.yaml` maps the NCP values to both the NCP provider variables and the
AWS-standard variables required by the S3-compatible backend. No duplicate
`AWS_*` entries are needed in the local file. Shell exports remain supported
when `.env.terraform.local` is absent.

Static validation uses a separate Terraform data directory, so `make check`
does not initialize, migrate, or contact an already activated remote backend.

## Stage 1: adopt into local state

1. Run `make check` (or `make check TF="terraform -chdir=environments/qa"`
   with a compatible native CLI).
2. Run `make import-plan` and review the saved plan.
3. The plan must contain exactly five imports and **zero creates, updates,
   replacements, or deletes**. If Terraform proposes any other action, stop and
   reconcile the console values with configuration.
4. Apply only the reviewed plan: `docker compose run --rm terraform apply adoption.tfplan`.
5. Run `make state-list` and confirm all five addresses are present.

`prevent_destroy` is set on the VPC, subnet, ACG, and both buckets. It is a last
guard, not a substitute for reviewing every plan.

## Stage 2: migrate state to Object Storage

1. Confirm the local state has all five resources and copy
   `environments/qa/terraform.tfstate` to an encrypted, access-controlled backup
   outside Git.
2. Export both `NCLOUD_*` and `AWS_*` variables above.
3. Run `make init-remote`. This activates the ignored local `backend.tf` from
   `backend.tf.example`, then starts state migration. Answer yes only when
   Terraform identifies the local state as the source and
   `adp-qa-tfstate/adp-infra/qa/terraform.tfstate` as the destination.
4. Run `make plan`; require zero unintended changes.
5. Confirm the state object exists and is private. Retain the encrypted local
   backup until a remote-state recovery drill succeeds.

NCP Object Storage is S3-compatible at
`https://kr.object.ncloudstorage.com` with region `kr-standard`. The backend
configuration intentionally contains no credentials.

## Recovery

- Never delete either bucket from the console or with `terraform destroy`.
- Do not create `environments/qa/backend.tf` or run `make init-remote` before
  local adoption is complete. The Makefile activates it only at migration time.
- Before a state operation, take an encrypted backup with `terraform state pull`.
- To restore, initialize the same backend, keep the current remote object as an
  incident copy, and use `terraform state push` only after peer review of the
  exact backup and a matching `terraform plan`.
- If the backend is unavailable, use the encrypted local backup with
  `terraform init -backend=false`; do not create replacement cloud resources.
- ACG rules remain absent until a concrete runtime/DB connection exists. Add all
  rules in one `ncloud_access_control_group_rule` resource to avoid overwrites.

## Docker decision

Docker is used only as a reproducible Terraform CLI runner, matching the other
ADP repositories' container-first development workflow. It does not run or
replace NCP infrastructure. `compose.yaml` pins Terraform 1.16.1 and passes only
the ignored `.env.terraform.local` values as runtime environment variables.
Native Terraform remains available through
`TF="terraform -chdir=environments/qa"`; native runs use shell environment
variables and do not consume the Compose env file automatically.

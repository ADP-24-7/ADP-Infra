# ADP-Infra

Terraform source of truth for ADP cloud infrastructure. The current scope is the
cost-minimized NCP QA foundation adopted from console bootstrap resources.

## Current execution order

1. **ADP-Infra (complete)** — VPC, private subnet, runtime ACG, and Object
   Storage buckets are adopted into the locked remote Terraform state without
   create/delete/replace actions.
2. **ADP-DA** — implement `ArtifactStore` and NCP Object Storage upload/download
   with manifest and SHA-256 verification.
3. **ADP-BE** — load validated artifact references and fail closed on schema,
   digest, or scope mismatch.

Cloud DB, NAT Gateway, Server, Container Registry, KMS, runtime deployment, and
monitoring stay out of scope until their documented gates are met.

The target deployment topology and the boundary between verified QA resources
and design-only production controls are defined in
[`docs/production-reference-architecture.md`](docs/production-reference-architecture.md).

The QA remote state is active at
`adp-qa-tfstate/adp-infra/qa/terraform.tfstate`. It tracks exactly five
resources and the post-migration plan is `No changes` with exit code `0`.

## Layout

```text
ADP-Infra/
├── modules/
│   ├── network/
│   └── object-storage/
├── environments/qa/
├── docs/
│   ├── ncp-bootstrap.md
│   └── production-reference-architecture.md
├── compose.yaml
└── Makefile
```

## Quick start

Docker is the default CLI runtime because the other ADP repositories already use
a container-first local workflow. No cloud credential is required for formatting
and static validation.

```sh
make version
make check
```

For authenticated NCP operations, create the ignored local credential file and
fill it only on the operator's machine:

```sh
make env
$EDITOR .env.terraform.local
```

The Makefile automatically passes this file to Docker Compose. The same NCP key
is mapped inside the container to both `NCLOUD_*` provider variables and the
`AWS_*` variables required by the S3-compatible remote backend.

Use a locally installed compatible Terraform CLI with:

```sh
make check TF="terraform -chdir=environments/qa"
```

Resource adoption requires QA-scoped credentials and a zero-change plan. Follow
[`docs/ncp-bootstrap.md`](docs/ncp-bootstrap.md) before any apply or backend
migration.

The S3 backend is intentionally inactive during the first local-state adoption.
Only `make init-remote` activates `backend.tf` after the reviewed import plan has
been applied. Use `make state-verify` before migration and
`make verify-remote` afterward. Recovery from an interrupted migration is
documented in [`docs/ncp-bootstrap.md`](docs/ncp-bootstrap.md).

## Safety rules

- Credentials are accepted only through process environment variables or the
  permission-restricted `.env.terraform.local` file.
- State, plan files, `.tfvars`, `.env`, `.env.terraform.local`, and credentials
  are ignored by Git.
- Every adopted resource uses `prevent_destroy`.
- Runtime ACG rules remain empty/default-deny until a concrete target exists.
- Outputs contain identifiers and bucket names only, never credentials.
- Initial remote state migration is single-operator. Normal remote operations
  use NCP Object Storage conditional-write locking through `use_lockfile`.
- Pull requests run credential-free formatting and static validation in GitHub
  Actions; authenticated plans remain an explicit operator step.

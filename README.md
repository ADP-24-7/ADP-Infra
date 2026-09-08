# ADP-Infra

Terraform source of truth for ADP cloud infrastructure. The current scope is the
cost-minimized NCP QA foundation adopted from console bootstrap resources.

## Current execution order

1. **ADP-Infra** — adopt VPC, private subnet, runtime ACG, and Object Storage
   buckets into Terraform without create/delete/replace actions.
2. **ADP-DA** — implement `ArtifactStore` and NCP Object Storage upload/download
   with manifest and SHA-256 verification.
3. **ADP-BE** — load validated artifact references and fail closed on schema,
   digest, or scope mismatch.

Cloud DB, NAT Gateway, Server, Container Registry, KMS, runtime deployment, and
monitoring stay out of scope until their documented gates are met.

## Layout

```text
ADP-Infra/
├── modules/
│   ├── network/
│   └── object-storage/
├── environments/qa/
├── docs/ncp-bootstrap.md
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
been applied.

## Safety rules

- Credentials are accepted only through process environment variables or the
  permission-restricted `.env.terraform.local` file.
- State, plan files, `.tfvars`, `.env`, `.env.terraform.local`, and credentials
  are ignored by Git.
- Every adopted resource uses `prevent_destroy`.
- Runtime ACG rules remain empty/default-deny until a concrete target exists.
- Outputs contain identifiers and bucket names only, never credentials.

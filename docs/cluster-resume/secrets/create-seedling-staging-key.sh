#!/usr/bin/env bash
# Mint a MinIO service account for the cohort staging job and store it as the abc secrets
# seedling-s3-access-key / seedling-s3-secret-key in su-everest-nf. The key is generated
# locally and never printed; its policy (seedling-staging-policy.json) allows list/read/write
# under su-everest-nf/shared/everest/test_data/reads_full/ only (no delete).
#
# Usage: create-seedling-staging-key.sh <parent-minio-user> [abc-admin-context]
#   <parent-minio-user>  existing MinIO user with access to the su-everest-nf bucket
#                        (list them: abc admin services cli minio -- admin user list local)
#   [abc-admin-context]  context with MinIO admin + Nomad management creds (default abc-bootstrap)
set -euo pipefail
PARENT="${1:?usage: $0 <parent-minio-user> [abc-admin-context]}"
CTX="${2:-abc-bootstrap}"
NS=su-everest-nf
POLICY="$(cd "$(dirname "$0")" && pwd)/seedling-staging-policy.json"

AK="everest-stage-$(openssl rand -hex 6)"
SK="$(openssl rand -base64 30 | tr -d '/+=' | cut -c1-40)"
trap 'unset AK SK' EXIT

ABC_CLI_CONTEXT="$CTX" abc admin services cli minio -- admin user svcacct add local "$PARENT" \
  --access-key "$AK" --secret-key "$SK" --policy "$POLICY" \
  --name everest-staging --description "everest cohort staging (abc job; reads_full only)" >/dev/null
echo "service account created under $PARENT (key id ${AK%%-*}-…)"

ABC_CLI_CONTEXT="$CTX" abc secrets set seedling-s3-access-key "$AK" --backend nomad --namespace "$NS"
ABC_CLI_CONTEXT="$CTX" abc secrets set seedling-s3-secret-key "$SK" --backend nomad --namespace "$NS"

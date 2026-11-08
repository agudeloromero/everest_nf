#!/bin/sh
#ABC --name=everest-secret-read-test
#ABC --namespace=su-everest-nf
#ABC --driver=docker
#ABC --driver.config.image=rclone/rclone:1.68.2
#ABC --driver.config.entrypoint=["/usr/bin/env"]   # image ENTRYPOINT is rclone; run the script via env
#ABC --cores=1
#ABC --mem=256M
#ABC --secret-file=abc-secret-test
#ABC --secret=ABC_SECRET_TEST=secret://abc-secret-test
# Verifies `abc job run --secret/--secret-file`: a job reads the dummy abc secret
# abc-secret-test (a harmless test value, not a credential) both as a file under
# $NOMAD_SECRETS_DIR and as an env var.
set -eu
f="$NOMAD_SECRETS_DIR/abc-secret-test"
[ -s "$f" ] && echo "SECRET_FILE_OK bytes=$(wc -c < "$f") value=$(cat "$f")" || { echo "SECRET_FILE_FAIL"; exit 1; }
[ -n "${ABC_SECRET_TEST:-}" ] && echo "SECRET_ENV_OK value=$ABC_SECRET_TEST" || { echo "SECRET_ENV_FAIL"; exit 1; }
[ "$(cat "$f")" = "$ABC_SECRET_TEST" ] && echo "SECRET_MATCH_OK" || echo "SECRET_MATCH_FAIL"
rclone version | head -1

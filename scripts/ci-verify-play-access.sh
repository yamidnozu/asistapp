#!/usr/bin/env bash
set -euo pipefail

# Script que valida acceso de la service account a la API de Play
# Uso: ./ci-verify-play-access.sh <service_account_json> <package_name>

KEY_FILE=${1:-service_account.json}
PACKAGE_NAME=${2:-com.edevcore.asistapp}

if [ ! -f "$KEY_FILE" ]; then
  echo "ERROR: key file not found: $KEY_FILE"
  exit 2
fi

gcloud --version >/dev/null 2>&1 || { echo "gcloud CLI missing"; exit 1; }

# Authenticate
gcloud auth activate-service-account --key-file="$KEY_FILE"

# Active account
ACTIVE_ACCOUNT=$(gcloud auth list --filter=status:ACTIVE --format="value(account)")
if [ -z "$ACTIVE_ACCOUNT" ]; then
  echo "ERROR: No active account after activation"
  exit 3
fi

echo "Active service account: $ACTIVE_ACCOUNT"

ACCESS_TOKEN=$(gcloud auth print-access-token)
if [ -z "$ACCESS_TOKEN" ]; then
  echo "ERROR: Could not obtain access token"
  exit 4
fi

# Try GET /edits
HTTP_STATUS=$(curl -s -o /tmp/edit.json -w "%{http_code}" -H "Authorization: Bearer $ACCESS_TOKEN" \
  "https://androidpublisher.googleapis.com/androidpublisher/v3/applications/$PACKAGE_NAME/edits")

echo "API http status: $HTTP_STATUS"

if [ "$HTTP_STATUS" -eq 200 ] || [ "$HTTP_STATUS" -eq 201 ]; then
  echo "OK: Service account can see the app."
  head -n 200 /tmp/edit.json || true
  exit 0
fi

if [ "$HTTP_STATUS" -eq 403 ]; then
  echo "ERROR: 403 Forbidden - Service account authenticated but lacks permissions on the app or account."
  exit 5
fi

if [ "$HTTP_STATUS" -eq 404 ]; then
  echo "ERROR: 404 Not Found - The app '$PACKAGE_NAME' is not visible to this service account. Possible causes:"
  echo "  - App not created in this Play Console (first upload not performed)."
  echo "  - Service account not invited/authorized in API access or Users & permissions."
  echo "  - App exists in different developer account."
  head -n 200 /tmp/edit.json || true
  echo "
Hint: If this is the first upload, follow scripts/PLAY_FIRST_UPLOAD.md in the repo for a step-by-step guide to initialize the app and grant Play Console API access."
  exit 6
fi

# Other statuses
echo "Unhandled HTTP status: $HTTP_STATUS"
head -n 200 /tmp/edit.json || true
exit 10

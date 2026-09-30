#!/bin/bash
# Points helm/student-registration/values.yaml at freshly pushed images.
# Only the image.repository and image.tag lines inside the "backend:" and "frontend:" blocks are touched.
#
# Usage: scripts/update-helm-values.sh <backend-repo> <frontend-repo> <tag> [values-file]
set -euo pipefail

BACKEND_REPO="${1:?backend image repository (without tag)}"
FRONTEND_REPO="${2:?frontend image repository (without tag)}"
TAG="${3:?image tag}"
VALUES="${4:-helm/student-registration/values.yaml}"

sed -i -E \
  -e "/^backend:/,/^frontend:/ { s|^([[:space:]]*repository:[[:space:]]*).*|\1${BACKEND_REPO}|; s|^([[:space:]]*tag:[[:space:]]*).*|\1\"${TAG}\"| }" \
  -e "/^frontend:/,/^ingress:/ { s|^([[:space:]]*repository:[[:space:]]*).*|\1${FRONTEND_REPO}|; s|^([[:space:]]*tag:[[:space:]]*).*|\1\"${TAG}\"| }" \
  "${VALUES}"

echo "Updated image references in ${VALUES}:"
grep -nE "repository:|tag:" "${VALUES}"

#!/bin/bash
set -e

IMAGE_NAME="justina_hardware:jazzy"
ARCHIVE_NAME="justina_hardware_jazzy.tar.gz"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

echo "==> SCRIPT_DIR: ${SCRIPT_DIR}"
echo "==> PROJECT_ROOT: ${PROJECT_ROOT}"
echo "==> Construyendo imagen ${IMAGE_NAME}"

docker build \
  -f "${SCRIPT_DIR}/Dockerfile.deploy" \
  -t "${IMAGE_NAME}" \
  "${PROJECT_ROOT}"

echo "==> Exportando imagen a ${ARCHIVE_NAME}"
docker save "${IMAGE_NAME}" | gzip > "${PROJECT_ROOT}/${ARCHIVE_NAME}"

echo "==> Listo:"
echo "${PROJECT_ROOT}/${ARCHIVE_NAME}"

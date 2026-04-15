#!/usr/bin/env bash
set -Eeuo pipefail

# ── Defaults ─────────────────────────────────────────────
TYPE=""
DISTRO=""

# ── Parse args ───────────────────────────────────────────
while [[ $# -gt 0 ]]; do
  case "$1" in
    --type)
      TYPE="${2:-}"
      shift 2
      ;;
    --distro)
      DISTRO="${2:-}"
      shift 2
      ;;
    *)
      echo "Unknown argument: $1"
      exit 1
      ;;
  esac
done

# ── Validate (only presence, not values) ─────────────────
if [[ -z "$TYPE" || -z "$DISTRO" ]]; then
  echo "Usage: $0 --type <type> --distro <distro>"
  exit 1
fi

# ── Variables ────────────────────────────────────────────
IMAGE="ghcr.io/zodium-project/${DISTRO}-${TYPE}"
ISO_NAME="${DISTRO}-${TYPE}.iso"

echo "[*] Building ISO"
echo "    Distro: $DISTRO"
echo "    Type:   $TYPE"
echo "    Image:  $IMAGE"

# ── Build ────────────────────────────────────────────────
sudo bluebuild generate-iso \
  --platform=linux/amd64 \
  --iso-name="$ISO_NAME" \
  --secure-boot-url="https://github.com/zodium-project/zcore-bootc/blob/stable/files/mok-file/etc/pki/akmods/certs/zodium-mok.der" \
  --enrollment-password="zodium" \
  --variant="kinoite" \
  --verbose \
  image "$IMAGE"

echo "[✓] Done: $ISO_NAME"
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

# ── Validate ─────────────────────────────────────────────
if [[ -z "$TYPE" || -z "$DISTRO" ]]; then
  echo "Usage: $0 --type <type> --distro <distro>"
  exit 1
fi

# ── Variables ────────────────────────────────────────────
IMAGE="ghcr.io/zodium-project/${DISTRO}-${TYPE}"
ISO_NAME="${DISTRO}-${TYPE}.iso"
CHECKSUM_NAME="${ISO_NAME}-CHECKSUM"
ITEM_NAME="zodium-${DISTRO}-${TYPE}"

echo "[*] Building ISO"
echo "    Distro : $DISTRO"
echo "    Type   : $TYPE"
echo "    Image  : $IMAGE"

# ── Build ────────────────────────────────────────────────
sudo bluebuild generate-iso \
  --platform=linux/amd64 \
  --iso-name="$ISO_NAME" \
  --secure-boot-url="https://github.com/zodium-project/zcore-bootc/blob/stable/files/mok-file/etc/pki/akmods/certs/zodium-mok.der" \
  --enrollment-password="zodium" \
  --variant="kinoite" \
  --verbose \
  image "$IMAGE"

echo "[✓] Build complete"

# ── Verify output ───────────────────────────────────────
if [[ ! -f "$ISO_NAME" ]]; then
  echo "[✗] ISO not found: $ISO_NAME"
  exit 1
fi

# ── Ensure checksum exists (BlueBuild already does it) ──
if [[ ! -f "$CHECKSUM_NAME" ]]; then
  echo "[*] Generating checksum..."
  sha256sum "$ISO_NAME" > "$CHECKSUM_NAME"
fi

echo "[✓] ISO + checksum ready"

# ── Configure Internet Archive auth ─────────────────────
# required env vars from GitHub Secrets
: "${IA_ACCESS_KEY:?Missing IA_ACCESS_KEY}"
: "${IA_SECRET_KEY:?Missing IA_SECRET_KEY}"

mkdir -p ~/.config/internetarchive

cat > ~/.config/internetarchive/ia.ini <<EOF
[general]
access_key = ${IA_ACCESS_KEY}
secret_key = ${IA_SECRET_KEY}
EOF

# ── Archive upload ───────────────────────────────────────
echo "[*] Uploading to Internet Archive..."

ia upload "$ITEM_NAME" \
  "$ISO_NAME" \
  "$CHECKSUM_NAME" \
  --metadata="title=Zodium $DISTRO $TYPE" \
  --metadata="mediatype=software"

echo "[✓] Upload complete"
echo "👉 https://archive.org/details/$ITEM_NAME"
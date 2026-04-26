#!/usr/bin/env bash
set -Eeuo pipefail

ISO_FILE="$STORAGE/android.iso"

# Forward ADB port for user-mode networking
: "${USER_PORTS:="5555"}"

downloadISO() {

  local url="$1"
  local dest="$2"
  local sum="$3"
  local sum_type="$4"
  local msg="Downloading $APP"

  if [ -f "$dest" ] && [ -s "$dest" ]; then
    info "Found existing ISO at $dest, skipping download..."
    if [ -n "$sum" ] && [ -n "$sum_type" ]; then
      verifyChecksum "$dest" "$sum" "$sum_type" && return 0
      warn "Checksum mismatch, re-downloading..."
      rm -f "$dest"
    else
      return 0
    fi
  fi

  info "$msg..." && html "$msg..."

  local tmp="${dest}.tmp"
  rm -f "$tmp"

  local -a urls=("$url")
  if [ -n "${ISO_MIRRORS:-}" ]; then
    local IFS='|'
    read -ra MIRROR_ARR <<< "$ISO_MIRRORS"
    urls+=("${MIRROR_ARR[@]}")
  fi

  local success=false

  for try_url in "${urls[@]}"; do
    info "Trying: $try_url"
    rm -f "$tmp"
    /run/progress.sh "$tmp" "0" "$msg ([P])..." &

    if curl -L -o "$tmp" -Ss --fail --proto =https \
         --max-time 7200 --connect-timeout 30 \
         --retry 2 --retry-delay 10 --retry-all-errors "$try_url"; then
      fKill "progress.sh"
      if [ -s "$tmp" ]; then
        success=true
        break
      fi
      warn "Downloaded file is empty, trying next URL..."
    else
      fKill "progress.sh"
      warn "Download failed from: $try_url"
    fi
    rm -f "$tmp"
  done

  if [ "$success" = false ]; then
    rm -f "$tmp"
    error "Failed to download ISO from all URLs"
    return 1
  fi

  if [ -n "$sum" ] && [ -n "$sum_type" ]; then
    if ! verifyChecksum "$tmp" "$sum" "$sum_type"; then
      rm -f "$tmp"
      error "Checksum verification failed for downloaded ISO"
      return 1
    fi
    info "Checksum verification passed"
  fi

  mv -f "$tmp" "$dest"
  return 0
}

verifyChecksum() {

  local file="$1"
  local expected="$2"
  local sum_type="$3"
  local actual

  case "${sum_type,,}" in
    "sha1" )
      actual=$(sha1sum "$file" | cut -d' ' -f1)
      ;;
    "sha256" )
      actual=$(sha256sum "$file" | cut -d' ' -f1)
      ;;
    "md5" )
      actual=$(md5sum "$file" | cut -d' ' -f1)
      ;;
    * )
      warn "Unknown checksum type: $sum_type, skipping verification"
      return 0
      ;;
  esac

  if [[ "${actual,,}" != "${expected,,}" ]]; then
    error "Checksum mismatch: expected $expected, got $actual"
    return 1
  fi

  return 0
}

detectCustom() {

  local custom=""

  if [ -f "/custom.iso" ] && [ -s "/custom.iso" ]; then
    custom="/custom.iso"
  fi

  if [ -f "$STORAGE/custom.iso" ] && [ -s "$STORAGE/custom.iso" ]; then
    custom="$STORAGE/custom.iso"
  fi

  if [ -n "$custom" ]; then
    ISO_FILE="$custom"
    ISO_URL=""
    ISO_NAME="custom.iso"
    ISO_SUM=""
    SUM_TYPE=""
    INTERNAL_ID="custom"
    info "Using custom ISO: $custom"
  fi

  return 0
}

startInstall() {

  html "Starting $APP..."

  detectCustom

  if [[ "${ISO_URL,,}" == "http"* ]]; then
    if ! downloadISO "$ISO_URL" "$ISO_FILE" "$ISO_SUM" "$SUM_TYPE"; then
      rm -f "$ISO_FILE" 2>/dev/null || true
      exit 61
    fi
  fi

  if [ ! -f "$ISO_FILE" ] || [ ! -s "$ISO_FILE" ]; then
    error "ISO file not found: $ISO_FILE"
    exit 61
  fi

  # Set BOOT variable so base image's disk.sh adds the ISO as CDROM
  BOOT="$ISO_FILE"

  html "Successfully prepared image for boot..."
  return 0
}

! startInstall && exit 60

return 0

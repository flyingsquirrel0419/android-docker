#!/usr/bin/env bash
set -Eeuo pipefail

: "${VERSION:=""}"

ISO_URL=""
ISO_MIRRORS=""
ISO_NAME=""
ISO_SUM=""
SUM_TYPE=""
INTERNAL_ID=""

parseVersion() {

  if [[ "${VERSION}" == \"*\" || "${VERSION}" == \'*\' ]]; then
    VERSION="${VERSION:1:-1}"
  fi

  VERSION=$(expr "$VERSION" : "^\ *\(.*[^ ]\)\ *$")
  [ -z "$VERSION" ] && VERSION="11"

  case "${VERSION,,}" in
    "9" | "9.0" | "pie" | "android9" | "android 9" | "android 9.0" )
      VERSION="9.0"
      INTERNAL_ID="android9"
      ISO_NAME="android-x86_64-9.0-r2.iso"
      ISO_URL="https://downloads.sourceforge.net/project/android-x86/Release%209.0/android-x86_64-9.0-r2.iso"
      ISO_MIRRORS=""
      ISO_SUM="1cc85b5ed7c830ff71aecf8405c7281a9c995aa0"
      SUM_TYPE="sha1"
      ;;
    "11" | "11.0" | "r11" | "android11" | "android 11" | "android 11.0" | "bliss14" | "blissos14" )
      VERSION="11"
      INTERNAL_ID="bliss14"
      ISO_NAME="Bliss-v14.10.3-x86_64-OFFICIAL-opengapps-20241012.iso"
      ISO_URL="https://downloads.sourceforge.net/project/blissos-x86/Official/BlissOS14/OpenGApps/Generic/Bliss-v14.10.3-x86_64-OFFICIAL-opengapps-20241012.iso"
      ISO_MIRRORS=""
      ISO_SUM=""
      SUM_TYPE=""
      ;;
    "13" | "13.0" | "r13" | "android13" | "android 13" | "android 13.0" | "bliss16" | "blissos16" )
      VERSION="13"
      INTERNAL_ID="bliss16"
      ISO_NAME="Bliss-v16.9.7-x86_64-OFFICIAL-gapps-20241011.iso"
      ISO_URL="https://downloads.sourceforge.net/project/blissos-x86/Official/BlissOS16/Gapps/Generic/Bliss-v16.9.7-x86_64-OFFICIAL-gapps-20241011.iso"
      ISO_MIRRORS=""
      ISO_SUM=""
      SUM_TYPE=""
      ;;
    * )
      if [[ "${VERSION,,}" == "http"* ]]; then
        ISO_URL="$VERSION"
        ISO_NAME="$(basename "${VERSION%%\?*}")"
        ISO_NAME="${ISO_NAME//[!A-Za-z0-9._-]/_}"
        INTERNAL_ID="custom"
        SUM_TYPE=""
        ISO_SUM=""
      else
        error "Invalid VERSION specified, value \"$VERSION\" is not recognized!"
        error "Supported values: 9, 11, 13"
        return 1
      fi
      ;;
  esac

  return 0
}

getVersion() {

  local version="$1"

  case "${version,,}" in
    "android9" | "9.0" )
      echo "android9"
      ;;
    "bliss14" | "11" )
      echo "bliss14"
      ;;
    "bliss16" | "13" )
      echo "bliss16"
      ;;
    * )
      echo "$version"
      ;;
  esac

  return 0
}

hasVersion() {

  local version="$1"

  case "${version,,}" in
    "android9" | "9.0" | "9" | \
    "bliss14" | "11" | \
    "bliss16" | "13" )
      return 0
      ;;
  esac

  return 1
}

printVersion() {

  local id="$1"
  local desc="$2"

  case "${id,,}" in
    "android9" | "9.0" )
      desc="Android 9 (Pie)"
      ;;
    "bliss14" | "11" )
      desc="BlissOS 14 (Android 11)"
      ;;
    "bliss16" | "13" )
      desc="BlissOS 16 (Android 13)"
      ;;
    "custom" )
      desc="Custom Android ISO"
      ;;
  esac

  if [ -z "$desc" ]; then
    desc="Android"
  fi

  echo "$desc"
  return 0
}

! parseVersion && exit 58

return 0

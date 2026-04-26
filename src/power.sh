#!/usr/bin/env bash
set -Eeuo pipefail

: "${QEMU_TIMEOUT:="120"}"

QEMU_TERM=""
QEMU_DIR="/run/shm"
QEMU_PID="$QEMU_DIR/qemu.pid"
QEMU_PTY="$QEMU_DIR/qemu.pty"
QEMU_LOG="$QEMU_DIR/qemu.log"
QEMU_OUT="$QEMU_DIR/qemu.out"
QEMU_END="$QEMU_DIR/qemu.end"

rm -f "$QEMU_DIR/qemu.*"
touch "$QEMU_LOG"

_trap() {
  func="$1" ; shift
  for sig ; do
    trap "$func $sig" "$sig"
  done
}

boot() {

  [ -f "$QEMU_END" ] && return 0

  if [ -s "$QEMU_PTY" ]; then
    if [ "$(stat -c%s "$QEMU_PTY")" -gt 7 ]; then
      info "Android started successfully, visit http://127.0.0.1:8006/ to view the screen..."
      return 0
    fi
  fi

  error "Timeout while waiting for QEMU to boot the machine!"

  local pid
  pid=$(<"$QEMU_PID")
  { kill -15 "$pid" || true; } 2>/dev/null

  return 0
}

finish() {

  local pid
  local cnt=0
  local reason=$1

  touch "$QEMU_END"

  if [ -s "$QEMU_PID" ]; then

    pid=$(<"$QEMU_PID")
    echo && error "Forcefully terminating Android, reason: $reason..."
    { kill -15 "$pid" || true; } 2>/dev/null

    while isAlive "$pid"; do

      sleep 1
      cnt=$((cnt+1))

      [ ! -s "$QEMU_PID" ] && break

      if [ "$cnt" == "5" ]; then
        echo && error "QEMU did not terminate itself, forcefully killing process..."
        { kill -9 "$pid" || true; } 2>/dev/null
      fi

    done

  fi

  closeNetwork

  sleep 0.5
  echo "❯ Shutdown completed!"

  exit "$reason"
}

terminal() {

  local dev=""

  if [ -s "$QEMU_OUT" ]; then

    local msg
    msg=$(<"$QEMU_OUT")

    if [ -n "$msg" ]; then

      if [[ "${msg,,}" != "char"* ||  "$msg" != *"serial0)" ]]; then
        echo "$msg"
      fi

      dev="${msg#*/dev/p}"
      dev="/dev/p${dev%% *}"

    fi
  fi

  if [ ! -c "$dev" ]; then
    dev=$(echo 'info chardev' | nc -q 1 -w 1 localhost "$MON_PORT" | tr -d '\000')
    dev="${dev#*serial0}"
    dev="${dev#*pty:}"
    dev="${dev%%$'\n'*}"
    dev="${dev%%$'\r'*}"
  fi

  if [ ! -c "$dev" ]; then
    error "Device '$dev' not found!"
    finish 34 && return 34
  fi

  QEMU_TERM="$dev"
  return 0
}

_graceful_shutdown() {

  local code=$?

  set +e

  if [ -f "$QEMU_END" ]; then
    info "Received $1 while already shutting down..."
    return
  fi

  touch "$QEMU_END"
  info "Received $1, sending ACPI shutdown signal..."

  if [ ! -s "$QEMU_PID" ]; then
    error "QEMU PID file does not exist?"
    finish "$code" && return "$code"
  fi

  local pid=""
  pid=$(<"$QEMU_PID")

  if ! isAlive "$pid"; then
    error "QEMU process does not exist?"
    finish "$code" && return "$code"
  fi

  echo 'system_powerdown' | nc -q 1 -w 1 localhost "$MON_PORT" > /dev/null

  local cnt=0
  while [ "$cnt" -lt "$QEMU_TIMEOUT" ]; do

    sleep 1
    cnt=$((cnt+1))

    ! isAlive "$pid" && break
    [ ! -s "$QEMU_PID" ] && break

    info "Waiting for Android to shutdown... ($cnt/$QEMU_TIMEOUT)"

    echo 'system_powerdown' | nc -q 1 -w 1 localhost "$MON_PORT" > /dev/null

  done

  if [ "$cnt" -ge "$QEMU_TIMEOUT" ]; then
    error "Shutdown timeout reached, aborting..."
  fi

  finish "$code" && return "$code"
}

SERIAL="pty"
MONITOR="telnet:localhost:$MON_PORT,server,nowait,nodelay"
MONITOR+=" -daemonize -D $QEMU_LOG -pidfile $QEMU_PID"

_trap _graceful_shutdown SIGTERM SIGHUP SIGINT SIGABRT SIGQUIT

return 0

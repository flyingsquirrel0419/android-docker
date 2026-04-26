#!/usr/bin/env bash
set -Eeuo pipefail

: "${APP:="Android"}"
: "${PLATFORM:="x64"}"
: "${BOOT_MODE:="legacy"}"
: "${SUPPORT:="https://github.com/flyingsquirrel0419/android-docker"}"

cd /run

. start.sh
. utils.sh
. reset.sh
. server.sh

. define.sh
. install.sh

. disk.sh
. display.sh
. network.sh
. boot.sh
. proc.sh
. power.sh
. memory.sh
. config.sh
. finish.sh

trap - ERR

version=$(qemu-system-x86_64 --version | head -n 1 | cut -d '(' -f 1 | awk '{ print $NF }')
info "Booting ${APP}${BOOT_DESC} using QEMU v$version..."

{ qemu-system-x86_64 ${ARGS:+ $ARGS} >"$QEMU_OUT" 2>"$QEMU_LOG"; rc=$?; } || :
(( rc != 0 )) && error "$(<"$QEMU_LOG")" && exit 15

terminal
( sleep 30; boot ) &
tail -fn +0 "$QEMU_LOG" --pid=$$ 2>/dev/null &
cat "$QEMU_TERM" 2>/dev/null | tee "$QEMU_PTY" | \
sed -u -e 's/\x1B\[[=0-9;]*[a-z]//gi' \
-e 's/\x1B\x63//g' -e 's/\x1B\[[=?]7l//g' \
-e '/^$/d' -e 's/\x44\x53\x73//g' & wait $! || :

sleep 1 & wait $!
[ ! -f "$QEMU_END" ] && finish 0

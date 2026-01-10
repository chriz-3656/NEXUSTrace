#!/bin/bash
set -euo pipefail

# ——— Detect Termux ———
if [ -n "$ANDROID_ROOT" ] || [ -d "/system/bin" ]; then
  IS_TERMUX=1
fi

# ——— Safe Colors ———
if [ "$IS_TERMUX" = "1" ] && ! command -v tput >/dev/null 2>&1; then
  RED="\e[31m"; GRN="\e[32m"; YLW="\e[33m"; CYA="\e[36m"; RST="\e[0m"; BLD="\e[1m"
else
  RED=$(tput setaf 1); GRN=$(tput setaf 2); YLW=$(tput setaf 3)
  CYA=$(tput setaf 6); RST=$(tput sgr0); BLD=$(tput bold)
fi

ROOT="$(cd "$(dirname "$0")" && pwd)"
CAPTURE_DIR="$ROOT/capture"
NEXUS_LOG="$CAPTURE_DIR/nexustrace.log"
PORT="8080"

clear
echo -e "${CYA}${BLD}NEXUSTRACE CLEANUP${RST}"
echo -e "${YLW}This will:${RST}
- stop PHP server & Cloudflare tunnel
- delete old log files
- create fresh empty logs
- NOT touch your project files
"
read -rp "⚠️  Permanently erase all captured logs? (y/N): " ANSW
case "$ANSW" in
  y|Y) ;;
  *) echo -e "${GRN}✅ Cleanup aborted. Logs kept.${RST}"; exit 0 ;;
esac

# ——— Stop Processes ———
echo -e "${YLW}[*] Stopping PHP server on port ${PORT}...${RST}"
if command -v ss >/dev/null 2>&1; then
  PIDS=$(ss -ltnp 2>/dev/null | grep ":${PORT}" | awk '{print $6}' | sed 's/pid=//;s/,.*//' | sort -u || true)
else
  PIDS=""
fi
for pid in $PIDS; do kill "$pid" 2>/dev/null || true; done

echo -e "${YLW}[*] Stopping cloudflared...${RST}"
pkill -f cloudflared 2>/dev/null || true

# ——— Reset Logs ———
echo -e "${YLW}[*] Removing old logs...${RST}"
rm -rf "$CAPTURE_DIR"
mkdir -p "$CAPTURE_DIR"
touch "$NEXUS_LOG"

# ——— Done ———
clear
echo -e "${GRN}${BLD}🔒 NEXUSTRACE RESET${RST}"
echo -e "${GRN}All logs wiped. Fresh session ready.${RST}"
echo -e "${CYA}Run ./serve.sh to start.${RST}"

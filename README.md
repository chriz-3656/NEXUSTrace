<p align="center">
  <img src="https://i.ibb.co/pr6wWrjh/nexuxtrace.png" width="800" alt="NEXUSTrace Banner">
</p>
# ⭐ NEXUSTRACE — Ethical Geolocation Telemetry Beacon
### *By Chriz • SKY TECH&CRAFTS*

<p align="center">
  <img src="https://img.shields.io/badge/Platform-Linux%20%7C%20WSL%20%7C%20macOS-blue?style=for-the-badge" />
  <img src="https://img.shields.io/badge/Security-Red%20Team-green?style=for-the-badge" />
  <img src="https://img.shields.io/badge/Tunnel-Cloudflare-orange?style=for-the-badge" />
  <img src="https://img.shields.io/badge/License-MIT-yellow?style=for-the-badge" />
</p>

---

## ⚡ Overview  

NEXUSTRACE is a self-contained, ethical geolocation telemetry system for red-team demonstrations and cyber-security education.

It hosts a local webpage, exposes it globally via an HTTPS Cloudflare Tunnel, and—only after explicit user consent—captures:

- 🌐 IP Address  
- 📍 Precise Geolocation (HTML5)  
- 🗺 Direct Google Maps link  
- ⏱ UTC Timestamp  
- ✔ Consent Status  

All events are displayed in real-time inside a beautiful, hacker-style terminal interface.

---

## ✨ Features

- Global HTTPS Tunnel via Cloudflare  
- Consent-based geolocation capture  
- Real-time neon terminal activity feed  
- Flashing NEW TARGET animation  
- Silent background log handling  
- Cleanup/reset utility  
- Local-first privacy design  

---

## 📁 Project Structure

```
NEXUSTrace/
├── serve.sh
├── cleanup.sh
├── index.html
├── beacon.php
├── cloudflared(will be autodownload)
├── capture/
│   └── nexustrace.log
└── README.md
```

---

## 🚀 Getting Started

### 1. Clone the repo
```
git clone https://github.com/chrizmonsaji/NEXUSTrace.git
```
### 2. Change Directory
```
cd NEXUSTrace
```
### 3. Make scripts executable
```
chmod +x serve.sh cleanup.sh
```

### 4. Launch NEXUSTrace
```
./serve.sh
```

You’ll receive:

```
🌍 GLOBAL LINK: https://example.trycloudflare.com
📡 Waiting for connections...
```

### 5. Cleanup logs
```
./cleanup.sh
```

---

## 🔧 Flowchart

```
./serve.sh
     │
     ├── Start PHP server
     ├── Start Cloudflare Tunnel
     ├── Print global HTTPS link
     └── Begin live monitoring
            │
            ▼
   User opens global link
            │
            ▼
 index.html logs IP + requests location permission
            │
   ┌────────┴────────┐
   │                 │
Permission Granted  Permission Denied
   │                 │
   ▼                 ▼
 Send geo data      Send IP-only
to beacon.php       to beacon.php
   │                 │
   ▼                 ▼
Logs written + activity displayed
```

---

## 🛡 Ethical Use Policy

NEXUSTRACE is built **ONLY** for:

- Cybersecurity training  
- Red-team demos  
- Awareness programs  

Not allowed:

❌ Tracking without consent  
❌ Harassment  
❌ Illegal monitoring  

---

## 📜 License  
GNU GENERAL PUBLIC LICENSE  
This project uses the GNU GPL license to ensure all derivative works remain open-source and transparent, in alignment with ethical security research.
---

## 🌟 Author  
**Chriz**  
SKY TECH&CRAFTS

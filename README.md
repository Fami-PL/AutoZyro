# 🚀 AutoZyro – Ultimate Arch Gaming Setup

**AutoZyro** is a modern, interactive bash script that turns a fresh Arch Linux install into a high-performance gaming machine in minutes – with smart defaults, automatic GPU detection, and a clean hybrid memory setup.

[![Arch Linux](https://img.shields.io/badge/Arch%20Linux-Success?style=for-the-badge&logo=arch-linux&logoColor=white&color=1793D1)](https://archlinux.org)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg?style=for-the-badge)](https://opensource.org/licenses/MIT)

---

## ✨ Why AutoZyro?

Manual Arch gaming setup takes hours of reading the wiki.  
AutoZyro does it in one run with:

- **Automatic GPU detection** (NVIDIA / AMD / Intel) + optimal drivers  
- **Interactive menu**: choose **Full** or **Minimal** mode + yay/paru  
- **Hybrid memory**: **8 GB zRAM** (high priority) + **16 GB swapfile** (backup)  
- **Wayland-ready NVIDIA config** (fbdev=1, modeset=1)  
- **Full Pipewire audio stack** + EasyEffects-ready  
- **Zen kernel option**, gamemode, mangohud, gamescope, ProtonUp-Qt, etc.

---

## 📋 Requirements

- **Clean Arch Linux install** (preferably after `archinstall` – minimal or gaming profile)  
- **Working internet connection** (~2–8 GB download depending on mode)  
- **User with sudo privileges** (no root password required during run)  
- **At least 16 GB RAM recommended** (32 GB+ ideal)  
- **SSD/NVMe drive** (zRAM + swapfile perform best on fast storage)

---

## 🚀 Quick Start

Ensure you have a working internet connection, then run:

```bash
git clone https://github.com/Fami-PL/AutoZyro.git
cd AutoZyro
chmod +x AutoZyro.sh
./AutoZyro.sh
```

---

## 📦 Feature Comparison

| Feature | Full Mode | Minimal Mode |
| :--- | :---: | :---: |
| **GPU Drivers & Kernel Tweaks** | ✅ | ✅ |
| **Steam & Gaming Tools** | ✅ | ✅ |
| **zRAM & Swap Optimization** | ✅ | ✅ |
| **ZSH + Pure Prompt** | ✅ | ❌ |
| **Vivaldi & Discord** | ✅ | ❌ |
| **Java 17 & 21 (Temurin)** | ✅ | ❌ |
| **CUDA & cuDNN (NVIDIA)** | ✅ | ❌ |

---

## 💡 Pro Tips

1. **GE-Proton**: Use the pre-installed **ProtonUp-Qt** to download the latest GE-Proton for Steam.
2. **Performance HUD**: Use `MANGOHUD=1 %command%` in Steam to see your stats.
3. **Audio EQ**: Open **EasyEffects** (available in Full mode) to configure mic noise suppression.
4. **Wayland**: NVIDIA enthusiasts can check `cat /sys/module/nvidia_drm/parameters/fbdev` (should be `Y`).

---

## 🤝 Contributing

Feel free to fork, open issues, and submit PRs to keep AutoZyro the #1 choice for Arch Gamers!

Developed with ❤️ for the Arch Community.

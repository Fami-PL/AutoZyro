# 🚀 AutoZyro - Ultimate Arch Gaming Experience

**AutoZyro** is an advanced, all-in-one setup script designed to transform a fresh Arch Linux installation into a powerhouse for gaming, AI development, and daily productivity.

[![Arch Linux](https://img.shields.io/badge/Arch%20Linux-Success?style=for-the-badge&logo=arch-linux&logoColor=white&color=1793D1)](https://archlinux.org)
[![Licence](https://img.shields.io/badge/License-MIT-Success?style=for-the-badge&color=yellow)](LICENSE)

---

## ✨ Key Features

### 🎮 Gaming & Performance
- **Linux Zen Kernel**: Automatically installs and configures the Zen kernel for superior frame rates and system responsiveness.
- **GPU Auto-Detection**: Intellectually detects your hardware (NVIDIA, AMD, or Intel) and installs the perfect driver stack.
- **GameCore Suite**: Installs Steam, Prism Launcher (Minecraft), Heroic Games Launcher, GameMode, MangoHud, and GameScope.
- **Memory Mastery**: Configures **8GB zRAM** for fast processing and a **16GB Swapfile** to prevent crashes during heavy modding sessions.

### 🎥 Multimedia & Sound
- **High-Fidelity Audio**: Full Pipewire setup with **Bit-Perfect Playback** (up to 192kHz) and EasyEffects for system-wide EQ.
- **Codecs Galore**: All essential GStreamer and FFmpeg codecs for a flawless YouTube and streaming experience.
- **Vivaldi Browser**: Premium web experience with hardware-accelerated video support.

### 🛠️ Hardware & System
- **NVIDIA Pro Config**: Implements "No-Tearing" (ForceFullCompositionPipeline) and DKMS support to ensure your drivers never break.
- **Peripheral Support**: Out-of-the-box support for **Bluetooth** and **PS4/DualSense Controllers** (ds4drv + udev rules).
- **Auto-Housekeeping**: Weekly cache cleaning via `paccache` to keep your drive from filling up.

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

## 📦 What's Included?

| Category | Components |
| :--- | :--- |
| **Kernel** | `linux-zen`, `linux-zen-headers` |
| **Drivers** | `nvidia-dkms` (AI/Gaming tuned), `amdgpu`, `vulkan-intel` |
| **Browsers** | `Vivaldi`, `Discord` |
| **Launchers** | `Steam`, `Prism Launcher`, `Heroic Games Launcher` |
| **Tools** | `ProtonUp-Qt`, `MangoHud`, `GameScope`, `EasyEffects` |
| **Java** | `Adoptium (Temurin) 17, 21, 25` |

---

## ⚙️ Advanced Optimizations

AutoZyro doesn't just install apps; it tunes your OS:
- **vm.max_map_count**: Boosted to `2147483642` for massive open-world games.
- **Power Modes**: Integrated `power-profiles-daemon` for maximum CPU performance.
- **X11 NVIDIA Tweak**: Zero screen-tearing configuration.
- **ZRAM**: Dynamic compression with `zstd` algorithm.

---

## 🤝 Contributing

Feel free to fork, open issues, and submit PRs to make the Arch Gaming experience even better for everyone!

---

Developed with ❤️ for the Arch Community.

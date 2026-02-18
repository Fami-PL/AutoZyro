# 🚀 AutoZyro – Ultimate Arch Gaming Setup

**AutoZyro** is a modern, interactive bash script that transforms a fresh Arch Linux installation into a high-performance gaming machine in minutes – featuring smart defaults, automatic GPU detection, and a professional hybrid memory configuration.

[![Arch Linux](https://img.shields.io/badge/Arch%20Linux-Success?style=for-the-badge&logo=arch-linux&logoColor=white&color=1793D1)](https://archlinux.org)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg?style=for-the-badge)](https://opensource.org/licenses/MIT)

---

## ✨ Why AutoZyro?

Manual Arch gaming configuration can take hours. **AutoZyro** automates the entire process while keeping you in control:

- **Smart GUI Detection**: Automatically detects your Desktop Environment (KDE/GNOME/etc.) and installs appropriate tools to avoid unnecessary library bloat.
- **Auto GPU Detection**: Intellectually detects **NVIDIA / AMD / Intel** hardware and applies the optimal driver stack.
- **Interactive Setup**: Choose between **Full** or **Minimal** modes and select your preferred AUR helper (**yay** or **paru**).
- **Hybrid Memory**: Configures **8 GB zRAM** (high priority) + **16 GB swapfile** (backup) for maximum stability.
- **Optional CUDA**: Provides an interactive prompt for NVIDIA users to choose if they need AI/ML support (saving ~2-3 GB).
- **Pro Audio**: Full PipeWire stack with high-bitrate support and EasyEffects readiness.
- **Gaming Suite**: Zen kernel option, GameMode, MangoHud, GameScope, ProtonUp-Qt, and Vulkan diagnostics.

---

## 📋 Requirements

- **Clean Arch Linux install** (recommended after `archinstall` – minimal or gaming profile).
- **Working internet connection** (downloads between 2 GB and 8 GB depending on mode).
- **User with sudo privileges**.
- **At least 16 GB RAM** (32 GB+ ideal for zRAM).
- **SSD/NVMe drive** (essential for hybrid swap performance).

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

## 📦 What does AutoZyro install? (February 2026 Edition)

### 1. Official Arch Repositories (Pacman)
| Group | Package(s) | Mode | Comment |
| :--- | :--- | :---: | :--- |
| **Kernel** | `linux-zen` (+headers) | Optional | Best for gaming responsiveness |
| **GPU Drivers** | `nvidia-dkms` / `amdgpu` / `intel` | Auto | Full Vulkan/Mesa/32-bit support |
| **GPU Tools** | `nvtop` (NVIDIA) / `radeontop` (AMD) | Auto | Real-time temp & VRAM monitoring |
| **Gaming Core** | `steam`, `gamemode`, `mangohud`, `gamescope` | Always | The Linux gaming trifecta |
| **Wine** | `wine-staging`, `winetricks` | Always | For non-Steam gaming needs |
| **Audio** | `pipewire` (full stack) + `easyeffects` | Always | Modern 192kHz bit-perfect audio |
| **Diagnostics** | `vulkan-tools`, `mesa-demos`, `vulkaninfo` | Always | Driver verification and debugging |
| **Monitoring** | `fastfetch`, `btop`, `htop` | Always | Modern resource monitoring |
| **Smart GUI** | `dolphin`, `konsole`, `ark`, `kate` | Full (KDE) | Clean install based on DE detection |

### 2. Arch User Repository (AUR)
| Component | Script Package | Source | Comment |
| :--- | :--- | :---: | :--- |
| **MC Launcher** | `prismlauncher-bin` | AUR | Binary version (fast install) |
| **Epic/GOG** | `heroic-games-launcher-bin` | AUR | Official binary build |
| **Proton GUI** | `protonup-qt-bin` | AUR | Manage GE-Proton easily |
| **Controllers** | `game-devices-udev` | AUR | Better support for DS4/Xbox pads |
| **Java (Temurin)**| `jdk17-temurin`, `jdk21-temurin` | AUR | Optimal for modern Minecraft |
| **ZSH Prompt** | `zsh-pure-prompt` | AUR | Fast and minimalist shell look |
| **Browser** | `vivaldi` | AUR/Ext | High performance + ffmpeg codecs |
| **Chat** | `discord` | AUR/Ext | Official pacman-based build |

---

## 💡 Pro Tips

1. **GE-Proton**: Use **ProtonUp-Qt** to download the latest GE-Proton for Steam or Heroic.
2. **Performance HUD**: Add `MANGOHUD=1 %command%` to your Steam launch options.
3. **Wayland**: NVIDIA users can verify setup: `cat /sys/module/nvidia_drm/parameters/fbdev` (should return `Y`).
4. **Verification**: After installation, the script automatically checks your setup – look for the `POST-INSTALLATION VERIFICATION` report.

---

## 🤝 Contributing

Have an idea for improvement? Feel free to fork, open an issue, or submit a PR. Let's build the ultimate Arch environment for gamers together!

Developed with ❤️ for the Arch Linux Community.

#!/bin/bash

# ==============================================================================
# AutoZyro - Arch Gaming Setup Script
# ==============================================================================
# Installs: Prism Launcher, Steam, Heroic, ProtonUp-Qt, Java (17, 21)
# Optimized for performance and ease of use.
# ==============================================================================

# --- Colors & Aesthetics ---
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color
BOLD='\033[1m'

# --- Banner ---
print_banner() {
    clear
    echo -e "${PURPLE}${BOLD}"
    echo "    ___         __        _____                      "
    echo "   /   | __  __/ /_____  /__  /_  __________  ____   "
    echo "  / /| |/ / / / __/ __ \   / / / / / / ___/ / / / __ \ "
    echo " / ___ / /_/ / /_/ /_/ /  / /_/ /_/ / /  / /_/ / /_/ / "
    echo "/_/  |_\__,_/\__/\____/  /____/\__, /_/   \__,_/\____/  "
    echo "                              /____/                    "
    echo -e "${CYAN}                AutoZyro: Ultimate Arch Gaming Setup${NC}"
    echo "----------------------------------------------------------------------"
}

# --- Helpers ---
info() { echo -e "${BLUE}[AutoZyro]${NC} $1"; }
success() { echo -e "${GREEN}[AutoZyro]${NC} $1"; }
warn() { echo -e "${YELLOW}[AutoZyro]${NC} $1"; }
error() { echo -e "${RED}[AutoZyro]${NC} $1"; exit 1; }

# --- Internet Check ---
check_internet() {
    info "Checking internet connection..."
    if ! ping -c 1 8.8.8.8 &>/dev/null; then
        error "No internet connection! Please connect to the internet before running AutoZyro."
    fi
    success "Internet connection detected."
}

# --- 0. Initialization ---
MINIMAL=false
AUR_HELPER="yay"


# --- GPU Detection ---
detect_gpu() {
    info "Detecting hardware..."
    if lspci | grep -qi "nvidia"; then
        echo "nvidia"
    elif lspci | grep -qi "amd"; then
        echo "amd"
    elif lspci | grep -qi "intel"; then
        echo "intel"
    else
        echo "unknown"
    fi
}


# --- Check for Root ---
if [[ $EUID -eq 0 ]]; then
   error "Do not run AutoZyro as root! It will ask for sudo when needed."
fi

print_banner

# --- 0. Pre-Flight Check & Warning ---
warn "This script makes significant changes to your system (Kernel, Drivers, Shell, Memory)."
warn "Source: https://github.com/Fami-PL/AutoZyro"
read -p "[AutoZyro] Continue with the installation? (y/N): " initial_confirm
[[ "$initial_confirm" =~ ^[Yy]$ ]] || exit 0

check_internet

# --- 0.1 Interactive Setup Menu ---
echo -e "\n${YELLOW}${BOLD}SETUP CONFIGURATION${NC}"
echo -e "Choose your installation mode:"
echo -e "  [1] ${CYAN}Full${NC} (Recommended: ZSH, Pure Prompt, Vivaldi, Discord, Java, etc.)"
echo -e "  [2] ${CYAN}Minimal${NC} (Lightweight: Core gaming tools, drivers & memory tweaks only)"
echo ""
read -p "[AutoZyro] Selection (1 or 2): " mode_choice

if [[ "$mode_choice" == "2" ]]; then
    MINIMAL=true
    info "Minimal mode selected."
else
    MINIMAL=false
    info "Full mode selected."
fi

echo -e "\n${YELLOW}${BOLD}AUR HELPER SELECTION${NC}"
echo -e "Choose your preferred AUR helper:"
echo -e "  [1] ${CYAN}yay${NC} (Default, most popular)"
echo -e "  [2] ${CYAN}paru${NC} (Rust-based, very fast)"
echo ""
read -p "[AutoZyro] Selection (1 or 2): " helper_choice

if [[ "$helper_choice" == "2" ]]; then
    AUR_HELPER="paru"
    info "Using paru as AUR helper."
else
    AUR_HELPER="yay"
    info "Using yay as AUR helper."
fi

sleep 1


# --- VM/Container Detection ---
if systemd-detect-virt --quiet &>/dev/null; then
    warn "VM or container detected. Kernel installation and heavy tweaks will be skipped."
    MINIMAL=true
fi

GPU_TYPE=$(detect_gpu)
info "Hardware detected: ${PURPLE}${BOLD}${GPU_TYPE}${NC}"

install_nvidia() {
    info "Detecting kernel and installing headers..."
    # Detect the currently running kernel to install correct headers
    CURRENT_KERNEL=$(pacman -Q | grep -E "^linux(-zen|-lts|-hardened)? " | awk '{print $1}')
    if [[ -z "$CURRENT_KERNEL" ]]; then
        # Fallback to standard linux if not detected (unlikely on Arch)
        CURRENT_KERNEL="linux"
    fi
    
    info "Installing headers for $CURRENT_KERNEL..."
    sudo pacman -S --needed --noconfirm "${CURRENT_KERNEL}-headers"

    info "Installing NVIDIA Drivers (DKMS - works with all kernels: Zen, LTS, etc.)..."
    sudo pacman -S --needed --noconfirm \
        nvidia-dkms \
        nvidia-utils \
        lib32-nvidia-utils \
        nvidia-settings \
        nvtop

    # CUDA removed from here - moved to interactive prompt after Java

    info "Configuring Kernel Modules for NVIDIA (Wayland compatible)..."
    # Essential modules
    MODULES="nvidia nvidia_modeset nvidia_drm"
    # Check if CUDA is installed to add UVM
    if pacman -Qq cuda &>/dev/null || [[ "$MINIMAL" == false ]]; then
        MODULES="$MODULES nvidia_uvm"
    fi
    
    if ! grep -q "$MODULES" /etc/mkinitcpio.conf; then
        sudo sed -i "s/MODULES=(/MODULES=($MODULES /" /etc/mkinitcpio.conf
        sudo mkinitcpio -P
    fi

    if [[ ! -f /etc/modprobe.d/nvidia.conf ]]; then
        echo "options nvidia-drm modeset=1 fbdev=1" | sudo tee /etc/modprobe.d/nvidia.conf
    fi

    # Conditional X11 tearing fix (skip on Wayland)
    if [[ "$XDG_SESSION_TYPE" == "x11" || -z "$XDG_SESSION_TYPE" ]]; then
        info "Applying NVIDIA X11 No-Tearing Config..."
        sudo mkdir -p /etc/X11/xorg.conf.d/
        cat <<EOF | sudo tee /etc/X11/xorg.conf.d/20-nvidia.conf
Section "Screen"
    Identifier "nvidia"
    Device "nvidia"
    Option "ForceFullCompositionPipeline" "on"
    Option "AllowIndirectGLXProtocol" "off"
    Option "TripleBuffer" "on"
EndSection
EOF
    else
        info "Wayland detected. Skipping legacy X11 config."
    fi

    sudo systemctl enable --now nvidia-persistenced.service
    success "NVIDIA setup completed."
}

install_amd() {
    info "Installing AMD Drivers..."
    sudo pacman -S --needed --noconfirm \
        xf86-video-amdgpu \
        vulkan-radeon \
        lib32-vulkan-radeon \
        libva-mesa-driver \
        lib32-libva-mesa-driver \
        mesa-vdpau \
        lib32-mesa-vdpau \
        radeontop
    success "AMD setup completed."
}

install_intel() {
    info "Installing Intel Drivers..."
    sudo pacman -S --needed --noconfirm \
        vulkan-intel \
        lib32-vulkan-intel \
        intel-media-driver \
        libva-intel-driver \
        lib32-libva-intel-driver
    success "Intel setup completed."
}

# --- 1. Enable Multilib ---
info "Checking if multilib is enabled..."
if grep -q "^\[multilib\]" /etc/pacman.conf; then
    success "Multilib is already enabled."
else
    info "Enabling multilib repository..."
    sudo sed -i '/#\[multilib\]/,/#Include = \/etc\/pacman.d\/mirrorlist/ s/#//' /etc/pacman.conf
    sudo pacman -Syu --noconfirm
    success "Multilib enabled."
fi

# --- 1.1 Kernel Zen Installation ---
if [[ "$CURRENT_KERNEL" != "linux-zen" ]]; then
    read -p "[AutoZyro] Would you like to install the Linux Zen kernel for better responsiveness? (y/N): " zen_choice
    if [[ "$zen_choice" =~ ^[Yy]$ ]]; then
        info "Installing Linux Zen kernel..."
        sudo pacman -S --needed --noconfirm linux-zen linux-zen-headers
        if command -v grub-mkconfig &>/dev/null && [[ -f /boot/grub/grub.cfg ]]; then
            info "Updating GRUB configuration..."
            sudo grub-mkconfig -o /boot/grub/grub.cfg
        else
            info "Skipping GRUB update (systemd-boot or other bootloader detected)."
        fi
        success "Linux Zen installed."
    fi
fi

# --- 2. Update System ---
info "Updating system repositories..."
sudo pacman -Syu --noconfirm

# --- 2.5 Hardware-Specific installation ---
case $GPU_TYPE in
    "nvidia")
        install_nvidia
        ;;
    "amd")
        install_amd
        ;;
    "intel")
        install_intel
        ;;
    *)
        warn "Generic GPU or VM detected. No specific drivers will be installed."
        ;;
esac

# --- 3. Install Core Dependencies & Housekeeping ---
info "Installing base-devel, git, network tools and housekeeping..."
sudo pacman -S --needed --noconfirm \
    base-devel git networkmanager wireless_tools wpa_supplicant \
    pacman-contrib power-profiles-daemon \
    zsh zsh-autosuggestions zsh-syntax-highlighting \
    lib32-gcc-libs lib32-glibc lib32-libx11 lib32-mesa lib32-vulkan-icd-loader \
    libva-mesa-driver lib32-libva-mesa-driver \
    wget curl unzip rsync \
    fastfetch btop htop vulkan-tools \
    vulkan-icd-loader lib32-vulkan-icd-loader \
    vulkan-validation-layers vulkan-mesa-layers

# Enable Housekeeping & Power Mode
info "Enabling Housekeeping (paccache) and Power Management..."
sudo systemctl enable --now paccache.timer
sudo systemctl enable --now power-profiles-daemon

# --- 4. Install AUR Helper ---
if command -v $AUR_HELPER &> /dev/null; then
    success "$AUR_HELPER is already installed."
else
    info "Installing $AUR_HELPER (AUR helper)..."
    git clone https://aur.archlinux.org/${AUR_HELPER}-bin.git /tmp/${AUR_HELPER}-bin
    cd /tmp/${AUR_HELPER}-bin && makepkg -si --noconfirm
    cd - && rm -rf /tmp/${AUR_HELPER}-bin
    success "$AUR_HELPER installed."
fi

# Optimization for AUR helper
if [[ "$AUR_HELPER" == "yay" ]]; then
    yay -Y --gendb &>/dev/null
fi

# --- 5. Install System Essentials (Sound, Bluetooth, Network) ---
info "Installing System Essentials (Pipewire, Bluetooth, NetworkManager)..."
sudo pacman -S --needed --noconfirm \
    networkmanager \
    bluez \
    bluez-utils \
    blueman \
    pipewire \
    pipewire-pulse \
    pipewire-alsa \
    pipewire-jack \
    wireplumber \
    pavucontrol \
    easyeffects \
    gst-plugins-good \
    gst-plugins-bad \
    gst-plugins-ugly \
    gst-libav \
    ffmpeg

# Enable Services
info "Enabling System Services..."
sudo systemctl enable --now NetworkManager
sudo systemctl enable --now bluetooth

# Configure Flathub
if command -v flatpak &> /dev/null; then
    info "Adding Flathub remote..."
    sudo flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
    flatpak update --appstream &>/dev/null || true
fi

# --- 5.1 High Quality Audio Tweaks ---
info "Applying High Quality Audio Tweaks..."
mkdir -p ~/.config/pipewire/pipewire.conf.d/
cat <<EOF > ~/.config/pipewire/pipewire.conf.d/10-rates.conf
context.properties = {
    default.clock.allowed-rates = [ 44100 48000 88200 96000 176400 192000 ]
}
EOF
success "Audio codecs and bit-perfect playback configured."

# --- 6. Install Steam & Gaming Utilities ---
info "Installing Steam and basic gaming drivers/tools..."
sudo pacman -S --needed --noconfirm \
    steam \
    gamemode \
    lib32-gamemode \
    mangohud \
    lib32-mangohud \
    goverlay \
    gamescope \
    vulkan-icd-loader \
    lib32-vulkan-icd-loader \
    wine-staging \
    winetricks \
    flatpak

# --- 7. Install Extra Packages ---
info "Installing extra packages..."
AUR_PACKAGES=("protonup-qt-bin" "game-devices-udev")

if [[ "$MINIMAL" == false ]]; then
    AUR_PACKAGES+=("prismlauncher-bin" "heroic-games-launcher-bin" "vivaldi" "vivaldi-ffmpeg-codecs" "discord")
    
    # DE-Aware GUI Installation
    if [[ "$XDG_CURRENT_DESKTOP" == "KDE" ]] || [[ "$XDG_SESSION_DESKTOP" == "KDE" ]]; then
        info "KDE Plasma detected. Installing optimized GUI tools..."
        sudo pacman -S --needed --noconfirm \
            konsole dolphin discover plasma-browser-integration ark spectacle kate
    else
        warn "Non-KDE environment or TTY detected ($XDG_CURRENT_DESKTOP)."
        read -p "[AutoZyro] Environment is not KDE. Still install KDE suite (Dolphin, Konsole, etc.)? (y/N): " kde_choice
        if [[ "$kde_choice" =~ ^[Yy]$ ]]; then
            sudo pacman -S --needed --noconfirm \
                konsole dolphin discover plasma-browser-integration ark spectacle kate
        fi
    fi
fi

$AUR_HELPER -S --needed "${AUR_PACKAGES[@]}"

# --- 7.1 Install Java Versions (Adoptium/Temurin) ---
if [[ "$MINIMAL" == false ]]; then
    info "Installing Adoptium Java 17 and 21..."
    $AUR_HELPER -S --needed jdk17-temurin jdk21-temurin
fi

# --- 7.2 Optional CUDA for NVIDIA (Full Mode) ---
if [[ "$MINIMAL" == false ]] && [[ "$GPU_TYPE" == "nvidia" ]]; then
    echo -e "\n${YELLOW}${BOLD}AI/ML SUPPORT (NVIDIA CUDA)${NC}"
    read -p "[AutoZyro] Install CUDA + cuDNN? (Needed for AI/ML, consumes ~2-3 GB) (y/N): " cuda_q
    if [[ "$cuda_q" =~ ^[Yy]$ ]]; then
        sudo pacman -S --needed --noconfirm cuda cudnn
        success "CUDA + cuDNN installed."
    else
        info "Skipping CUDA installation."
    fi
fi

# --- 8. Configuration & Optimizations ---
info "Configuring system for peak performance..."

# vm.max_map_count is already 1048576 by default in Arch since 2024
info "vm.max_map_count is already optimized by Arch default (1048576)."

# --- 8.2 Electron & Wayland Optimizations ---
info "Configuring Electron Optimizations..."
sudo mkdir -p /etc/environment.d/
cat <<EOF | sudo tee /etc/environment.d/10-electron.conf
ELECTRON_OZONE_PLATFORM_HINT=auto
EOF
success "Electron set to auto platform (Wayland/X11)."

# --- 8.3 ZSH & Pure Prompt Configuration ---
if [[ "$MINIMAL" == false ]]; then
    info "Configuring ZSH and Pure Prompt..."
    $AUR_HELPER -S --noconfirm zsh-pure-prompt

    # Set ZSH as default shell
    CURRENT_USER=$(whoami)
    if [[ $SHELL != "/usr/bin/zsh" ]]; then
        sudo chsh -s /usr/bin/zsh $CURRENT_USER
    fi

    # Create ZSH configuration
    cat <<EOF > ~/.zshrc
# Pure Prompt Setup
fpath+=(/usr/share/zsh/site-functions)
autoload -U promptinit; promptinit
prompt pure

# Plugins
source /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh
source /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

# Paths & Aliases
export PATH=\$PATH:\$HOME/.local/bin
alias ls='ls --color=auto'
alias grep='grep --color=auto'
alias update='${AUR_HELPER} -Syu'

# History
HISTFILE=~/.zsh_history
HISTSIZE=10000
SAVEHIST=10000
setopt HIST_IGNORE_DUPS
EOF
    success "ZSH configured with Pure prompt."
fi

# --- 8.4 Memory Management – Hybrid: 8 GB zram + 16 GB swapfile ---
echo -e "\n${YELLOW}${BOLD}MEMORY MANAGEMENT SETUP${NC}"
info "Configuring hybrid swap: 8 GB zram (high priority) + 16 GB swapfile (backup)"

# zram – 8 GB fixed
info "Setting up zram-generator (8 GB)..."
sudo pacman -S --needed --noconfirm systemd-zram-generator

cat <<EOF | sudo tee /etc/systemd/zram-generator.conf
[zram0]
zram-size = 8192
compression-algorithm = zstd
swap-priority = 100
EOF

sudo systemctl daemon-reload
sudo systemctl enable systemd-zram-setup@zram0.service || true
success "zram 8 GB enabled (zstd, priority 100)."

# swapfile 16 GB – zawsze jako backup
if [[ ! -f /swapfile ]]; then
    info "Creating 16 GB swapfile..."
    sudo truncate -s 0 /swapfile
    sudo chattr +C /swapfile 2>/dev/null || true
    sudo fallocate -l 16G /swapfile
    sudo chmod 600 /swapfile
    sudo mkswap /swapfile
    sudo swapon /swapfile
    echo "/swapfile none swap defaults,pri=-1 0 0" | sudo tee -a /etc/fstab
    success "16 GB swapfile added (priority -1)."
else
    if ! grep -q "pri=-1" /etc/fstab; then
        sudo sed -i '/swapfile/s/defaults/defaults,pri=-1/' /etc/fstab || true
        info "Updated existing swapfile to low priority (-1)."
    fi
    info "Swapfile already exists."
fi

# Swappiness – wyższy dla zram-heavy setupów
echo "vm.swappiness = 140" | sudo tee /etc/sysctl.d/99-zram-swap.conf
sudo sysctl --system
info "vm.swappiness=140 (good for zram priority)."

# Java notification
success "Java 17 and 21 installed. Manage versions within Prism Launcher."

# Enable gamemode
systemctl --user enable --now gamemoded

# --- Final Message ---
echo -e "\n${BOLD}${GREEN}======================================================================"
echo "                   AUTOZYRO SETUP COMPLETED!"
echo -e "======================================================================${NC}"
echo -e "${BOLD}Installed Apps:${NC}"
echo -e "  - ${CYAN}Steam${NC} (Gaming platform)"
echo -e "  - ${CYAN}Prism Launcher${NC} (Minecraft)"
echo -e "  - ${CYAN}Heroic Games Launcher${NC} (Epic/GOG/Amazon)"
echo -e "  - ${CYAN}ProtonUp-Qt${NC} (Manage Proton-GE)"
echo -e "  - ${CYAN}Vivaldi${NC} (Premium Browser)"
echo -e "  - ${CYAN}Discord${NC} (Community Hub)"
echo -e "  - ${CYAN}Java 17 and 21 (Temurin)${NC}"
echo -e "  - ${CYAN}Drivers${NC} (Auto-optimized for $GPU_TYPE)"
echo -e "  - ${CYAN}Konsole + Dolphin + Discover${NC} (KDE Suite)"
echo -e "  - ${CYAN}fastfetch, btop, htop${NC} (Modern monitoring)"
echo -e "  - ${CYAN}Vulkan Tools${NC} (vulkaninfo, vkcube, etc.)"
echo -e "\n${BOLD}Gaming Tweaks:${NC}"
echo -e "  - ${CYAN}GameMode${NC} enabled"
echo -e "  - ${CYAN}MangoHud${NC} installed"
echo -e "  - ${CYAN}GameScope${NC} installed (micro-compositor)"
echo -e "  - ${CYAN}Pipewire${NC} (Modern Sound System)"
echo -e "  - ${CYAN}EasyEffects & Codecs${NC} (YT & HQ Audio)"
echo -e "  - ${CYAN}Bluetooth${NC} (Service & Blueman GUI)"
echo -e "  - ${CYAN}NetworkManager${NC} (Service enabled)"
echo -e "  - ${CYAN}PS4/Controller Support${NC} (Native Kernel + udev)"
echo -e "  - ${CYAN}ZSH + Pure Prompt${NC} (Default shell set)"
echo -e "  - ${CYAN}Electron Opts${NC} (Ozone/Wayland hint enabled)"
echo -e "  - ${CYAN}Wine/Winetricks${NC} (Non-Steam gaming ready)"
echo -e "  - ${CYAN}Flatpak${NC} (Flathub ready)"
echo -e "  - ${CYAN}vm.max_map_count${NC} (Arch Default: 1048576)"
echo -e "\n${BOLD}Hardware Summary:${NC}"
sudo pacman -S --needed --noconfirm mesa-demos || true
if command -v glxinfo &> /dev/null; then
    glxinfo | grep -E "OpenGL renderer|OpenGL vendor" || true
fi
if command -v nvidia-smi &> /dev/null; then
    nvidia-smi --query-gpu=gpu_name,driver_version --format=csv,noheader || true
fi

echo -e "\n${PURPLE}${BOLD}PRO TIPS FOR THE WIN:${NC}"
echo -e "  1. Use ${CYAN}ProtonUp-Qt${NC} to download GE-Proton for Steam/Heroic."
echo -e "  2. Use ${CYAN}gamemoderun %command%${NC} in Steam Launch Options for unlisted games."
echo -e "  3. Use ${CYAN}MANGOHUD=1${NC} environment variable to show the performance overlay."
echo -e "  4. Configure your EQ and mic noise suppression in ${CYAN}EasyEffects${NC}."
echo -e "  5. For better in-game audio → set PipeWire quantum to ${CYAN}1024/48000${NC} in EasyEffects."
echo -e "  6. For NVIDIA + Wayland → check fbdev status: ${CYAN}cat /sys/module/nvidia_drm/parameters/fbdev${NC} (Y = enabled)"
echo -e "  7. GameMode is already enabled → add ${CYAN}gamemoderun %command%${NC} in Steam Launch Options."

# --- 9. Installation Verification ---
echo -e "\n${YELLOW}${BOLD}POST-INSTALLATION VERIFICATION${NC}"
echo -e "${YELLOW}Verifying installation (this may take a few seconds)...${NC}"

verify_pkg() {
    local pkg="$1"
    local cmd="$2"  # Optional command to check

    if pacman -Qs "$pkg" &>/dev/null || ( [[ -n "$cmd" ]] && command -v "$cmd" &>/dev/null ); then
        echo -e "  [${GREEN}OK${NC}] $pkg"
    else
        echo -e "  [${RED}MISSING${NC}] $pkg"
    fi
}

info "Checking essential components..."
verify_pkg "steam"
verify_pkg "gamemode" "gamemoded"
verify_pkg "mangohud"
verify_pkg "gamescope"
verify_pkg "wine-staging" "wine"
verify_pkg "flatpak"
verify_pkg "pipewire"
verify_pkg "bluez"

if [[ "$MINIMAL" == false ]]; then
    info "Checking extra applications..."
    verify_pkg "prismlauncher-bin" "prismlauncher"
    verify_pkg "heroic-games-launcher-bin" "heroic"
    verify_pkg "vivaldi"
    verify_pkg "discord"
    verify_pkg "jdk17-temurin" "java"
    verify_pkg "jdk21-temurin" "java"
    verify_pkg "zsh-pure-prompt" "zsh"
fi

info "Checking hardware drivers ($GPU_TYPE)..."
case $GPU_TYPE in
    "nvidia")
        verify_pkg "nvidia-utils"
        verify_pkg "nvidia-dkms"
        ;;
    "amd")
        verify_pkg "vulkan-radeon"
        verify_pkg "xf86-video-amdgpu"
        ;;
    "intel")
        verify_pkg "vulkan-intel"
        verify_pkg "intel-media-driver"
        ;;
esac

# --- Final System Update ---
info "Running final full system update..."
$AUR_HELPER -Syu
success "Final update completed."

info "If something doesn't work after reboot, check logs:"
info "  journalctl -b -u NetworkManager -u bluetooth -u gamemoded"

echo -e "\n${YELLOW}Enjoy your powered-up Arch Linux! (REBOOT RECOMMENDED)${NC}"
echo -e "${PURPLE}${BOLD}GL HF in your games! 🎮${NC}"
echo "======================================================================"

# --- Reboot Prompt ---
echo -e "\n${YELLOW}${BOLD}REBOOT REQUIRED${NC}"
echo -e "To apply all kernel tweaks, ZSH changes and drivers, a system restart is needed."
read -p "[AutoZyro] Reboot now? [y/N]: " reboot_choice

if [[ "$reboot_choice" =~ ^[Yy]$ ]]; then
    info "Rebooting in 3 seconds..."
    sleep 3
    sudo reboot
else
    success "Setup complete! Please remember to reboot manually later."
fi

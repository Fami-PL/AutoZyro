#!/bin/bash

# ==============================================================================
# AutoZyro - Arch Gaming Setup Script
# ==============================================================================
# Installs: Prism Launcher, Steam, Heroic, ProtonUp-Qt, Java (17, 21, 25)
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
check_internet

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
        cuda \
        cudnn \
        python-pytorch-cuda \
        python-tensorflow-cuda

    info "Configuring Kernel Modules for NVIDIA..."
    if ! grep -q "nvidia nvidia_modeset nvidia_uvm nvidia_drm" /etc/mkinitcpio.conf; then
        sudo sed -i 's/MODULES=(/MODULES=(nvidia nvidia_modeset nvidia_uvm nvidia_drm /' /etc/mkinitcpio.conf
        sudo mkinitcpio -P
    fi

    if [[ ! -f /etc/modprobe.d/nvidia.conf ]]; then
        echo "options nvidia-drm modeset=1" | sudo tee /etc/modprobe.d/nvidia.conf
    fi

    info "Applying NVIDIA No-Tearing Config..."
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

    sudo systemctl enable --now nvidia-persistenced.service
    success "NVIDIA setup completed with No-Tearing config."
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
        lib32-mesa-vdpau
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
    sudo pacman -Sy
    success "Multilib enabled."
fi

# --- 1.1 Kernel Zen Installation (Best for FPS) ---
if [[ "$CURRENT_KERNEL" != "linux-zen" ]]; then
    info "Installing Linux Zen kernel for better responsiveness..."
    sudo pacman -S --needed --noconfirm linux-zen linux-zen-headers
    if [[ -f /boot/grub/grub.cfg ]]; then
        info "Updating GRUB configuration..."
        sudo grub-mkconfig -o /boot/grub/grub.cfg
    fi
    success "Linux Zen installed (reboot recommended)."
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
    pacman-contrib power-profiles-daemon

# Enable Housekeeping & Power Mode
info "Enabling Housekeeping (paccache) and Power Management..."
sudo systemctl enable --now paccache.timer
sudo systemctl enable --now power-profiles-daemon

# --- 4. Install Yay (AUR Helper) ---
if command -v yay &> /dev/null; then
    success "Yay is already installed."
else
    info "Installing yay (AUR helper)..."
    git clone https://aur.archlinux.org/yay-bin.git /tmp/yay-bin
    cd /tmp/yay-bin && makepkg -si --noconfirm
    cd - && rm -rf /tmp/yay-bin
    success "Yay installed."
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
    gamescope \
    vulkan-icd-loader \
    lib32-vulkan-icd-loader

# --- 7. Install AUR Packages (Prism, Heroic, ProtonUp, Vivaldi, Controllers, Discord) ---
info "Installing AUR packages: Prism Launcher, Heroic, ProtonUp-Qt, Vivaldi, Discord, Controller Rules..."
yay -S --noconfirm \
    prismlauncher-bin \
    heroic-games-launcher-bin \
    protonup-qt-bin \
    vivaldi \
    vivaldi-ffmpeg-codecs \
    discord \
    game-devices-udev \
    ds4drv

# --- 7. Install Java Versions (Adoptium/Temurin) ---
info "Installing Adoptium Java 17, 21, and 25..."
JAVA_VERSIONS=("jdk17-temurin" "jdk21-temurin" "jdk25-temurin")

for version in "${JAVA_VERSIONS[@]}"; do
    info "Attempting to install $version..."
    if yay -Si "$version" &> /dev/null; then
        yay -S --noconfirm "$version"
        success "$version installed."
    else
        warn "$version not found in AUR. Skipping..."
    fi
done

# --- 8. Configuration & Optimizations ---
info "Configuring system for peak performance..."

# Optimizing for high memory map count (needed for Steam/Proton)
if [[ -f /etc/sysctl.d/99-gaming.conf ]]; then
    info "Gaming optimizations already present."
else
    info "Applying kernel optimizations (vm.max_map_count)..."
    echo "vm.max_map_count=2147483642" | sudo tee /etc/sysctl.d/99-gaming.conf
    sudo sysctl --system
    success "Kernel optimized for gaming."
fi

# --- 8.1 Memory Management (zRAM + Swapfile) ---
info "Configuring Memory Management (zRAM 8GB + Swapfile 16GB)..."
sudo pacman -S --needed --noconfirm zram-generator

# Setup zRAM
cat <<EOF | sudo tee /etc/systemd/zram-generator.conf
[zram0]
zram-size = 8192
compression-algorithm = zstd
EOF
sudo systemctl daemon-reload
sudo systemctl start /dev/zram0

# Setup Swapfile (16GB)
if [[ ! -f /swapfile ]]; then
    info "Creating 16GB swapfile..."
    sudo truncate -s 0 /swapfile
    sudo chattr +C /swapfile
    sudo fallocate -l 16G /swapfile
    sudo chmod 600 /swapfile
    sudo mkswap /swapfile
    sudo swapon /swapfile
    echo "/swapfile none swap defaults 0 0" | sudo tee -a /etc/fstab
    success "Swapfile created."
else
    info "Swapfile already exists."
fi

# Set default Java to 21 for now (widely supported)
if command -v archlinux-java &> /dev/null; then
    if archlinux-java status | grep -q "java-21-temurin"; then
        sudo archlinux-java set java-21-temurin
        success "Default Java set to version 21 (Temurin)."
    elif archlinux-java status | grep -q "java-17-temurin"; then
        sudo archlinux-java set java-17-temurin
        success "Default Java set to version 17 (Temurin)."
    fi
fi

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
echo -e "  - ${CYAN}Java 17, 21, 25 (Temurin)${NC}"
echo -e "  - ${CYAN}Drivers${NC} (Auto-optimized for $GPU_TYPE)"
echo -e "\n${BOLD}Gaming Tweaks:${NC}"
echo -e "  - ${CYAN}GameMode${NC} enabled"
echo -e "  - ${CYAN}MangoHud${NC} installed"
echo -e "  - ${CYAN}GameScope${NC} installed (micro-compositor)"
echo -e "  - ${CYAN}Pipewire${NC} (Modern Sound System)"
echo -e "  - ${CYAN}EasyEffects & Codecs${NC} (YT & HQ Audio)"
echo -e "  - ${CYAN}Bluetooth${NC} (Service & Blueman GUI)"
echo -e "  - ${CYAN}NetworkManager${NC} (Service enabled)"
echo -e "  - ${CYAN}PS4/Controller Support${NC} (udev rules & ds4drv)"
echo -e "  - ${CYAN}vm.max_map_count${NC} optimized to 2147483642"
echo -e "\n${YELLOW}Enjoy your powered-up Arch Linux!${NC}"
echo "======================================================================"

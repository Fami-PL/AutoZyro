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

# --- Check for Root ---
if [[ $EUID -eq 0 ]]; then
   error "Do not run AutoZyro as root! It will ask for sudo when needed."
fi

print_banner

# --- 0. Hardware Detection / Choice ---
echo -e "${YELLOW}${BOLD}NVIDIA GPU DETECTED?${NC}"
read -p "[AutoZyro] Would you like to install & configure NVIDIA drivers for AI + Games? (y/N): " nvidia_choice

install_nvidia() {
    info "Installing NVIDIA Drivers (Pro, AI & Gaming optimized)..."
    sudo pacman -S --needed --noconfirm \
        nvidia \
        nvidia-utils \
        lib32-nvidia-utils \
        nvidia-settings \
        cuda \
        cudnn \
        python-pytorch-cuda \
        python-tensorflow-cuda

    info "Configuring Kernel Modules for NVIDIA..."
    # Add to modules for early loading
    if ! grep -q "nvidia nvidia_modeset nvidia_uvm nvidia_drm" /etc/mkinitcpio.conf; then
        sudo sed -i 's/MODULES=(/MODULES=(nvidia nvidia_modeset nvidia_uvm nvidia_drm /' /etc/mkinitcpio.conf
        sudo mkinitcpio -P
    fi

    info "Setting up NVIDIA DRM Modesetting..."
    if [[ ! -f /etc/modprobe.d/nvidia.conf ]]; then
        echo "options nvidia-drm modeset=1" | sudo tee /etc/modprobe.d/nvidia.conf
    fi

    info "Enabling NVIDIA Services..."
    sudo systemctl enable --now nvidia-persistenced.service
    success "NVIDIA setup completed for AI and Gaming."
}

if [[ "$nvidia_choice" =~ ^[Yy]$ ]]; then
    USE_NVIDIA=true
else
    USE_NVIDIA=false
fi

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

# --- 2. Update System ---
info "Updating system repositories..."
sudo pacman -Syu --noconfirm

# --- 2.5 NVIDIA installation (if selected) ---
if [[ "$USE_NVIDIA" == true ]]; then
    install_nvidia
fi

# --- 3. Install Core Dependencies ---
info "Installing base-devel and git..."
sudo pacman -S --needed --noconfirm base-devel git

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

# --- 7. Install AUR Packages (Prism, Heroic, ProtonUp, Vivaldi, Controllers) ---
info "Installing AUR packages: Prism Launcher, Heroic, ProtonUp-Qt, Vivaldi, Controller Rules..."
yay -S --noconfirm \
    prismlauncher-bin \
    heroic-games-launcher-bin \
    protonup-qt-bin \
    vivaldi \
    vivaldi-ffmpeg-codecs \
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
echo -e "  - ${CYAN}Java 17, 21, 25 (Temurin)${NC}"
if [[ "$USE_NVIDIA" == true ]]; then
    echo -e "  - ${CYAN}NVIDIA Drivers + CUDA + cuDNN${NC} (AI & Gaming)"
fi
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

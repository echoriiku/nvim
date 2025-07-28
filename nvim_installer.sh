#!/bin/bash

# Neovim AppImage Installer/Updater
# Downloads, extracts, and installs the latest Neovim stable or nightly build

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_question() {
    echo -e "${BLUE}[QUESTION]${NC} $1"
}

# Check if running as root
if [[ $EUID -eq 0 ]]; then
    print_error "Don't run this script as root. It will use sudo when needed."
    exit 1
fi

# Check if sudo is available
if ! command -v sudo &> /dev/null; then
    print_error "sudo is required but not installed."
    exit 1
fi

# Check if wget or curl is available
if command -v wget &> /dev/null; then
    DOWNLOADER="wget -O"
    HEADER_FETCHER="wget -S --spider"
elif command -v curl &> /dev/null; then
    DOWNLOADER="curl -L -o"
    HEADER_FETCHER="curl -sI"
else
    print_error "Either wget or curl is required to download the AppImage."
    exit 1
fi

# Function to get remote file modification time
get_remote_date() {
    local url="$1"
    if command -v wget &> /dev/null; then
        wget -S --spider "$url" 2>&1 | grep -i "last-modified" | sed 's/.*Last-Modified: //' | head -1
    else
        curl -sI "$url" | grep -i "last-modified" | sed 's/.*Last-Modified: //' | tr -d '\r'
    fi
}

# Function to convert date to timestamp
date_to_timestamp() {
    if command -v gdate &> /dev/null; then
        # macOS with GNU coreutils
        gdate -d "$1" +%s 2>/dev/null || echo "0"
    else
        # Linux
        date -d "$1" +%s 2>/dev/null || echo "0"
    fi
}

# Function to get current installed version info
get_installed_version() {
    if command -v nvim &> /dev/null && [[ -L "/usr/bin/nvim" ]]; then
        local version_output
        version_output=$(nvim --version 2>/dev/null | head -1)
        echo "$version_output"
        return 0
    fi
    return 1
}

# Function to check if update is needed
check_update_needed() {
    local remote_url="$1"
    local version_file="$2"
    
    # Get remote file date
    local remote_date
    remote_date=$(get_remote_date "$remote_url")
    
    if [[ -z "$remote_date" ]]; then
        print_warning "Could not fetch remote file date. Will proceed with installation."
        return 0
    fi
    
    # If version file doesn't exist, update is needed
    if [[ ! -f "$version_file" ]]; then
        return 0
    fi
    
    # Get local file date
    local local_date
    local_date=$(cat "$version_file" 2>/dev/null || echo "")
    
    if [[ -z "$local_date" ]]; then
        return 0
    fi
    
    # Convert dates to timestamps for comparison
    local remote_ts local_ts
    remote_ts=$(date_to_timestamp "$remote_date")
    local_ts=$(date_to_timestamp "$local_date")
    
    if [[ "$remote_ts" -gt "$local_ts" ]]; then
        return 0  # Update needed
    else
        return 1  # No update needed
    fi
}

print_status "Neovim AppImage Installer/Updater"
echo

# Ask user which version they want
print_question "Which version would you like to install?"
echo "1) Latest Stable Release"
echo "2) Latest Nightly Build"
echo
read -p "Enter your choice (1 or 2): " choice

case $choice in
    1)
        VERSION_TYPE="stable"
        NVIM_URL="https://github.com/neovim/neovim/releases/latest/download/nvim-linux-x86_64.appimage"
        VERSION_FILE="/opt/nvim/.version_stable"
        print_status "Selected: Latest Stable Release"
        ;;
    2)
        VERSION_TYPE="nightly"
        NVIM_URL="https://github.com/neovim/neovim/releases/download/nightly/nvim-linux-x86_64.appimage"
        VERSION_FILE="/opt/nvim/.version_nightly"
        print_status "Selected: Latest Nightly Build"
        ;;
    *)
        print_error "Invalid choice. Please run the script again and choose 1 or 2."
        exit 1
        ;;
esac

echo

# Define paths
TEMP_DIR="/tmp/nvim-install"
APPIMAGE_PATH="$TEMP_DIR/nvim-linux-x86_64.appimage"
INSTALL_DIR="/opt/nvim"

# Check current installation
current_version=$(get_installed_version)
if [[ $? -eq 0 ]]; then
    print_status "Current installation found:"
    echo "  $current_version"
    echo
fi

# Check if update is needed
print_status "Checking for updates..."
if check_update_needed "$NVIM_URL" "$VERSION_FILE"; then
    print_status "Update available or no installation found. Proceeding with installation..."
else
    print_status "You already have the latest $VERSION_TYPE version installed!"
    read -p "Do you want to reinstall anyway? (y/N): " reinstall
    if [[ ! "$reinstall" =~ ^[Yy]$ ]]; then
        print_status "Installation cancelled."
        exit 0
    fi
fi

echo

# Create temporary directory
print_status "Creating temporary directory..."
mkdir -p "$TEMP_DIR"
cd "$TEMP_DIR"

# Download the AppImage
print_status "Downloading Neovim $VERSION_TYPE AppImage..."
if ! $DOWNLOADER "$APPIMAGE_PATH" "$NVIM_URL"; then
    print_error "Failed to download Neovim AppImage"
    exit 1
fi

# Make it executable
print_status "Making AppImage executable..."
chmod +x "$APPIMAGE_PATH"

# Extract the AppImage
print_status "Extracting AppImage..."
"$APPIMAGE_PATH" --appimage-extract

# Check if extraction was successful
if [[ ! -d "squashfs-root" ]]; then
    print_error "Failed to extract AppImage"
    exit 1
fi

# Test the extracted version
print_status "Testing extracted Neovim..."
./squashfs-root/AppRun --version

# Remove existing installation if it exists
if [[ -d "$INSTALL_DIR" ]]; then
    print_warning "Removing existing Neovim installation at $INSTALL_DIR"
    sudo rm -rf "$INSTALL_DIR"
fi

# Remove existing symlink if it exists
if [[ -L "/usr/bin/nvim" ]]; then
    print_warning "Removing existing nvim symlink"
    sudo rm -f "/usr/bin/nvim"
fi

# Move extracted files to system location
print_status "Installing Neovim to $INSTALL_DIR..."
sudo mv squashfs-root "$INSTALL_DIR"

# Create symlink
print_status "Creating symlink in /usr/bin/nvim..."
sudo ln -s "$INSTALL_DIR/AppRun" /usr/bin/nvim

# Save version info
print_status "Saving version information..."
sudo mkdir -p "$(dirname "$VERSION_FILE")"
remote_date=$(get_remote_date "$NVIM_URL")
if [[ -n "$remote_date" ]]; then
    echo "$remote_date" | sudo tee "$VERSION_FILE" > /dev/null
fi

# Clean up temporary files
print_status "Cleaning up temporary files..."
cd /
rm -rf "$TEMP_DIR"

# Verify installation
print_status "Verifying installation..."
if command -v nvim &> /dev/null; then
    print_status "Installation successful! Neovim version:"
    nvim --version | head -1
    echo
    print_status "Installation type: $VERSION_TYPE"
else
    print_error "Installation failed - nvim command not found"
    exit 1
fi

print_status "Neovim has been successfully installed!"
print_status "You can now run 'nvim' from anywhere in your system."
print_status "Run this script again anytime to check for updates."
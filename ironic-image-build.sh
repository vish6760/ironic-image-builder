#!/bin/bash

set -eu  # Exit on error
set -o pipefail  # Fail on first command in pipeline that fails

LOG_FILE="$PWD/image_build.log"
TIMESTAMP=$(date '+%Y%m%d_%H%M%S')
BACKUP_LOG_FILE="${LOG_FILE}_${TIMESTAMP}.bak"

# Rotate log file if it exists
if [[ -f "$LOG_FILE" ]]; then
    echo "Backing up existing log file to: $BACKUP_LOG_FILE"
    mv "$LOG_FILE" "$BACKUP_LOG_FILE"
fi

# Function to log messages
log() {
    local MSG="$1"
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $MSG" | tee -a "$LOG_FILE"
}

# Function to handle errors
error_exit() {
    local MSG="$1"
    log "ERROR: $MSG"
    exit 1
}

log "========================================"
log "Starting Image Build Process"
log "========================================"

# Required packages
REQUIRED_PKGS=("python3-virtualenv" "qemu-utils" "kpartx" "qemu" "squashfs-tools" "curl" "uuid-runtime")

# Function to check if packages are installed
check_packages() {
    MISSING_PKGS=()
    for pkg in "${REQUIRED_PKGS[@]}"; do
        if ! dpkg -l | grep -q "^ii  $pkg "; then
            MISSING_PKGS+=("$pkg")
        fi
    done

    if [ ${#MISSING_PKGS[@]} -gt 0 ]; then
        log "Missing packages: ${MISSING_PKGS[*]}"
        read -rp "Install missing packages? (y/n): " INSTALL_CHOICE
        if [[ "$INSTALL_CHOICE" =~ ^[Yy]$ ]]; then
            sudo apt update && sudo apt install -y "${MISSING_PKGS[@]}" || error_exit "Failed to install packages"
            log "Required packages installed successfully"
        else
            error_exit "Missing required packages. Exiting..."
        fi
    else
        log "All required packages are installed."
    fi
}

# Run package check
check_packages

# Get user inputs
read -rp "Enter the distro release from the following options: centos9, bionic, focal, jammy (default: focal): " DIS
DIS=${DIS:-focal}

read -rp "Enter Virtual Environment Directory (default: $(pwd)/image-builder): " VENV_DIR
VENV_DIR=${VENV_DIR:-$(pwd)/image-builder}

read -rp "Enter Output Directory (default: $(pwd)/ironic-images): " OUTPUT_DIR
OUTPUT_DIR=${OUTPUT_DIR:-$(pwd)/ironic-images}

#https://github.com/openstack/diskimage-builder
read -rp "Enter Diskimage-Builder Version (default: 3.31.0): " DIB_VERSION
DIB_VERSION=${DIB_VERSION:-3.31.0}

#https://github.com/openstack/ironic-python-agent-builder
read -rp "Enter Ironic-Python-Agent-Builder Version (default: 5.0.1): " IPA_BUILDER_VERSION
IPA_BUILDER_VERSION=${IPA_BUILDER_VERSION:-5.0.1}

# Ensure output directory exists
mkdir -p "$OUTPUT_DIR" || error_exit "Failed to create output directory: $OUTPUT_DIR"

# Install required packages and setup virtual environment
log "Setting up virtual environment in $VENV_DIR"
[ -d "$VENV_DIR" ] && rm -rf "$VENV_DIR"
virtualenv -p python3 "$VENV_DIR" || error_exit "Failed to create virtual environment"

# Install required packages in the venv
log "Installing diskimage-builder ($DIB_VERSION) and ironic-python-agent-builder ($IPA_BUILDER_VERSION)"
"$VENV_DIR/bin/pip" install --upgrade pip setuptools wheel --isolated
"$VENV_DIR/bin/pip" install "diskimage-builder==$DIB_VERSION" "ironic-python-agent-builder==$IPA_BUILDER_VERSION" --isolated || error_exit "Package installation failed"

echo  # New line for clarity
# Activate virtual environment
source "$VENV_DIR/bin/activate"

# Set Environment Variables
CUSTOM_ELEMENTS="$(pwd)/dib-elements"
export ELEMENTS_PATH="${ELEMENTS_PATH:-$CUSTOM_ELEMENTS}"

echo  # New line for clarity

#https://github.com/openstack/ironic-python-agent
read -rp "Enter Ironic Python Agent Branch (default: unmaintained/victoria): " DIB_REPOREF_ironic_python_agent
DIB_REPOREF_ironic_python_agent=${DIB_REPOREF_ironic_python_agent:-unmaintained/victoria}

export DIB_REPOREF_ironic_python_agent
#https://github.com/openstack/requirements
export DIB_REPOREF_requirements="$DIB_REPOREF_ironic_python_agent"
#https://github.com/openstack/ironic-lib
export DIB_REPOREF_ironic_lib="$DIB_REPOREF_ironic_python_agent"

# Specify SHA-512 hash
export ENCRYPTED_PASSWORD="UPDATE-ME"

# Set Disk Image Builder variables
case "$DIS" in
  focal) export DISTRO_NAME=ubuntu; export DIB_RELEASE=focal ;;
  bionic) export DISTRO_NAME=ubuntu; export DIB_RELEASE=bionic ;;
  jammy) export DISTRO_NAME=ubuntu; export DIB_RELEASE=jammy ;;
  centos9) export DISTRO_NAME=centos; export DIB_RELEASE=9-stream ;;
  *) error_exit "Invalid distribution release: $DIS" ;;
esac

IMG_NAME="${DISTRO_NAME}-${DIB_RELEASE}-metal-simple"

# Build the Image
log "Building ${DISTRO_NAME}-${DIB_RELEASE} image at ${OUTPUT_DIR}/${IMG_NAME}"

disk-image-create $DISTRO_NAME \
  $(test "$DISTRO_NAME" = "centos" && echo epel) \
  $(test "$DISTRO_NAME" = "ubuntu" && echo ubuntu-common) \
  block-device-gpt \
  disable-nouveau \
  cloud-init-datasources \
  vm \
  dhcp-all-interfaces \
  dynamic-login \
  baremetal \
  grub2 \
  my-custom-element -o "${OUTPUT_DIR}/${IMG_NAME}" 2>&1 | tee -a "$LOG_FILE"

# Check if image creation succeeded
if [ $? -ne 0 ]; then
    error_exit "Image build failed. Check logs at $LOG_FILE"
fi

# Cleanup and deactivate the virtual environment
log "Deactivating the virtual environment"
deactivate

# Define the source and destination paths for kernel and initramfs files
KERNEL_FILE="${OUTPUT_DIR}/${IMG_NAME}.vmlinuz"
INITRD_FILE="${OUTPUT_DIR}/${IMG_NAME}.initrd"

# Move kernel and initramfs
log "Renaming kernel and initramfs"
sudo mv "$KERNEL_FILE" "${OUTPUT_DIR}/${IMG_NAME}.kernel" || error_exit "Failed to move kernel file"
sudo mv "$INITRD_FILE" "${OUTPUT_DIR}/${IMG_NAME}.initramfs" || error_exit "Failed to move initramfs file"

log "Build Completed Successfully"
log "Kernel and initramfs located at: ${OUTPUT_DIR}"

echo -e "\nBuild log saved at: $LOG_FILE"


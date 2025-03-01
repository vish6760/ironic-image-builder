# Image Builder for Ironic Python Agent

📌 Description
This repository contains scripts and custom elements for building an **Ironic Python Agent (IPA)** image using **diskimage-builder** and **ironic-python-agent-builder**. It automates the creation of images with necessary configurations, ensuring a streamlined deployment process for OpenStack Ironic environments.

## 📁 Directory Structure

```
├── README.md                          # Documentation for the repository
├── ironic-image-build.sh              # Script to build the image using DIB
└── dib-elements
    └── my-custom-element/             # Example of a custom element                      
        ├── element-deps               # Dependencies for the element
        ├── environment.d              # Environment variables
        │   └── 01-defaults.bash       # Default settings and variables
        ├── extra-data.d               # Extra files needed during the build
        │   └── 10-custom-base-image   # Defines custom base image sources
        ├── finalise.d                 # Final configuration before image completion
        │   └── 99-custom-grub         # Custom GRUB configuration
        ├── install.d                  # Package installation scripts
        │   └── 50-install-packages    # Installs required packages
        ├── package-installs.yaml      # Package list for installation
        ├── pkg-map                    # Package mapping for different distros
        └── post-install.d             # Post-installation scripts
            ├── 02-network-manager     # Configures Network Manager
            ├── 03-fix-cloud-init      # Fixes cloud-init issues
            ├── 10-add-custom-scripts  # Adds additional custom scripts
            ├── 90-clean-tasks         # Performs cleanup tasks
            └── 99-blacklist-modules   # Blacklists unwanted kernel modules
```

## 🚀 Getting Started

🚀 Prerequisites

Ensure your system meets the following requirements:

Operating System:
Ubuntu 20.04 / 22.04
CentOS 9 Stream
Required Packages:
Before running the script, install the necessary dependencies:

### **This IPA image build process has been tested on an Ubuntu 20.04 virtual machine, but you are welcome to test it on other distributions as well. **

### 1️⃣ **Clone the Repository**
```bash
git clone https://github.com/your-username/image-builder.git
cd image-builder
```

### 2️⃣ **Install Dependencies**
Ensure you have the following installed on your system: Most of them cover with `ironic-image-build.sh`

On **Ubuntu/Debian**:
```bash
sudo apt update
sudo apt install -y python3-virtualenv qemu-utils kpartx qemu squashfs-tools curl uuid-runtime
```

On **CentOS/RHEL**:
```bash
sudo dnf install -y python3-virtualenv qemu-img kpartx qemu squashfs-tools curl util-linux
```

### 3️⃣ **Build the Image**
Run the `ironic-image-build.sh` script to create the image:
```bash
./ironic-image-build.sh
```

This script will use the `my-custom-element` element and apply all custom configurations.

### 4️⃣ **Customize the Image**
Modify the files inside the `elements/my-custom-element/` directory to:
- Add/remove packages (`package-installs.yaml`)
- Change cloud-init behavior (`post-install.d/03-fix-cloud-init`)
- Modify GRUB settings (`finalise.d/99-custom-grub`)

### 5️⃣ **Deploy the Image**
Once the image is built, you can upload it to OpenStack:
```bash
openstack image create "Custom my-custom-element Image" \
  --disk-format qcow2 --container-format bare \
  --file output-image.qcow2
```

## 🛠️ Custom DIB Element Details

| Directory            | Purpose |
|----------------------|---------|
| `environment.d/`    | Sets environment variables used in the build |
| `extra-data.d/`     | Provides additional files needed during the build |
| `finalise.d/`       | Executes final tasks before finalizing the image |
| `install.d/`        | Installs necessary packages |
| `post-install.d/`   | Runs scripts after the image is built |
| `package-installs.yaml` | Defines required packages for the image |
| `pkg-map`           | Maps packages across different distributions |



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
        │   ├── 99-custom-grub         # Custom GRUB configuration
        │   └── 99-enable-network      # Ensures networking is enabled
        ├── install.d                  # Package installation scripts
        │   └── 50-install-packages    # Installs required packages
        ├── package-installs.yaml      # Package list for installation
        ├── pkg-map                    # Package mapping for different distros
        └── post-install.d             # Post-installation scripts
            ├── 03-fix-cloud-init      # Fixes cloud-init issues
            ├── 10-add-custom-scripts  # Adds additional custom scripts
            ├── 90-clean-tasks         # Performs cleanup tasks
            ├── 99-apply-networking    # Applies networking configurations 
            └── 99-blacklist-modules   # Blacklists unwanted kernel modules
```

## 🚀 Getting Started

**Prerequisites**

Ensure your system meets the following requirements:

**Operating System:**  
Ubuntu 20.04 / 22.04  
CentOS 9 Stream  

**Required Packages:**  
Before running the script, install the necessary dependencies:  

### **This IPA image build process has been tested on an Ubuntu 20.04 virtual machine, but you are welcome to test it on other distributions.**

### 1️⃣ **Clone the Repository**
```bash
git clone https://github.com/vish6760/ironic-image-builder.git /opt/ironic-image-builder
cd ironic-image-builder
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

## 🛠️ Use a Local PyPI Mirror for Python Packages

Instead of fetching packages from `pypi.org`, use a local **PyPI mirror**.

1. Set up a PyPI mirror using devpi or bandersnatch or use existing PyPI mirror.
2. Configure `DIB_PYTHON_PACKAGE_MIRROR`:
```bash
export DIB_PYTHON_PACKAGE_MIRROR="http://your-internal-mirror/pypi/simple"
```
3. Alternatively, modify the `pip.conf` file:
```bash
[global]
index-url = http://your-internal-mirror/pypi/simple
trusted-host = your-internal-mirror
```

## 🛠️ Disable Online Image Fetching (Use Local Base Image)

DIB normally fetches cloud images. To avoid this:

1. Download the cloud image manually and store it internally:
```bash
mkdir -p /opt/local-images/
wget -O /opt/local-images/ubuntu.qcow2 https://cloud-images.ubuntu.com/releases/22.04/release/ubuntu-22.04-server-cloudimg-amd64.img
```

2. Set `DIB_LOCAL_IMAGE`:
```bash
export DIB_LOCAL_IMAGE="/opt/local-images/ubuntu.qcow2"
```

Alternatively, we can configure the build process to reference a pre-existed image within the environment by specifying its URL in the configuration. This can be achieved using the settings defined in `dib-elements/my-custom-element/extra-data.d/10-custom-base-image`.

## Resources and Documentation

(https://github.com/openstack/diskimage-builder)  
(https://github.com/openstack/ironic-python-agent-builder)  
(https://github.com/openstack/ironic-python-agent)  
(https://github.com/openstack/requirements)  
(https://github.com/openstack/ironic-lib)  
(https://docs.openstack.org/ironic-python-agent-builder/latest/admin/dib.html)  
(https://docs.openstack.org/ironic-python-agent/latest/admin/troubleshooting.html)  


# Zishu Packages

Official package repository for **Zishu Terminal**.

## What is this?

This repository contains:
- **Build scripts** for ARM64 (aarch64) binaries
- **GitHub Actions workflows** that build the binaries
- **`index.json`** — package metadata

## Packages

| Package | Version | Status | Description |
|---------|---------|--------|-------------|
| busybox | 1.36.1 | 🔧 Building | Multi-call binary (300+ commands) |
| zfetch  | 1.0.0  | ✅ Ready | System info tool |

## How builds work

1. Push to `main` or trigger **Actions** → **Run workflow**
2. GitHub Actions runs on **Ubuntu** (Linux)
3. Cross-compiles for **ARM64** using `gcc-aarch64-linux-gnu`
4. Creates a tarball with `MANIFEST` + `files/`
5. Uploads to **GitHub Releases**

## Package format

Every package is a `.tar.gz` or `.zip` containing:

```

package.tar.gz
├── MANIFEST
└── files/
└── bin/
└── <binary>

```

**MANIFEST** (key=value):

```

name=busybox
version=1.36.1
description=...
author=zishu
type=binary
arch=arm64-v8a
entrypoint=busybox

```

## Install via Zishu Terminal

```bash
curl -O https://github.com/zishutron/zishu-packages/releases/download/<tag>/<package>.tar.gz
tar xzf <package>.tar.gz -C $PREFIX/
chmod +x $PREFIX/bin/<binary>
```

License

Build scripts: MIT
Binaries: as per upstream (GPL for busybox)


## File 3 — `scripts/build-busybox.sh`

#!/bin/bash
# Zishu Packages - Build script for busybox ARM64
#
# This script is called from GitHub Actions.
# Can also be run locally on a Linux machine with cross-compiler.

set -e

BUSYBOX_VERSION="1.36.1"
CROSS_COMPILE="aarch64-linux-gnu-"
ARCH="arm64"

echo "=== Building busybox ${BUSYBOX_VERSION} for ${ARCH} ==="

# Download
if [ ! -f "busybox-${BUSYBOX_VERSION}.tar.bz2" ]; then
    echo "Downloading busybox source..."
    wget "https://busybox.net/downloads/busybox-${BUSYBOX_VERSION}.tar.bz2"
fi

# Extract
if [ ! -d "busybox-src" ]; then
    echo "Extracting..."
    tar xjf "busybox-${BUSYBOX_VERSION}.tar.bz2"
    mv "busybox-${BUSYBOX_VERSION}" busybox-src
fi

cd busybox-src

# Configure
echo "Configuring..."
make defconfig
sed -i 's/^# CONFIG_STATIC is not set/CONFIG_STATIC=y/' .config

# Build
echo "Building..."
make CROSS_COMPILE="${CROSS_COMPILE}" ARCH="${ARCH}" -j$(nproc)

# Verify
echo "=== Result ==="
file busybox
ls -la busybox

cd ..

# Package
echo "Packaging..."
mkdir -p output/files/bin
cp busybox-src/busybox output/files/bin/busybox-arm64
chmod +x output/files/bin/busybox-arm64

cat > output/MANIFEST << EOF
name=busybox
version=${BUSYBOX_VERSION}
description=Busybox multi-call binary (Zishu build)
author=zishu
type=binary
arch=arm64-v8a
entrypoint=busybox
EOF

cd output
tar czf "../busybox-${BUSYBOX_VERSION}-arm64.tar.gz" MANIFEST files/
cd ..

sha256sum "busybox-${BUSYBOX_VERSION}-arm64.tar.gz" > "busybox-${BUSYBOX_VERSION}-arm64.tar.gz.sha256"

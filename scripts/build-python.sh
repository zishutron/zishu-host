#!/bin/bash
# Zishu Packages - Build script for Python ARM64
#
# This script is called from GitHub Actions.
# Can also be run locally on a Linux machine with cross-compiler.

set -e

PYTHON_VERSION="3.11.9"
CROSS_COMPILE="aarch64-linux-gnu-"
ARCH="arm64"

echo "=== Building Python ${PYTHON_VERSION} for ${ARCH} ==="

# Download
if [ ! -f "Python-${PYTHON_VERSION}.tgz" ]; then
    echo "Downloading Python source..."
    wget "https://www.python.org/ftp/python/${PYTHON_VERSION}/Python-${PYTHON_VERSION}.tgz"
fi

# Extract
if [ ! -d "python-src" ]; then
    echo "Extracting..."
    tar xzf "Python-${PYTHON_VERSION}.tgz"
    mv "Python-${PYTHON_VERSION}" python-src
fi

cd python-src

# Configure
echo "Configuring..."
./configure \
    --host=aarch64-linux-gnu \
    --build=x86_64-linux-gnu \
    --prefix=/usr \
    --enable-shared \
    --disable-ipv6 \
    --without-ensurepip \
    --with-system-ffi

# Build
echo "Building..."
make -j$(nproc)

# Install to staging
echo "Installing to staging..."
make install DESTDIR=$PWD/staging

# Verify
echo "=== Result ==="
file staging/usr/bin/python3.11
ls -la staging/usr/bin/python3.11

cd ..

# Package
echo "Packaging..."
mkdir -p output/files/bin
mkdir -p output/files/lib

cp python-src/staging/usr/bin/python3.11 output/files/bin/python3.11
cd output/files/bin
ln -sf python3.11 python3
ln -sf python3.11 python
cd ../../..

cp -P python-src/staging/usr/lib/libpython3.11* output/files/lib/ 2>/dev/null || true
cp -r python-src/staging/usr/lib/python3.11 output/files/lib/

cat > output/MANIFEST << EOF
name=python
version=${PYTHON_VERSION}
description=Python ${PYTHON_VERSION} for Zishu Terminal
author=zishu
type=binary
arch=arm64-v8a
entrypoint=python3
EOF

cd output
tar czf "../python-${PYTHON_VERSION}-arm64.tar.gz" MANIFEST files/
cd ..

sha256sum "python-${PYTHON_VERSION}-arm64.tar.gz" > "python-${PYTHON_VERSION}-arm64.tar.gz.sha256"

echo "=== Done ==="
ls -la "python-${PYTHON_VERSION}-arm64.tar.gz"*

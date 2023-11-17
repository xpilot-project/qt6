#!/bin/bash

if [ $# -lt 1 ]; then
  echo "Usage: $0 <qt-version>"
  exit 1
fi

# Install dependencies
echo "Installing dependencies..."
sudo apt-get update && sudo apt-get install -y \
  libfontconfig1-dev libfreetype6-dev libx11-dev libx11-xcb-dev libxext-dev \
  libxfixes-dev libxi-dev libxrender-dev libxcb1-dev libxcb-cursor-dev libxcb-glx0-dev libxcb-keysyms1-dev \
  libxcb-image0-dev libxcb-shm0-dev libxcb-icccm4-dev libxcb-sync-dev libxcb-xfixes0-dev libxcb-shape0-dev \
  libxcb-randr0-dev libxcb-render-util0-dev libxcb-util-dev libxcb-xinerama0-dev libxcb-xkb-dev \
  libxkbcommon-dev libxkbcommon-x11-dev xorg-dev \
  libglu1-mesa-dev freeglut3-dev mesa-common-dev libglfw3-dev libgles2-mesa-dev \
  libpulse-dev
  
# Clone the Qt repository
echo "Cloning the Qt repository..."
git clone https://github.com/qt/qt5.git qt6 -b $1

# Navigate to the Qt directory
cd qt6

# Initialize the Qt repository with the required modules
echo "Initializing the Qt repository with required modules..."
perl init-repository --module-subset=qtbase,qtdeclarative,qtimageformats,qtmultimedia,qtsvg,qtshadertools

# Create and enter the build directory
echo "Creating and entering the build directory..."
mkdir -p build && cd build

# Clone additional dependencies
echo "Cloning additional dependencies..."
git clone https://github.com/xpilot-project/dependencies.git

# Set OPENSSL_LIBS environment variable
echo "Setting OPENSSL_LIBS environment variable..."
OPENSSL_ROOT_DIR="$(pwd)/dependencies/platform/linux/openssl"

# Configure Qt build
echo "Configuring Qt build..."
../configure -prefix ./install -release -static -confirm-license \
  -qt-pcre -qt-zlib -qt-libpng -qt-libjpeg -openssl-linked -no-pch -nomake tests -nomake examples \
  -skip qt3d,qtactiveqt,qtandroidextras,qtcanvas3d,qtcharts,qtconnectivity \
  -skip qtdatavis3d,qtdoc,qtgamepad,qtgraphicaleffects,qtlocation,qtmacextras \
  -skip qtnetworkauth,qtpurchasing,qtremoteobjects,qtscript,qtscxml,qtsensors \
  -skip qtserialbus,qtspeech,qttools,qttranslations,qtvirtualkeyboard,qtwayland \
  -skip qtwebchannel,qtwebview,qtwinextras,qtx11extras,qtxmlpatterns,qtwebengine,qtimageformats \
  -- -DOPENSSL_ROOT_DIR="$OPENSSL_ROOT_DIR" -DOPENSSL_USE_STATIC_LIBS=TRUE

# Build Qt
echo "Building Qt..."
cmake --build . --parallel

# Install Qt
echo "Installing Qt..."
cmake --install .

# Add files to 7z archive
cd install && 7z a linux *
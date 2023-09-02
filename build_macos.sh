#!/bin/bash

if [ $# -lt 1 ]; then
  echo "Usage: $0 <qt-version>"
  exit 1
fi

export PLATFORM="./dependencies/platform/macos"

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
export OPENSSL_LIBS="$PLATFORM/openssl/libssl.a $PLATFORM/openssl/libcrypto.a"
echo $OPENSSL_LIBS

OPENSSL_ROOT_DIR="$(pwd)/dependencies/platform/macos/openssl"
echo $OPENSSL_ROOT_DIR

# Configure Qt build
echo "Configuring Qt build..."
../configure -prefix ./install -debug-and-release -static -confirm-license \
  -feature-relocatable -qt-zlib -nomake examples -nomake tests -no-dbus -openssl-linked \
  -skip qt3d,qtactiveqt,qtandroidextras,qtcanvas3d,qtcharts,qtconnectivity \
  -skip qtdatavis3d,qtdoc,qtgamepad,qtgraphicaleffects,qtlocation,qtmacextras \
  -skip qtnetworkauth,qtpurchasing,qtremoteobjects,qtscript,qtscxml,qtsensors \
  -skip qtserialbus,qtspeech,qttools,qttranslations,qtvirtualkeyboard,qtwayland \
  -skip qtwebchannel,qtwebview,qtwinextras,qtx11extras,qtxmlpatterns,qtwebengine,qtimageformats \
  -- -DOPENSSL_ROOT_DIR="$OPENSSL_ROOT_DIR" -DCMAKE_OSX_ARCHITECTURES="x86_64;arm64"

# Build Qt
echo "Building Qt..."
cmake --build . && cmake --install .

# Add files to 7z archive
cd install && 7z a macos *
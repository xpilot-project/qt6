if(-not $args[0]) {
  Write-Host "Version parameter is required"
  Exit 1
}

Push-Location

Write-Output "Cloning the Qt repository"

git clone https://github.com/qt/qt5.git qt6 -b $args[0]

# Navigate to the Qt directory
Set-Location qt6

# Initialize the Qt repository with the required modules
Write-Output "Initializing the Qt repository with required modules..."
perl init-repository --module-subset=qtbase,qtdeclarative,qtimageformats,qtmultimedia,qtsvg,qtshadertools

Write-Output "Creating and entering the build directory..."
New-Item -Path 'build' -ItemType Directory -Force
Set-Location -Path 'build'

$platform = $pwd.Path + "\dependencies\platform\windows"

Write-Output "Cloning additional dependencies"
git clone https://github.com/xpilot-project/dependencies.git

Write-Output "Setting OPENSSL environment variable..."
$openssl_root_dir = "$platform\openssl"
$openssl_libs = "$platform\openssl\ssl.lib $platform\openssl\crypto.lib"

# Setup VC tools
$vswhere = "${env:ProgramFiles(x86)}\Microsoft Visual Studio\Installer\vswhere.exe"
$vcvarspath = &$vswhere -latest -products * -requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64 -property installationPath
Write-Output "Found path to VC tools: $vcvarspath"

cmd.exe /c "call `"$vcvarspath\VC\Auxiliary\Build\vcvars64.bat`" && set > %temp%\vcvars.txt"

Get-Content "$env:temp\vcvars.txt" | Foreach-Object {
  if ($_ -match "^(.*?)=(.*)$") {
    Set-Content "env:\$($matches[1])" $matches[2]
  }
}

Write-Output "Configuring Qt build..."
& "..\configure.bat" -prefix "./install" -debug-and-release -static -static-runtime -confirm-license `
  -feature-relocatable -qt-zlib -nomake examples -nomake tests -no-dbus -openssl-linked `
  -skip qt3d,qtactiveqt,qtandroidextras,qtcanvas3d,qtcharts,qtconnectivity `
  -skip qtdatavis3d,qtdoc,qtgamepad,qtgraphicaleffects,qtlocation,qtmacextras `
  -skip qtnetworkauth,qtpurchasing,qtremoteobjects,qtscript,qtscxml,qtsensors `
  -skip qtserialbus,qtspeech,qttools,qttranslations,qtvirtualkeyboard,qtwayland `
  -skip qtwebchannel,qtwebview,qtwinextras,qtx11extras,qtxmlpatterns,qtwebengine,qtimageformats `
  -- -DOPENSSL_ROOT_DIR="$openssl_root_dir"

Write-Output "Build Qt..."
cmake --build . --parallel

Write-Output "Install Qt..."
cmake --install .

Write-Output "Add files to 7z archive..."
Set-Location install
7z a windows *

Pop-Location
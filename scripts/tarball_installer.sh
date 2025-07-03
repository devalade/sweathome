#!/bin/bash

# Script to install Qt from a tarball on Linux

# --- Configuration ---
QT_TARBALL_NAME="qt-everywhere-src-5.15.2.tar.xz" # <--- IMPORTANT: Change this to your downloaded tarball name
INSTALL_DIR="/opt/Qt"                             # <--- IMPORTANT: Change this to your desired installation path
BUILD_DIR="qt_build"                              # Temporary build directory
DOWNLOAD_DIR="$HOME/Downloads"                    # Assuming your tarball is in Downloads
# --- End Configuration ---

echo "Starting Qt installation script..."
echo "----------------------------------"

# 1. Check if the tarball exists
if [ ! -f "$DOWNLOAD_DIR/$QT_TARBALL_NAME" ]; then
  echo "Error: Qt tarball '$DOWNLOAD_DIR/$QT_TARBALL_NAME' not found."
  echo "Please ensure the tarball is in the specified DOWNLOAD_DIR or update the QT_TARBALL_NAME variable."
  exit 1
fi

# 2. Extract the tarball
echo "Extracting Qt tarball..."
mkdir -p "$BUILD_DIR"
if tar -xf "$DOWNLOAD_DIR/$QT_TARBALL_NAME" -C "$BUILD_DIR" --strip-components=1; then
  echo "Extraction complete."
else
  echo "Error: Failed to extract the tarball. Please check the file and permissions."
  exit 1
fi

# Determine the extracted source directory name (usually something like qt-everywhere-src-5.15.2)
# This assumes the tarball extracts into a single top-level directory.
# We already stripped components, so now we are in the build directory.
QT_SOURCE_DIR=$(pwd) # Current directory is now the source directory after --strip-components=1

echo "Qt source directory: $QT_SOURCE_DIR"
cd "$QT_SOURCE_DIR" || {
  echo "Error: Could not change to Qt source directory."
  exit 1
}

# 3. Configure Qt
echo "Configuring Qt build..."
echo "This step might take a while depending on your system and chosen options."

# Common configuration options. You might need to adjust these based on your needs.
# For a full list of options, run './configure -help' in the extracted Qt source directory.
#
# -prefix <path>: Installation path
# -opensource: Use the open-source license
# -confirm-license: Confirm the license agreement
# -nomake examples: Don't build examples (saves time)
# -nomake tests: Don't build tests (saves time)
# -skip qtwebengine: Skips building QtWebEngine (can be very time-consuming and resource-intensive)
# -skip qtwebkit: Skips building QtWebKit (often deprecated)
# -opengl desktop: Use desktop OpenGL
# -qt-zlib -qt-libpng -qt-libjpeg -qt-freetype: Use Qt's bundled versions of these libraries
# -system-zlib -system-libpng -system-libjpeg -system-freetype: Use system versions of these libraries (requires dev packages)
# -optimized-tools: Build optimized tools

CONFIGURE_OPTIONS="\
-prefix $INSTALL_DIR \
-opensource \
-confirm-license \
-nomake examples \
-nomake tests \
-opengl desktop"
# -skip qtwebengine # Uncomment this if you don't need QtWebEngine and want to save time/space

echo "Running configure with options: $CONFIGURE_OPTIONS"
if ./configure $CONFIGURE_OPTIONS; then
  echo "Configuration complete."
else
  echo "Error: Qt configuration failed. Check the output above for details."
  echo "You might be missing dependencies. Please install them and try again."
  exit 1
fi

# 4. Compile Qt
echo "Compiling Qt..."
echo "This step will take a significant amount of time (hours) depending on your CPU and system resources."
# Use -j<number_of_cores> for parallel compilation to speed it up.
# NPROC=$(nproc) # Get number of available CPU cores
NPROC=$(grep -c ^processor /proc/cpuinfo) # A more portable way to get core count
if make -j$NPROC; then
  echo "Compilation complete."
else
  echo "Error: Qt compilation failed. Check the output above for details."
  exit 1
fi

# 5. Install Qt
echo "Installing Qt to $INSTALL_DIR..."
# This step often requires root privileges if installing to system directories.
if [ "$(id -u)" -eq 0 ]; then
  # Running as root, proceed directly
  if make install; then
    echo "Qt installation successful!"
  else
    echo "Error: Qt installation failed."
    exit 1
  fi
else
  # Not running as root, attempt with sudo
  echo "Root privileges are required for installation to $INSTALL_DIR."
  echo "Attempting to install with sudo..."
  if sudo make install; then
    echo "Qt installation successful!"
  else
    echo "Error: Qt installation failed with sudo. Please check your sudo permissions."
    exit 1
  fi
fi

# 6. Clean up (optional)
echo "Cleaning up temporary build directory ($BUILD_DIR)..."
cd "$HOME" || {
  echo "Error: Could not change to home directory."
  exit 1
}
rm -rf "$BUILD_DIR"
echo "Cleanup complete."

# 7. Post-installation steps (important for system to find Qt)
echo "--------------------------------------------------------"
echo "Qt installation finished. Now you need to set up your environment variables."
echo "Add the following lines to your ~/.bashrc or ~/.profile (and then source it):"
echo ""
echo "export QT_INSTALL_DIR=\"$INSTALL_DIR\""
echo "export PATH=\"\$QT_INSTALL_DIR/bin:\$PATH\""
echo "export LD_LIBRARY_PATH=\"\$QT_INSTALL_DIR/lib:\$LD_LIBRARY_PATH\""
echo "export PKG_CONFIG_PATH=\"\$QT_INSTALL_DIR/lib/pkgconfig:\$PKG_CONFIG_PATH\""
echo ""
echo "After adding, run: source ~/.bashrc (or source ~/.profile)"
echo ""
echo "To verify the installation, open a new terminal and run:"
echo "qmake -v"
echo "--------------------------------------------------------"

exit 0

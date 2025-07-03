#!/bin/bash

# Exit on error
set -e

echo "Starting Android development environment setup..."

# Update system
sudo apt update && sudo apt upgrade -y

# Install required packages
echo "Installing required packages..."
sudo apt install -y \
  openjdk-17-jdk \
  adb \
  lib32z1 \
  lib32stdc++6 \
  lib32gcc-s1

# Create Android development directory
echo "Creating Android development directory..."
mkdir -p ~/Android/Sdk
cd ~/Android

# Download and install Android Command Line Tools
echo "Downloading Android Command Line Tools..."
wget https://dl.google.com/android/repository/commandlinetools-linux-9477386_latest.zip
unzip commandlinetools-linux-*_latest.zip
rm commandlinetools-linux-*_latest.zip
mkdir -p cmdline-tools/latest
mv cmdline-tools/* cmdline-tools/latest/
rm -r cmdline-tools/latest/cmdline-tools

# Set up environment variables
echo "Setting up environment variables..."
echo 'export ANDROID_HOME=$HOME/Android/Sdk' >>~/.bashrc
echo 'export PATH=$PATH:$ANDROID_HOME/cmdline-tools/latest/bin' >>~/.bashrc
echo 'export PATH=$PATH:$ANDROID_HOME/platform-tools' >>~/.bashrc
source ~/.bashrc

# Install Android SDK components
echo "Installing Android SDK components..."
yes | sdkmanager --licenses
sdkmanager "platform-tools" "platforms;android-33" "build-tools;33.0.0"

# Install Expo CLI
echo "Installing Expo CLI..."
npm install -g expo-cli

# Create a new Expo project
read -p "Would you like to create a new Expo project? (y/n) " CREATE_PROJECT
if [ "$CREATE_PROJECT" = "y" ]; then
  read -p "Enter project name: " PROJECT_NAME
  npx create-expo-app $PROJECT_NAME
  cd $PROJECT_NAME

  # Add Android platform
  npx expo install

  echo "
Your new Expo project has been created!
To start development:
1. cd $PROJECT_NAME
2. npx expo start

To run on Android:
1. Connect your Android device via USB or start an Android emulator
2. Enable USB debugging on your device
3. Run 'npx expo start --android'
"
fi

echo "
Setup complete! Here are some useful commands:

- Start Expo development server: npx expo start
- Run on Android device/emulator: npx expo start --android
- Build standalone APK: eas build -p android

Make sure to:
1. Connect your Android device via USB or set up an Android emulator
2. Enable USB debugging on your device
3. Run 'adb devices' to verify device connection
"

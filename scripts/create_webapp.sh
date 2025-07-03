#!/bin/bash

# ==============================================================================
# Brave Web Link to App - A script for creating Brave-powered .desktop files
#
# Author: Your Coding Partner (AI Assistant)
# Version: 3.1 (Brave-specific)
#
# ------------------------------------------------------------------------------
#
# DESCRIPTION:
# This script creates a highly detailed .desktop file that launches a web link
# in a dedicated Brave Browser window. It is streamlined to use Brave by
# default without requiring user selection.
#
# FEATURES:
# - Asks for App Name, URL, and a Comment.
# - Automatically uses Brave's `--app` mode for a native feel.
# - Adds `--class` and `--name` flags for better window management.
# - Automatically finds and downloads a high-quality icon for the web app.
# - Creates a structured icon path in ~/Pictures/icons/.
# - Adds advanced fields like MimeType, StartupNotify, and Categories.
#
# REQUIRES: brave-browser, curl
#
# ==============================================================================

# --- Pre-flight Checks ---
if ! command -v brave-browser &>/dev/null; then
  echo "Error: 'brave-browser' is not installed or not in your PATH." >&2
  echo "Please install Brave Browser to use this script." >&2
  exit 1
fi
if ! command -v curl &>/dev/null; then
  echo "Error: 'curl' is not installed. Please install it with 'sudo apt install curl'" >&2
  exit 1
fi

# --- Introduction ---
echo "------------------------------------------------"
echo "Brave Web App Launcher Creator"
echo "------------------------------------------------"
echo

# --- Gather Information from User ---
read -p "Enter the name for your application (e.g., HEY): " app_name
if [ -z "$app_name" ]; then
  echo "Error: Application name cannot be empty." >&2
  exit 1
fi

# Sanitize the app name to create a valid Class/filename
app_class=$(echo "$app_name" | tr -d ' ' | tr '[:upper:]' '[:lower:]')
file_name="$app_class"

read -p "Enter a comment for the app (e.g., HEY Email + Calendar): " app_comment
if [ -z "$app_comment" ]; then
  app_comment="Web application for $app_name" # Default comment
fi

read -p "Enter the full web link (URL) (e.g., https://app.hey.com): " app_url
if [ -z "$app_url" ]; then
  echo "Error: Web link cannot be empty." >&2
  exit 1
fi
echo

# --- Set the Brave Command ---
browser_cmd="brave-browser"
exec_cmd="$browser_cmd --app=\"$app_url\" --name=$file_name --class=$file_name"
echo "✅ Using Brave Browser to create the application."

# --- Icon Handling ---
icon_dir="$HOME/Pictures/icons"
mkdir -p "$icon_dir"
icon_path="$icon_dir/$file_name.png"

echo "🔎 Attempting to download an icon for the website..."
# Use a favicon service to get the best available icon.
domain=$(echo "$app_url" | awk -F/ '{print $3}')
favicon_service_url="https://favicon.ico.hoerger.de/api/v2/$domain"

# Use curl to download the icon silently (-s), following redirects (-L)
if curl -sL "$favicon_service_url" -o "$icon_path"; then
  # Check if the downloaded file is a valid image
  if file "$icon_path" | grep -q 'image data'; then
    echo "✅ Icon successfully downloaded to: $icon_path"
  else
    echo "⚠️ Could not download a valid icon. A generic one may be used by the system."
    rm "$icon_path" # Clean up the invalid file
    icon_path=""    # Clear the path so it's not added to the .desktop file
  fi
else
  echo "⚠️ Icon download failed. A generic one may be used by the system."
  icon_path=""
fi

# --- Create the .desktop

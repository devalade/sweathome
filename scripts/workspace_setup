#!/bin/bash

# #############################################################################
#
# Workspace auto-start for three monitors with workspace management (v3)
#
# This script automates launching applications across a three-monitor setup
# and organizes them into separate workspaces on the main monitor.
#
# - Monitor 1: Apps in separate windows and workspaces (Notion, GitHub, etc.)
# - Monitor 2: Alacritty terminal.
# - Monitor 3: A new empty Brave window.
#
# INSTRUCTIONS:
#
# 1. MAKE THE SCRIPT EXECUTABLE:
#    chmod +x /path/to/your/script_name.sh
#
# 2. RUN THE SCRIPT:
#    Simply execute it from your terminal to start your workspace setup.
#
# #############################################################################

# --- CONFIGURATION ---

# Set your monitor names here
MONITOR_1="eDP-1"
MONITOR_2="DP-2"
MONITOR_3="HDMI-1"

# --- FUNCTION TO WAIT AND MOVE WINDOW BY CLASS ---
# This function is more reliable as it identifies windows by their WM_CLASS
# instead of their title, which can be slow to appear or change.
# Usage: wait_and_move "WM_CLASS.WM_CLASS" "App Name (for logging)" WORKSPACE_NUMBER
wait_and_move() {
  local CLASS=$1
  local APP_NAME=$2
  local WORKSPACE=$3
  echo "Waiting for '$APP_NAME' window (Class: $CLASS)..."

  # Try for 10 seconds to find the new window
  for i in {1..20}; do
    # Get the latest created window ID that matches the WM_CLASS
    # `wmctrl -lx` lists windows. We grep for the class. `tail -n 1` gets the most recent one. `awk` gets the ID.
    WID=$(wmctrl -lx | grep "$CLASS" | tail -n 1 | awk '{print $1}')

    # If a window ID was found, move it and exit the function
    if [ ! -z "$WID" ]; then
      echo "Found '$APP_NAME' (Window ID: $WID). Moving to workspace $WORKSPACE."
      wmctrl -i -r "$WID" -t "$WORKSPACE"
      return 0 # Success
    fi
    sleep 0.5
  done

  echo "Error: Could not find window for '$APP_NAME' after 10 seconds. It might have failed to launch or its WM_CLASS is different."
  return 1 # Failure
}

# --- SCRIPT ---

# Get monitor geometries for positioned windows
GEOMETRY_1=$(xrandr --query | grep "$MONITOR_1" | grep -o '[0-9]*x[0-9]*+[0-9]*+[0-9]*')
GEOMETRY_2=$(xrandr --query | grep "$MONITOR_2" | grep -o '[0-9]*x[0-9]*+[0-9]*+[0-9]*')
GEOMETRY_3=$(xrandr --query | grep "$MONITOR_3" | grep -o '[0-9]*x[0-9]*+[0-9]*+[0-9]*')

# --- LAUNCH POSITIONED APPLICATIONS ---

# Monitor 2: Alacritty Terminal
OFFSET_2=$(echo $GEOMETRY_2 | grep -o '[0-9]*+[0-9]*$' | sed 's/+/ /')
X_2=$(echo $OFFSET_2 | cut -d' ' -f1)
Y_2=$(echo $OFFSET_2 | cut -d' ' -f2)
alacritty --position $X_2,$Y_2 &

# Monitor 3: New empty Brave window
brave-browser --profile-directory="Alade" --new-window "about:newtab" --window-position=${GEOMETRY_3#*+} &

# --- LAUNCH AND ORGANIZE APPS INTO WORKSPACES ---
# We launch each app in the background, then call the function to wait and move it.

# Workspace 0: Notion (New Window on Monitor 1)
brave-browser --profile-directory="Alade" --new-window --window-position=${GEOMETRY_1#*+} "https://www.notion.so/dev-alade/Money-Making-System-4306d98a13ad4b939449a61263ad6ed0" &
wait_and_move "brave-browser.Brave-browser" "Notion" 0

# Workspace 1: GitHub (New Window on Monitor 1)
brave-browser --profile-directory="Alade" --new-window --window-position=${GEOMETRY_1#*+} "https://www.github.com" &
wait_and_move "brave-browser.Brave-browser" "GitHub" 1

# Workspace 2: Gemini (New Window on Monitor 1)
brave-browser --profile-directory="Alade" --new-window --window-position=${GEOMETRY_1#*+} "https://gemini.google.com" &
wait_and_move "brave-browser.Brave-browser" "Gemini" 2

# Workspace 3: Spotify
spotify &
wait_and_move "spotify.Spotify" "Spotify" 3

# Optional: Switch back to the first workspace to start
sleep 1
wmctrl -s 0

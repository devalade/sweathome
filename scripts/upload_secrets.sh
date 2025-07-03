#!/bin/bash
#
# ====================================================================================
#
#   ██████╗ ███████╗ ██████╗██████╗ ████████╗███████╗     ██████╗ ██╗  ██╗
#  ██╔════╝ ██╔════╝██╔════╝██╔══██╗╚══██╔══╝██╔════╝    ██╔═══██╗██║  ██║
#  ██║  ███╗█████╗  ██║     ██████╔╝   ██║   █████╗      ██║   ██║███████║
#  ██║   ██║██╔══╝  ██║     ██╔══██╗   ██║   ██╔══╝      ██║   ██║██╔════╝
#  ╚██████╔╝███████╗╚██████╗██║  ██║   ██║   ███████╗    ╚██████╔╝██║
#   ╚═════╝ ╚══════╝ ╚═════╝╚═╝  ╚═╝   ╚═╝   ╚══════╝     ╚═════╝ ╚═╝
#
# ====================================================================================
#
#  GITHUB SECRET UPLOADER (WITH GUIDED SETUP)
#
#  This script automates uploading secrets to GitHub. If dependencies are
#  missing, it will provide instructions on how to install them.
#
#  --- HOW IT WORKS ---
#  1.  It checks for dependencies (`git`, `gh`, `yq`) and guides you through installation if needed.
#  2.  It automatically detects the target repository from your local Git remote 'origin'.
#  3.  It reads secret keys from `config/deploy.yml` and their values from a .env file.
#  4.  It securely uploads the secrets to your repository.
#
#  --- PREREQUISITES ---
#  - git, gh, yq (The script will help you install these).
#
#  --- USAGE ---
#  # To use the default '.env' file:
#  ./upload_secrets.sh
#
#  # To use a specific environment file:
#  ./upload_secrets.sh .env.production
#
# ====================================================================================

# --- Configuration ---
# !!! SET TO "true" TO ENABLE DEBUG MESSAGES !!!
DEBUG="true"

CONFIG_FILE="config/deploy.yml"
ENV_FILE="${1:-.env}"

# --- Script Start ---
set -o nounset
set -e

# (Helper functions and prerequisite checks are here...)
# --- Helper Functions ---
function print_message() {
  local message="$1"
  local type="${2:-INFO}"
  case "$type" in
  INFO) echo "[INFO] $message" ;;
  SUCCESS) echo -e "\e[32m[SUCCESS]\e[0m $message" ;;
  ERROR) echo -e "\e[31m[ERROR]\e[0m $message" >&2 ;;
  WARN) echo -e "\e[33m[WARN]\e[0m $message" ;;
  DEBUG)
    if [ "$DEBUG" == "true" ]; then
      echo -e "\e[34m[DEBUG]\e[0m $message" # Blue text for debug
    fi
    ;;
  esac
}

# --- Guided Installation Function ---
function provide_install_instructions() {
  local cmd="$1"
  print_message "The command '$cmd' is required but could not be found." "ERROR"
  # ... (rest of the function is the same as before) ...
  echo "After installation, please run this script again."
  exit 1
}

# --- Prerequisite Checks ---
if ! command -v git &>/dev/null || ! git rev-parse --is-inside-work-tree &>/dev/null; then provide_install_instructions "git"; fi
if ! command -v gh &>/dev/null; then provide_install_instructions "gh"; fi
if ! command -v yq &>/dev/null; then provide_install_instructions "yq"; fi
if [ ! -f "$CONFIG_FILE" ]; then
  print_message "Config file not found: $CONFIG_FILE" "ERROR"
  exit 1
fi
if [ ! -f "$ENV_FILE" ]; then
  print_message ".env file not found: $ENV_FILE" "ERROR"
  exit 1
fi
print_message "All dependencies are installed and files are present." "SUCCESS"

# --- Automatically Detect Repository ---
# (This section is the same as before)
print_message "Detecting repository..."
REMOTE_URL=$(git remote get-url origin 2>/dev/null)
GITHUB_REPO=$(echo "$REMOTE_URL" | sed -e 's/.*github.com[:/]//' -e 's/\.git$//')
print_message "Successfully detected repository: $GITHUB_REPO" "SUCCESS"
echo

# --- Main Logic ---

# NEW: More robust way to load the .env file.
# It temporarily exports all variables defined in the file.
set -o allexport
print_message "Loading environment variables from $ENV_FILE"
source "$ENV_FILE"
set +o allexport

# Parse the YAML file to get the list of secret keys.
secret_keys=$(yq .env.secret[] "$CONFIG_FILE")
print_message "Found keys in $CONFIG_FILE to process." "DEBUG"
print_message "KEYS: $secret_keys" "DEBUG"

echo # Add newline

for key in $secret_keys; do
  print_message "Processing key: '$key'"

  # Check if the variable is set in the environment (from the .env file).
  # The `${!key+x}` syntax checks if a variable with the name stored in `key` is set.
  if [ -n "${!key+x}" ]; then
    value="${!key}"
    print_message "Value for '$key' was found in $ENV_FILE." "DEBUG"
    # The line below is commented out for security, but you can uncomment it
    # temporarily for local debugging if you are certain no one can see your screen.
    # print_message "VALUE: '$value'" "DEBUG"

    print_message "Found '$key'. Preparing to upload to GitHub..."

    # Use --body flag for more robust value passing
    gh secret set "$key" --body "$value" --repo "$GITHUB_REPO"

    print_message "'$key' has been successfully uploaded." "SUCCESS"
  else
    print_message "Secret key '$key' not found in $ENV_FILE. Skipping." "WARN"
  fi
  echo # Add a newline for better readability
done

print_message "Secret synchronization complete for repository: $GITHUB_REPO" "SUCCESS"

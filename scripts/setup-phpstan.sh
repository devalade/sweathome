#!/bin/bash

# This script automates the setup of PHPStan in your project.
# It checks for Composer, installs PHPStan, and creates a
# configuration file with your input.

# --- Functions ---

# Function to check if a command exists
command_exists() {
  command -v "$1" >/dev/null 2>&1
}

# Function to display colored messages
echo_color() {
  case "$1" in
  "green") echo -e "\e[32m$2\e[0m" ;;
  "red") echo -e "\e[31m$2\e[0m" ;;
  "yellow") echo -e "\e[33m$2\e[0m" ;;
  *) echo "$2" ;;
  esac
}

# --- Main Script ---

echo_color "green" "🚀 Starting PHPStan setup..."

# 1. Check for Composer
if ! command_exists composer; then
  echo_color "red" "Error: Composer is not installed. Please install Composer and try again."
  exit 1
fi

echo_color "green" "✅ Composer is installed."

# 2. Install PHPStan
echo_color "yellow" "Installing PHPStan (this may take a moment)..."
composer require --dev phpstan/phpstan

if [ ! -f "vendor/bin/phpstan" ]; then
  echo_color "red" "Error: PHPStan installation failed."
  exit 1
fi

echo_color "green" "✅ PHPStan installed successfully."

# 3. Create phpstan.neon.dist
if [ -f "phpstan.neon" ] || [ -f "phpstan.neon.dist" ]; then
  echo_color "yellow" "A PHPStan configuration file already exists. Skipping creation."
else
  echo_color "yellow" "Creating phpstan.neon.dist configuration file..."

  # Get user input for configuration
  read -p "What analysis level would you like to start with? (0-9, 5 is a good start): " level
  level=${level:-5} # Default to 5 if no input

  read -p "Enter the paths to analyze (e.g., src, tests): " paths
  paths=${paths:-src} # Default to 'src' if no input

  # Create the configuration file
  cat >phpstan.neon.dist <<EOL
parameters:
    level: $level
    paths:
        - $paths
    # Add more paths to analyze here, for example:
    #   - tests

    # --- Optional Extensions ---
    # Uncomment the following lines if you are using Doctrine or PHPUnit
    # includes:
    #     - vendor/phpstan/phpstan-doctrine/extension.neon
    #     - vendor/phpstan/phpstan-phpunit/extension.neon
    #     - vendor/phpstan/phpstan-phpunit/rules.neon

    # --- Ignoring Errors ---
    # You can ignore specific error messages or errors in certain files.
    # ignoreErrors:
    #     - '#PHPDoc tag @var is not valid for a class property#'
    #     -
    #         message: '#Call to an undefined method#'
    #         paths:
    #             - src/SomeLegacyFile.php
EOL

  echo_color "green" "✅ phpstan.neon.dist created successfully."
fi

# 4. Final Instructions
echo_color "green" "\n🎉 PHPStan setup is complete! 🎉"
echo_color "yellow" "To run PHPStan, use the following command:"
echo "vendor/bin/phpstan analyse"
echo_color "yellow" "\nYou can customize the configuration in the 'phpstan.neon.dist' file."

exit 0

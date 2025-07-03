#!/bin/bash

# This script automates the setup of the 'barryvdh/laravel-ide-helper'
# package in your Laravel project. (Version 2 - Corrected)

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

echo_color "green" "🚀 Starting Laravel IDE Helper setup..."

# 1. Check for Laravel Project
if [ ! -f "artisan" ]; then
  echo_color "red" "Error: 'artisan' file not found. Please run this script from the root of your Laravel project."
  exit 1
fi

echo_color "green" "✅ Laravel project detected."

# 2. Check for Composer
if ! command_exists composer; then
  echo_color "red" "Error: Composer is not installed. Please install Composer and try again."
  exit 1
fi

echo_color "green" "✅ Composer is installed."

# 3. Install the package
echo_color "yellow" "Installing barryvdh/laravel-ide-helper (this may take a moment)..."
composer require --dev barryvdh/laravel-ide-helper

# 4. CORRECTED CHECK: Verify that the artisan commands are available
echo_color "yellow" "Verifying installation..."
if ! php artisan list | grep -q 'ide-helper:'; then
  echo_color "red" "Error: IDE Helper installation failed. The artisan commands are not available."
  exit 1
fi

echo_color "green" "✅ IDE Helper installed and commands are registered successfully."

# 5. Generate initial helper files
echo_color "yellow" "Generating helper files..."
php artisan ide-helper:generate
php artisan ide-helper:meta

echo_color "green" "✅ Helper files generated."

# 6. Configure composer.json for automation
echo_color "yellow" "Configuring composer.json to auto-generate files on update..."
if command_exists jq; then
  # Use jq to safely add scripts to composer.json
  jq '.scripts."post-update-cmd" += ["@php artisan ide-helper:generate", "@php artisan ide-helper:meta"]' composer.json >composer.json.tmp && mv composer.json.tmp composer.json
  echo_color "green" "✅ 'composer.json' updated automatically using jq."
else
  echo_color "yellow" "Warning: 'jq' is not installed. You will need to manually update composer.json."
  echo "Please add the following lines to the 'post-update-cmd' section of your composer.json file:"
  echo_color "green" '"@php artisan ide-helper:generate",'
  echo_color "green" '"@php artisan ide-helper:meta",'
fi

# 7. Update .gitignore
GITIGNORE_FILE=".gitignore"
HELPER_FILE_LINE="/_ide_helper.php"

if [ -f "$GITIGNORE_FILE" ] && grep -q "$HELPER_FILE_LINE" "$GITIGNORE_FILE"; then
  echo_color "yellow" "Removing '$HELPER_FILE_LINE' from .gitignore..."
  # Use grep to filter out the line and overwrite the file
  grep -v "$HELPER_FILE_LINE" "$GITIGNORE_FILE" >.gitignore.tmp && mv .gitignore.tmp "$GITIGNORE_FILE"
  echo_color "green" "✅ .gitignore updated."
else
  echo_color "green" "'_ide_helper.php' is not being ignored by git. No changes needed."
fi

# 8. Final Instructions
echo_color "green" "\n🎉 Laravel IDE Helper setup is complete! 🎉"
echo_color "yellow" "Your IDE should now have enhanced autocompletion for Laravel."
echo "The helper files will be automatically updated every time you run 'composer update'."
echo ""
echo_color "yellow" "💡 Pro Tip: For even better model autocompletion, you can run:"
echo "php artisan ide-helper:models --nowrite"
echo "This generates PHPDoc blocks for your models. Run it whenever you change a model's properties."
echo ""
echo_color "yellow" "➡️ Next Steps: Commit the updated files to your repository:"
echo "git add composer.json composer.lock .gitignore _ide_helper.php .phpstorm.meta.php"
echo "git commit -m \"Configure Laravel IDE Helper\""

exit 0

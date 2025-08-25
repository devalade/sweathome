#!/bin/bash

# This script automates the setup of Rector for a PHP/Laravel project.

# --- Functions ---

# Function to display colored messages
echo_color() {
  case "$1" in
  "green") echo -e "\e[32m$2\e[0m" ;;
  "red") echo -e "\e[31m$2\e[0m" ;;
  "yellow") echo -e "\e[33m$2\e[0m" ;;
  "cyan") echo -e "\e[36m$2\e[0m" ;;
  *) echo "$2" ;;
  esac
}

# Function to check if a command exists
command_exists() {
  command -v "$1" >/dev/null 2>&1
}

# --- Main Script ---

echo_color "cyan" "🚀 Setting up Rector..."

# 1. Check if we are in a PHP project root (by checking for composer.json)
if [ ! -f "composer.json" ]; then
  echo_color "red" "Error: 'composer.json' not found. Please run this script from the root of your PHP project."
  exit 1
fi

echo_color "green" "✅ PHP project detected."

# 2. Install Rector via Composer
echo_color "yellow" "Installing rector/rector (this may take a moment)..."
composer require --dev rector/rector

if [ ! -f "vendor/bin/rector" ]; then
  echo_color "red" "Error: Rector installation failed."
  exit 1
fi

echo_color "green" "✅ Rector installed successfully."

# 3. Create the rector.php configuration file
RECTOR_CONFIG_FILE="rector.php"

if [ -f "$RECTOR_CONFIG_FILE" ]; then
  echo_color "yellow" "⚠️  Warning: File already exists at '$RECTOR_CONFIG_FILE'. Skipping creation."
else
  # Use a HEREDOC to write the PHP config into the file
  cat >"$RECTOR_CONFIG_FILE" <<'EOF'
<?php

declare(strict_types=1);

use Rector\Config\RectorConfig;
use Rector\Set\ValueObject\LevelSetList;
use Rector\Set\ValueObject\SetList;

return static function (RectorConfig $rectorConfig): void {
    // register paths to analyze
    $rectorConfig->paths([
        __DIR__ . '/app',
        __DIR__ . '/config',
        __DIR__ . '/database',
        __DIR__ . '/public',
        __DIR__ . '/resources',
        __DIR__ . '/routes',
        __DIR__ . '/tests',
    ]);

    // define sets of rules
    $rectorConfig->sets([
        LevelSetList::UP_TO_PHP_81, // Target your project's PHP version
        SetList::CODE_QUALITY,
        SetList::DEAD_CODE,
        SetList::TYPE_DECLARATION, // This is the key set for adding typehints
        SetList::CODING_STYLE,
        SetList::PRIVATIZATION,
    ]);

    // You can skip specific rules or directories if needed
    $rectorConfig->skip([
        // e.g. \Rector\CodeQuality\Rector\Class_\InlineConstructorDefaultToPropertyRector::class,
    ]);
};
EOF
  echo_color "green" "✅ Successfully created Rector config file: $RECTOR_CONFIG_FILE"
fi

# 4. Configure composer.json shortcuts
echo_color "yellow" "Adding Rector shortcut scripts to composer.json..."
if command_exists jq; then
  # Use jq to safely add scripts to composer.json
  jq '.scripts += {"rector:analyse": "vendor/bin/rector process --dry-run", "rector:fix": "vendor/bin/rector process"}' composer.json >composer.json.tmp && mv composer.json.tmp composer.json
  echo_color "green" "✅ 'composer.json' updated automatically with 'rector:analyse' and 'rector:fix' scripts."
else
  echo_color "yellow" "Warning: 'jq' is not installed. You can add these scripts to composer.json manually:"
  echo_color "green" '"rector:analyse": "vendor/bin/rector process --dry-run",'
  echo_color "green" '"rector:fix": "vendor/bin/rector process",'
fi

# 5. Print final instructions
echo_color "cyan" "\n🎉 Rector setup complete! Here's how to use it: 🎉"
echo ""
echo_color "yellow" "1. Perform a 'dry run' using the new composer script:"
echo_color "green" "   composer rector:analyse"
echo ""
echo_color "yellow" "2. After reviewing the changes, apply the fixes:"
echo_color "green" "   composer rector:fix"
echo ""
echo_color "yellow" "3. Review the changes with 'git diff' and commit them."
echo ""

exit 0

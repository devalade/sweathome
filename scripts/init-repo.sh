#!/bin/bash

# Script to initialize a Git repository based on the current folder name.
# Assumes the folder you run this in should be the root of your new repository,
# and its name matches the desired repository name on GitHub.

# --- Configuration ---
# Get the current directory's base name
repo_name=$(basename "$PWD")

# --- Check for potential problems ---
if [ -z "$repo_name" ]; then
  echo "Error: Could not determine repository name from the current directory."
  exit 1
fi

if [ -d ".git" ]; then
  echo "Error: This directory is already a Git repository."
  exit 1
fi

# --- Get User Input ---
read -p "Enter your GitHub username: " github_username

if [ -z "$github_username" ]; then
  echo "Error: GitHub username cannot be empty."
  exit 1
fi

# Construct the remote URL (SSH format, as in your example)
remote_url="git@github.com:${github_username}/${repo_name}.git"

# --- Execute Git Commands ---
echo "--- Initializing Git repository: ${repo_name} ---"
echo "Using remote URL: ${remote_url}"
echo "" # Newline for readability

# 1. Create README.md with the repository name as the title
echo "# ${repo_name}" >README.md
echo "1. Created README.md"

# 2. Initialize the Git repository
git init
echo "2. Initialized Git repository"

# 3. Add the README.md file to the staging area
git add README.md
echo "3. Added README.md to staging area"

# 4. Create the first commit
git commit -m "Initial commit"
echo "4. Created initial commit"

# 5. Rename the default branch to 'main'
git branch -M main
echo "5. Renamed branch to main"

# 6. Add the remote repository URL
git remote add origin "${remote_url}"
if [ $? -ne 0 ]; then
  echo "Warning: Failed to add remote 'origin'. It might already exist."
  # Optional: you could try 'git remote set-url origin "${remote_url}"' here
  # But for simplicity, we'll just warn and continue.
else
  echo "6. Added remote 'origin'"
fi

# 7. Push the 'main' branch to the remote repository 'origin'
#    The '-u' flag sets the upstream branch for future pulls/pushes
echo "7. Pushing to origin main..."
git push -u origin main

# Check the exit status of the push command
if [ $? -eq 0 ]; then
  echo "" # Newline
  echo "--- Repository initialization complete and pushed successfully! ---"
else
  echo "" # Newline
  echo "*** Error during push operation! ***"
  echo "Please check the following:"
  echo "  - The repository '${repo_name}' exists on GitHub under user '${github_username}'."
  echo "  - You have the correct permissions (SSH keys set up for git@github.com)."
  echo "  - Your network connection is active."
  exit 1
fi

exit 0

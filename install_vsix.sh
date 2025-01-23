#!/bin/bash

# Script to install all VSIX files from the given directory into VS Code or code-server

# Directory containing the VSIX files
DOWNLOAD_DIR="vsix_downloads"

# Check if the directory exists
if [ ! -d "$DOWNLOAD_DIR" ]; then
  echo "Error: Directory '$DOWNLOAD_DIR' not found!"
  exit 1
fi

# Find all .vsix files in the directory
VSIX_FILES=$(find "$DOWNLOAD_DIR" -type f -name "*.vsix")

# Check if there are any .vsix files
if [ -z "$VSIX_FILES" ]; then
  echo "No .vsix files found in '$DOWNLOAD_DIR'."
  exit 1
fi

# Install each .vsix file using code-server or code
for VSIX_FILE in $VSIX_FILES; do
  echo "Installing $VSIX_FILE..."
  
  # Use `code` or `code-server` command to install
  if command -v code &>/dev/null; then
    code --install-extension "$VSIX_FILE"
  elif command -v code-server &>/dev/null; then
    code-server --install-extension "$VSIX_FILE"
  else
    echo "Error: Neither 'code' nor 'code-server' is installed on this system."
    exit 1
  fi

  # Check the installation status
  if [ $? -eq 0 ]; then
    echo "Successfully installed $VSIX_FILE."
  else
    echo "Failed to install $VSIX_FILE."
  fi
done

echo "All installations complete."
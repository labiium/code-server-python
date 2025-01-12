#!/bin/bash
# Script to automatically download multiple VSIX files from the Visual Studio Code Marketplace
# using the new URL template:
#   https://<publisher>.gallery.vsassets.io/_apis/public/gallery/publisher/<publisher>/extension/<extension>/<version>/assetbyname/Microsoft.VisualStudio.Services.VSIXPackage
#
# Each line in the input file should contain: publisher, extension, version
# Example line: ms-vscode csharp 1.3.0

# Check if the input file is provided
if [ "$#" -ne 1 ]; then
  echo "Usage: $0 <extensions-list-file>"
  echo "Example: $0 extensions.txt"
  exit 1
fi

INPUT_FILE="$1"

# Verify that the input file exists
if [ ! -f "$INPUT_FILE" ]; then
  echo "Error: File '$INPUT_FILE' not found!"
  exit 1
fi

# Create a directory to store the downloaded VSIX files
DOWNLOAD_DIR="vsix_downloads"
mkdir -p "$DOWNLOAD_DIR"

# Loop through each non-empty line in the input file
while IFS=' ' read -r PUBLISHER EXTENSION VERSION || [[ -n "$PUBLISHER" ]]; do
  # Skip lines that do not contain exactly 3 fields
  if [[ -z "$PUBLISHER" || -z "$EXTENSION" || -z "$VERSION" ]]; then
    echo "Skipping invalid line in $INPUT_FILE: '$PUBLISHER $EXTENSION $VERSION'"
    continue
  fi

  # Construct the download URL using the new template
  URL="https://${PUBLISHER}.gallery.vsassets.io/_apis/public/gallery/publisher/${PUBLISHER}/extension/${EXTENSION}/${VERSION}/assetbyname/Microsoft.VisualStudio.Services.VSIXPackage"
  
  # Set an output file name that encodes the publisher, extension, and version
  OUTPUT_FILE="${DOWNLOAD_DIR}/${PUBLISHER}.${EXTENSION}-${VERSION}.vsix"

  # Download the VSIX file using curl
  echo "Downloading ${PUBLISHER}.${EXTENSION} (version ${VERSION}) from:"
  echo "  $URL"
  curl -L -o "$OUTPUT_FILE" "$URL"

  # Check if the download was successful
  if [ $? -eq 0 ]; then
    echo "Downloaded and saved as $OUTPUT_FILE successfully!"
  else
    echo "Failed to download ${PUBLISHER}.${EXTENSION} version ${VERSION}. Skipping..."
  fi
done < "$INPUT_FILE"

echo "All downloads complete. Files are located in the '$DOWNLOAD_DIR' directory."

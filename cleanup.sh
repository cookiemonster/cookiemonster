#!/bin/bash

# Fresh start
# Cleans up cluttering files by moving them in directories with a timestamp and pull not existing directories
# Version 0.4

# Get yesterday's date in YYYY-MM-DD format
YESTERDAY=$(date -d "yesterday" '+%Y-%m-%d')

# Load directories to organize
DIRECTORIES=(
  "$HOME/Downloads"
  "$HOME/Documents"
  "$HOME/Pictures"
  "$HOME/Pictures/Screenshots"
  "$HOME/Desktop"
)

move_files() {
  local DIR=$1
  local YESTERDAY=$2
  FILE_COUNT=$(find "$DIR" -maxdepth 1 -type f | wc -l)

  if [ "$FILE_COUNT" -gt 0 ]; then
    NEW_DIR="$DIR/$YESTERDAY"
    mkdir -p "$NEW_DIR"
    find "$DIR" -maxdepth 1 -type f -exec mv {} "$NEW_DIR" \;
    echo "Moved $FILE_COUNT files from $DIR to $NEW_DIR"
  else
    echo "No files to move in $DIR"
  fi
}


# Organize files
for DIR in "${DIRECTORIES[@]}"; do
  move_files "$DIR" "$YESTERDAY"
done


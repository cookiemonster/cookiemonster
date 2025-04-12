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

# Load active projects
REPOS=()
while IFS= read -r line; do
  [[ -n "$line" ]] || continue  # Skip empty lines

  if [[ "$line" = /* ]]; then
    REPOS+=("$line")
  else
    REPOS+=("$HOME/$line")
  fi
done < "$HOME/cookiemonster/active-projects.txt"

# Load GitHub sources from file
GITHUB_SOURCES=()
while IFS= read -r source; do
  [[ -n "$source" ]] || continue
  GITHUB_SOURCES+=("$source")
done < "$HOME/cookiemonster/github-sources.txt"

# Function to move files to a dated subdirectory
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

# Function to check or clone a repository
check_repo() {
  local REPO=$1
  local REPO_NAME
  REPO_NAME=$(basename "$REPO")

  if [ -d "$REPO" ]; then
    cd "$REPO" || { echo "Failed to cd into $REPO"; return; }

    # Check for uncommitted changes
    if ! git diff-index --quiet HEAD --; then
      echo "The repository at $REPO has uncommitted changes."
      git add .
      COMMIT_MSG="Auto-commit on $(date '+%Y-%m-%d %H:%M:%S')"
      git commit -m "$COMMIT_MSG"
      git push origin "$(git rev-parse --abbrev-ref HEAD)"
      echo "Committed and pushed changes to $REPO"
    fi

    # Check for untracked files
    if [ -n "$(git ls-files --others --exclude-standard)" ]; then
      echo "The repository at $REPO has untracked files."
      git add .
      COMMIT_MSG="Auto-commit on $(date '+%Y-%m-%d %H:%M:%S')"
      git commit -m "$COMMIT_MSG"
      git push origin "$(git rev-parse --abbrev-ref HEAD)"
      echo "Committed and pushed untracked changes to $REPO"
    fi

    git fetch origin

    LOCAL=$(git rev-parse HEAD)
    REMOTE=$(git rev-parse origin/$(git rev-parse --abbrev-ref HEAD))
    BASE=$(git merge-base HEAD origin/$(git rev-parse --abbrev-ref HEAD))

    if [ "$LOCAL" = "$REMOTE" ]; then
      echo "The repository at $REPO is up to date."
    elif [ "$LOCAL" = "$BASE" ]; then
      echo "The repository at $REPO needs to pull updates."
      git pull origin "$(git rev-parse --abbrev-ref HEAD)"
    elif [ "$REMOTE" = "$BASE" ]; then
      echo "The repository at $REPO needs to push updates."
    else
      echo "The repository at $REPO has diverged."
    fi
  else
    echo "The directory $REPO does not exist. Attempting to clone..."

    local CLONED=0
    for SOURCE in "${GITHUB_SOURCES[@]}"; do
      GITHUB_URL="https://github.com/$SOURCE/$REPO_NAME.git"
      echo "Trying $GITHUB_URL..."
      git clone "$GITHUB_URL" "$REPO" && {
        echo "Successfully cloned $REPO_NAME from $SOURCE"
        CLONED=1
        break
      }
    done

    if [ "$CLONED" -eq 0 ]; then
      echo "❌ Failed to clone $REPO_NAME from any GitHub source."
    fi
  fi
}

# Organize files
for DIR in "${DIRECTORIES[@]}"; do
  move_files "$DIR" "$YESTERDAY"
done

# Handle repos
for REPO in "${REPOS[@]}"; do
  check_repo "$REPO"
done

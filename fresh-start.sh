#!/bin/bash

# Get yesterday's date in YYYY-MM-DD format
YESTERDAY=$(date -d "yesterday" '+%Y-%m-%d')

# Directories to be processed
DIRECTORIES=("$HOME/Downloads" "$HOME/Pictures" "$HOME/Pictures/Screenshots")
REPOS=("$HOME/Documents/notes" "$HOME/projects/victorgevers.com" "$HOME/cookiemonster")  

# Function to move files to a dated directory
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

# Function to check if a git repository is up to date with GitHub and commit changes if necessary
check_repo() {
  local REPO=$1
  if [ -d "$REPO" ]; then
    cd "$REPO" || { echo "Failed to cd into $REPO"; return; }

    # Check for uncommitted changes
    if ! git diff-index --quiet HEAD --; then
      echo "The repository at $REPO has uncommitted changes."
      git add .
      COMMIT_MSG="Auto-commit on $(date '+%Y-%m-%d %H:%M:%S')"
      git commit -m "$COMMIT_MSG"
      git push origin "$(git rev-parse --abbrev-ref HEAD)"
      echo "Committed and pushed changes to $REPO with message: $COMMIT_MSG"
    fi

    # Check for untracked files
    if [ -n "$(git ls-files --others --exclude-standard)" ]; then
      echo "The repository at $REPO has untracked files."
      git add .
      COMMIT_MSG="Auto-commit on $(date '+%Y-%m-%d %H:%M:%S')"
      git commit -m "$COMMIT_MSG"
      git push origin "$(git rev-parse --abbrev-ref HEAD)"
      echo "Committed and pushed changes to $REPO with message: $COMMIT_MSG"
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
      echo "Pulled updates for $REPO"
    elif [ "$REMOTE" = "$BASE" ]; then
      echo "The repository at $REPO needs to push updates."
    else
      echo "The repository at $REPO has diverged."
    fi
  else
    echo "The directory $REPO does not exist."
  fi
}

# Process each directory
for DIR in "${DIRECTORIES[@]}"; do
  move_files "$DIR" "$YESTERDAY"
done

# Check each repository
for REPO in "${REPOS[@]}"; do
  check_repo "$REPO"
done


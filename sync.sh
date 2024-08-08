#!/bin/bash

# Check if the input file is provided
if [ -z "$1" ]; then
  echo "Usage: $0 active-projects.txt"
  exit 1
fi

# Read the input file line by line
while IFS= read -r directory; do
  # Check if the directory exists
  if [ -d "$HOME/$directory" ]; then
    cd "$HOME/$directory" || continue
    
    # Check if it's a git repository
    if [ -d ".git" ]; then
      # Check for changes
      if [ -n "$(git status --porcelain)" ]; then
        # Add new files to the staging area
        git add .
        
        # Commit the changes with a timestamp
        commit_message="Automated commit on $(date +"%Y-%m-%d %H:%M:%S")"
        git commit -m "$commit_message"
        
        # Push the changes to the remote repository
        git push
      else
        echo "No changes in $directory"
      fi
    else
      echo "$directory is not a git repository"
    fi
  else
    echo "Directory $directory does not exist"
  fi
done < "$1"


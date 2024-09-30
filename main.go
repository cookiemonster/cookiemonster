package main

import (
 "fmt"
 "log"
 "os"
 "os/exec"
 "path/filepath"
 "time"
)

// moveFiles moves files from a given directory to a subdirectory named with yesterday's date.
func moveFiles(dir string, yesterday string) {
 files, err := os.ReadDir(dir)
 if err != nil {
  log.Fatalf("Failed to read directory %s: %v", dir, err)
 }

 fileCount := 0
 for _, file := range files {
  if !file.IsDir() {
   fileCount++
  }
 }

 if fileCount > 0 {
  newDir := filepath.Join(dir, yesterday)
  err := os.MkdirAll(newDir, 0755)
  if err != nil {
   log.Fatalf("Failed to create directory %s: %v", newDir, err)
  }

  for _, file := range files {
   if !file.IsDir() {
    oldPath := filepath.Join(dir, file.Name())
    newPath := filepath.Join(newDir, file.Name())
    err := os.Rename(oldPath, newPath)
    if err != nil {
     log.Fatalf("Failed to move file %s to %s: %v", oldPath, newPath, err)
    }
   }
  }

  fmt.Printf("Moved %d files from %s to %s\n", fileCount, dir, newDir)
 } else {
  fmt.Printf("No files to move in %s\n", dir)
 }
}

// checkRepo checks if a git repository is up-to-date and performs necessary actions.
func checkRepo(repo string) {
 if _, err := os.Stat(repo); err != nil {
  if os.IsNotExist(err) {
   fmt.Printf("The directory %s does not exist.\n", repo)
  } else {
   log.Fatalf("Failed to check directory %s: %v", repo, err)
  }
  return
 }

 // Function to run a git command and handle errors
 runGitCommand := func(repo string, args ...string) (string, error) {
  cmd := exec.Command("git", args...)
  cmd.Dir = repo
  output, err := cmd.CombinedOutput()
  if err != nil {
   return "", fmt.Errorf("failed to run git command: %w\nOutput: %s", err, output)
  }
  return string(output), nil
 }

 // Check for uncommitted or untracked changes
 output, err := runGitCommand(repo, "status", "--porcelain")
 if err != nil {
  log.Fatalf("Error checking git status: %v", err)
 }
 if output != "" {
  fmt.Printf("The repository at %s has uncommitted or untracked changes.\n", repo)
  _, err = runGitCommand(repo, "add", ".")
  if err != nil {
   log.Fatalf("Error adding changes: %v", err)
  }
  commitMsg := fmt.Sprintf("Auto-commit on %s", time.Now().Format("2006-01-02 15:04:05"))
  _, err = runGitCommand(repo, "commit", "-m", commitMsg)
  if err != nil {
   log.Fatalf("Error committing changes: %v", err)
  }
  _, err = runGitCommand(repo, "push", "origin", "HEAD")
  if err != nil {
   log.Fatalf("Error pushing changes: %v", err)
  }
  fmt.Printf("Committed and pushed changes to %s with message: %s\n", repo, commitMsg)
 }

 // Check for updates
 _, err = runGitCommand(repo, "fetch", "origin")
 if err != nil {
  log.Fatalf("Error fetching updates: %v", err)
 }
 local, err := runGitCommand(repo, "rev-parse", "HEAD")
 if err != nil {
  log.Fatalf("Error getting local revision: %v", err)
 }
 remote, err := runGitCommand(repo, "rev-parse", "origin/HEAD")
 if err != nil {
  log.Fatalf("Error getting remote revision: %v", err)
 }
 base, err := runGitCommand(repo, "merge-base", "HEAD", "origin/HEAD")
 if err != nil {
  log.Fatalf("Error getting merge-base: %v", err)
 }

 if local == remote {
  fmt.Printf("The repository at %s is up to date.\n", repo)
 } else if local == base {
  fmt.Printf("The repository at %s needs to pull updates.\n", repo)
  _, err = runGitCommand(repo, "pull", "origin", "HEAD")
  if err != nil {
   log.Fatalf("Error pulling updates: %v", err)
  }
  fmt.Printf("Pulled updates for %s\n", repo)
 } else if remote == base {
  fmt.Printf("The repository at %s needs to push updates.\n", repo)
 } else {
  fmt.Printf("The repository at %s has diverged.\n", repo)
 }
}

func main() {
 // Get yesterday's date
 yesterday := time.Now().AddDate(0, 0, -1).Format("2006-01-02")

 // Directories to be processed
 directories := []string{
  filepath.Join(os.Getenv("HOME"), "Downloads"),
  filepath.Join(os.Getenv("HOME"), "Pictures"),
  filepath.Join(os.Getenv("HOME"), "Pictures", "Screenshots"),
  filepath.Join(os.Getenv("HOME"), "Desktop"),
 }

 // Repositories to be checked
 repos := []string{
  filepath.Join(os.Getenv("HOME"), "Documents", "notes"),
  filepath.Join(os.Getenv("HOME"), "projects", "victorgevers.com"),
  filepath.Join(os.Getenv("HOME"), "cookiemonster"),
 }

 // Process each directory
 for _, dir := range directories {
  moveFiles(dir, yesterday)
 }

 // Check each repository
 for _, repo := range repos {
  checkRepo(repo)
 }
}

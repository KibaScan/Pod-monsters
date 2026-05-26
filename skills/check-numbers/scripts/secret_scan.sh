#!/usr/bin/env bash

# Secret Scanner Pre-Push Git Hook
# Scans staged changes and unpushed commits for standard secret prefixes to prevent credentials leakage.

# Function to scan diff content for secret patterns
scan_diff() {
  local diff_content="$1"
  local source_label="$2"

  if [ -z "$diff_content" ]; then
    return 0
  fi

  # Filter only added lines (lines starting with '+' but not '+++')
  local added_lines
  added_lines=$(printf '%s\n' "$diff_content" | grep -E '^\+[^+]')

  if [ -n "$added_lines" ]; then
    # Perform case-insensitive search for secret patterns:
    # sk-, sb_secret, AIza, AKIA
    local matching_secrets
    matching_secrets=$(printf '%s\n' "$added_lines" | grep -E -i 'sk-|sb_secret|AIza|AKIA')

    if [ -n "$matching_secrets" ]; then
      echo "CRITICAL: Potential secrets detected in $source_label!"
      echo "$matching_secrets"
      return 1
    fi
  fi

  return 0
}

STAGED_SCAN_EXIT=0
UNPUSHED_SCAN_EXIT=0

# 1. Scan staged changes (git diff --cached)
staged_diff=$(git diff --cached --no-color 2>/dev/null)
scan_diff "$staged_diff" "staged changes"
STAGED_SCAN_EXIT=$?

# 2. Scan unpushed commits or local commits if no upstream exists
upstream_exists=false
if git rev-parse --verify @{u} >/dev/null 2>&1; then
  upstream_exists=true
fi

if [ "$upstream_exists" = true ]; then
  # Check if there are any unpushed commits
  unpushed_count=$(git rev-list --count @{u}..HEAD 2>/dev/null)
  if [ -n "$unpushed_count" ] && [ "$unpushed_count" -gt 0 ]; then
    unpushed_diff=$(git diff @{u}..HEAD --no-color 2>/dev/null)
    scan_diff "$unpushed_diff" "unpushed commits (@{u}..HEAD)"
    UNPUSHED_SCAN_EXIT=$?
  fi
else
  # No upstream exists. Check if HEAD has any commits
  if git rev-parse --verify HEAD >/dev/null 2>&1; then
    # If HEAD has at least one commit, scan already committed changes
    if git rev-parse --verify HEAD~1 >/dev/null 2>&1; then
      unpushed_diff=$(git diff HEAD~1..HEAD --no-color 2>/dev/null)
      scan_diff "$unpushed_diff" "committed changes (HEAD~1..HEAD)"
      UNPUSHED_SCAN_EXIT=$?
    else
      # Only one commit in history, diff-tree against the empty tree
      unpushed_diff=$(git diff-tree -p --no-commit-id HEAD --no-color 2>/dev/null)
      scan_diff "$unpushed_diff" "committed changes (initial commit)"
      UNPUSHED_SCAN_EXIT=$?
    fi
  fi
fi

# 3. Final evaluation
if [ "$STAGED_SCAN_EXIT" -ne 0 ] || [ "$UNPUSHED_SCAN_EXIT" -ne 0 ]; then
  echo "ERROR: Secret scan failed. Git operation blocked."
  exit 1
fi

echo "SUCCESS: No secrets found. Secret scan passed!"
exit 0

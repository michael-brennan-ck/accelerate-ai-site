#!/usr/bin/env bash
#
# deploy.sh -- Push an HTML file to the accelerate-ai-site GitHub Pages repo.
#
# Usage:
#   ./deploy.sh                  # deploys ./index.html
#   ./deploy.sh path/to/file.html
#
# Required:
#   DEPLOY_TOKEN  env var containing a GitHub personal access token (classic)
#                 with "repo" scope, OR a fine-grained token with Contents
#                 read/write permission on the target repo.
#
# Optional:
#   DEPLOY_REPO   override the target repo (default: michael-brennan-ck/accelerate-ai-site)
#   DEPLOY_BRANCH override the branch    (default: main)
#   SITE_URL      override the Pages URL (default: derived from repo)
#
set -euo pipefail

# ---------------------------------------------------------------------------
# Configuration (all overridable via env vars)
# ---------------------------------------------------------------------------
REPO="${DEPLOY_REPO:-michael-brennan-ck/accelerate-ai-site}"
BRANCH="${DEPLOY_BRANCH:-main}"

# Derive the GitHub Pages URL from the repo owner/name if not set explicitly
if [[ -z "${SITE_URL:-}" ]]; then
  OWNER="${REPO%%/*}"
  NAME="${REPO##*/}"
  SITE_URL="https://${OWNER}.github.io/${NAME}/"
fi

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------
cleanup() {
  if [[ -n "${TMPDIR_DEPLOY:-}" && -d "${TMPDIR_DEPLOY}" ]]; then
    rm -rf "${TMPDIR_DEPLOY}"
  fi
}
trap cleanup EXIT

die() {
  echo ""
  echo "ERROR: $1" >&2
  echo ""
  exit 1
}

info() {
  echo "  -> $1"
}

# ---------------------------------------------------------------------------
# Pre-flight checks
# ---------------------------------------------------------------------------
echo ""
echo "=== Accelerate AI Site Deploy ==="
echo ""

# 1. Token
if [[ -z "${DEPLOY_TOKEN:-}" ]]; then
  die "DEPLOY_TOKEN is not set.

  You need a GitHub personal access token to deploy.
  See README-DEPLOY.md for setup instructions, then run:

    export DEPLOY_TOKEN=\"ghp_your_token_here\"
    ./deploy.sh
"
fi

# 2. Git
if ! command -v git &>/dev/null; then
  die "git is not installed. Please install git first."
fi

# 3. HTML file
HTML_FILE="${1:-index.html}"

if [[ ! -f "${HTML_FILE}" ]]; then
  die "File not found: ${HTML_FILE}

  Usage: ./deploy.sh [path/to/file.html]
  If no path is given, it looks for index.html in the current directory."
fi

# Resolve to absolute path so it works after we cd into the temp dir
HTML_FILE="$(cd "$(dirname "${HTML_FILE}")" && pwd)/$(basename "${HTML_FILE}")"

echo "  File:   $(basename "${HTML_FILE}")"
echo "  Repo:   ${REPO}"
echo "  Branch: ${BRANCH}"
echo ""

# ---------------------------------------------------------------------------
# Clone, copy, commit, push
# ---------------------------------------------------------------------------
TMPDIR_DEPLOY="$(mktemp -d)"

info "Cloning repository..."
CLONE_URL="https://x-access-token:${DEPLOY_TOKEN}@github.com/${REPO}.git"
if ! git clone --quiet --depth 1 --branch "${BRANCH}" "${CLONE_URL}" "${TMPDIR_DEPLOY}/repo" 2>/dev/null; then
  die "Failed to clone the repository.

  Possible causes:
    - DEPLOY_TOKEN is invalid or expired
    - The repo ${REPO} does not exist or you lack access
    - Branch '${BRANCH}' does not exist

  Check your token and try again. See README-DEPLOY.md for help."
fi

info "Copying $(basename "${HTML_FILE}")..."
cp "${HTML_FILE}" "${TMPDIR_DEPLOY}/repo/index.html"

cd "${TMPDIR_DEPLOY}/repo"

# Check if there are actually changes
if git diff --quiet HEAD 2>/dev/null; then
  echo ""
  echo "  No changes detected -- the site is already up to date."
  echo "  Live at: ${SITE_URL}"
  echo ""
  exit 0
fi

info "Committing changes..."
git config user.email "deploy@accelerate-ai.local"
git config user.name "Accelerate AI Deploy"
git add index.html
TIMESTAMP="$(date '+%Y-%m-%d %H:%M:%S')"
git commit --quiet -m "Update site (${TIMESTAMP})"

info "Pushing to GitHub..."
if ! git push --quiet origin "${BRANCH}" 2>/dev/null; then
  die "Push failed.

  Possible causes:
    - DEPLOY_TOKEN lacks write permission on the repo
    - The branch is protected and requires a PR

  Check your token permissions and try again."
fi

# ---------------------------------------------------------------------------
# Done
# ---------------------------------------------------------------------------
echo ""
echo "  Deploy successful!"
echo ""
echo "  Your site will be live in 1-2 minutes at:"
echo ""
echo "    ${SITE_URL}"
echo ""

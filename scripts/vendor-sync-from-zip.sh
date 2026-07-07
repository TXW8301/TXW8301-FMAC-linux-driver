#!/usr/bin/env bash
set -euo pipefail

# Vendor drop sync helper for TXW8301-FMAC-linux-driver.
#
# Default behavior:
# - verifies clean working tree
# - fast-forwards main
# - extracts vendor zip to /tmp
# - rsync mirrors vendor content into repo with --delete (excluding .git)
# - prints pending changes for review
#
# Optional behavior:
# - create pre/post vendor tags
# - commit vendor sync
# - push main and tags
#
# Example:
#   ./scripts/vendor-sync-from-zip.sh \
#     --zip /home/csvke/TXW8301/Driver/taixin-fmac-linux-driver-v2.2.1-43002_20260707160403.zip \
#     --vendor-dir taixin-fmac-linux-driver-v2.2.1-43002 \
#     --pre-tag vendor-v2.2.1-41305 \
#     --post-tag vendor-v2.2.1-43002 \
#     --commit "vendor: sync taixin-fmac-linux-driver v2.2.1-43002" \
#     --push

usage() {
  cat <<'EOF'
Usage:
  vendor-sync-from-zip.sh --zip <path.zip> [options]

Required:
  --zip <path>            Absolute or relative path to vendor zip file.

Options:
  --vendor-dir <name>     Root directory name inside zip (auto-detected if omitted).
  --repo <path>           Repo path (default: current git repo root).
  --base-branch <name>    Base branch to sync (default: main).
  --pre-tag <name>        Tag current HEAD before vendor import.
  --post-tag <name>       Tag new HEAD after commit.
  --commit <message>      Commit message for vendor sync commit.
  --push                  Push base branch and tags after commit.
  --yes                   Skip confirmation prompt before rsync --delete.
  --help                  Show this help.

Notes:
- This script aborts if working tree is not clean.
- If --commit is not provided, the script stops after preparing changes.
EOF
}

require_cmd() {
  command -v "$1" >/dev/null 2>&1 || {
    echo "error: required command not found: $1" >&2
    exit 1
  }
}

ZIP_PATH=""
VENDOR_DIR=""
REPO_PATH=""
BASE_BRANCH="main"
PRE_TAG=""
POST_TAG=""
COMMIT_MSG=""
DO_PUSH=0
ASSUME_YES=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --zip)
      ZIP_PATH="${2:-}"
      shift 2
      ;;
    --vendor-dir)
      VENDOR_DIR="${2:-}"
      shift 2
      ;;
    --repo)
      REPO_PATH="${2:-}"
      shift 2
      ;;
    --base-branch)
      BASE_BRANCH="${2:-}"
      shift 2
      ;;
    --pre-tag)
      PRE_TAG="${2:-}"
      shift 2
      ;;
    --post-tag)
      POST_TAG="${2:-}"
      shift 2
      ;;
    --commit)
      COMMIT_MSG="${2:-}"
      shift 2
      ;;
    --push)
      DO_PUSH=1
      shift
      ;;
    --yes)
      ASSUME_YES=1
      shift
      ;;
    --help|-h)
      usage
      exit 0
      ;;
    *)
      echo "error: unknown argument: $1" >&2
      usage
      exit 1
      ;;
  esac
done

if [[ -z "$ZIP_PATH" ]]; then
  echo "error: --zip is required" >&2
  usage
  exit 1
fi

require_cmd git
require_cmd unzip
require_cmd rsync

if [[ -z "$REPO_PATH" ]]; then
  REPO_PATH="$(git rev-parse --show-toplevel)"
fi

if [[ ! -f "$ZIP_PATH" ]]; then
  echo "error: zip not found: $ZIP_PATH" >&2
  exit 1
fi

cd "$REPO_PATH"

if [[ -n "$(git status --porcelain)" ]]; then
  echo "error: working tree is not clean. Commit/stash first." >&2
  git status --short --branch
  exit 1
fi

current_branch="$(git branch --show-current)"
if [[ "$current_branch" != "$BASE_BRANCH" ]]; then
  echo "info: switching to $BASE_BRANCH"
  git switch "$BASE_BRANCH"
fi

echo "info: fetching and fast-forwarding $BASE_BRANCH"
git fetch origin
git pull --ff-only origin "$BASE_BRANCH"

if [[ -n "$PRE_TAG" ]]; then
  if git rev-parse -q --verify "refs/tags/$PRE_TAG" >/dev/null; then
    echo "error: pre-tag already exists: $PRE_TAG" >&2
    exit 1
  fi
  git tag -a "$PRE_TAG" -m "Vendor baseline before sync: $PRE_TAG"
  echo "info: created pre-tag: $PRE_TAG"
fi

if [[ -z "$VENDOR_DIR" ]]; then
  VENDOR_DIR="$(unzip -Z1 "$ZIP_PATH" | head -n 1 | cut -d/ -f1)"
  if [[ -z "$VENDOR_DIR" ]]; then
    echo "error: could not detect vendor directory from zip" >&2
    exit 1
  fi
fi

extract_root="/tmp/vendor-sync-$USER-$$"
mkdir -p "$extract_root"
trap 'rm -rf "$extract_root"' EXIT

echo "info: extracting zip into $extract_root"
unzip -q "$ZIP_PATH" -d "$extract_root"

src_dir="$extract_root/$VENDOR_DIR"
if [[ ! -d "$src_dir" ]]; then
  echo "error: vendor dir not found after extraction: $src_dir" >&2
  echo "hint: pass --vendor-dir <top-level-dir-inside-zip>" >&2
  exit 1
fi

echo "about to mirror vendor content into repo with rsync --delete"
echo "  source: $src_dir/"
echo "  target: $REPO_PATH/"
if [[ "$ASSUME_YES" -ne 1 ]]; then
  read -r -p "continue? [y/N] " reply
  case "$reply" in
    y|Y|yes|YES) ;;
    *)
      echo "aborted"
      exit 1
      ;;
  esac
fi

rsync -a --delete --exclude=.git "$src_dir/" "$REPO_PATH/"

echo
echo "info: vendor mirror staged in working tree. pending status:"
git status --short --branch

if [[ -z "$COMMIT_MSG" ]]; then
  echo
  echo "done: review changes, then commit manually if desired."
  echo "hint: git add -A && git commit -m \"vendor: sync ...\""
  exit 0
fi

git add -A
git commit -m "$COMMIT_MSG"
echo "info: committed vendor sync"

if [[ -n "$POST_TAG" ]]; then
  if git rev-parse -q --verify "refs/tags/$POST_TAG" >/dev/null; then
    echo "error: post-tag already exists: $POST_TAG" >&2
    exit 1
  fi
  git tag -a "$POST_TAG" -m "Vendor baseline after sync: $POST_TAG"
  echo "info: created post-tag: $POST_TAG"
fi

if [[ "$DO_PUSH" -eq 1 ]]; then
  git push origin "$BASE_BRANCH" --tags
  echo "info: pushed $BASE_BRANCH and tags"
fi

echo "done"

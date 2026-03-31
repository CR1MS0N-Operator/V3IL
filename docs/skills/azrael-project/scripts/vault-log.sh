#!/usr/bin/env bash
# vault-log.sh — Write project completion note to azrael-vault
#
# Usage:
#   vault-log.sh <project-name> <date> <summary> <category> <repo-name> [related-projects...]
#
# Arguments:
#   project-name      Kebab-case project identifier (e.g. rss-digest-bot)
#   date              ISO 8601 date (e.g. 2026-03-30)
#   summary           One-paragraph summary of what was built and key decisions
#   category          Tag category (e.g. tooling, web, cli, library)
#   repo-name         Git repo name for [[wikilink]] (e.g. rss-digest-bot)
#   related-projects  Optional: space-separated repo/project names for wikilinks
#
# Environment:
#   VAULT_PATH        Override vault root (default: ~/Documents/azrael-vault)

set -euo pipefail

# ── Argument validation ───────────────────────────────────────────────────────

if [[ $# -lt 5 ]]; then
    echo "vault-log.sh: error: requires at least 5 arguments" >&2
    echo "Usage: vault-log.sh <project-name> <date> <summary> <category> <repo-name> [related-projects...]" >&2
    exit 1
fi

PROJECT_NAME="$1"
DATE="$2"
SUMMARY="$3"
CATEGORY="$4"
REPO_NAME="$5"
shift 5
RELATED_PROJECTS=("$@")

# ── Vault path resolution ─────────────────────────────────────────────────────

VAULT_PATH="${VAULT_PATH:-$HOME/Documents/azrael-vault}"

if [[ ! -d "$VAULT_PATH" ]]; then
    echo "vault-log.sh: warn: vault path not found: $VAULT_PATH — skipping note write" >&2
    exit 0
fi

# ── Build related wikilinks block ─────────────────────────────────────────────

RELATED_LINKS=""
if [[ ${#RELATED_PROJECTS[@]} -gt 0 ]]; then
    RELATED_LINKS="## Related Projects\n\n"
    for proj in "${RELATED_PROJECTS[@]}"; do
        RELATED_LINKS+="- [[$proj]]\n"
    done
    RELATED_LINKS+="\n"
fi

# ── Build note content ────────────────────────────────────────────────────────

NOTE_CONTENT="---
type: project-log
date: ${DATE}
tags:
  - project
  - claude-code
  - ${CATEGORY}
---

# ${PROJECT_NAME}

## What Was Built

${SUMMARY}

## Repo

[[$REPO_NAME]]

${RELATED_LINKS}## Related Skill

[[azrael-project-skill]]
"

# ── Write via obsidian CLI or direct file fallback ────────────────────────────

TARGET_DIR="${VAULT_PATH}/20-Projects"
TARGET_FILE="${TARGET_DIR}/${PROJECT_NAME}.md"

if command -v obsidian &>/dev/null; then
    # Attempt obsidian CLI path
    if obsidian create --path "20-Projects/${PROJECT_NAME}.md" --content "$NOTE_CONTENT" 2>/dev/null; then
        echo "vault-log.sh: wrote note via obsidian CLI: 20-Projects/${PROJECT_NAME}.md"
        exit 0
    else
        echo "vault-log.sh: warn: obsidian CLI failed — falling back to direct file write" >&2
    fi
fi

# Direct file write fallback
if [[ ! -d "$TARGET_DIR" ]]; then
    echo "vault-log.sh: warn: target directory does not exist: $TARGET_DIR — skipping" >&2
    exit 0
fi

if [[ -f "$TARGET_FILE" ]]; then
    echo "vault-log.sh: warn: note already exists at $TARGET_FILE — appending separator" >&2
    printf "\n---\n\n%s" "$NOTE_CONTENT" >> "$TARGET_FILE"
else
    printf "%s" "$NOTE_CONTENT" > "$TARGET_FILE"
fi

echo "vault-log.sh: wrote note: $TARGET_FILE"

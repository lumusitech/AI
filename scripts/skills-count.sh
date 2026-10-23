#!/usr/bin/env bash
# Print the current skill totals so the README never needs hardcoded counts
# (hardcoded counts caused repeated merge conflicts on every skill addition).
#
# Usage: ./scripts/skills-count.sh
set -euo pipefail

SKILLS_DIR="$(cd "$(dirname "$0")/.." && pwd)/skills"

total=$(find "$SKILLS_DIR" -mindepth 2 -maxdepth 2 -name SKILL.md | wc -l | tr -d ' ')

echo "Total skills: ${total}"
echo ""
echo "Skills:"
find "$SKILLS_DIR" -mindepth 2 -maxdepth 2 -name SKILL.md \
  | sed "s#${SKILLS_DIR}/##; s#/SKILL.md##" \
  | sort

#!/usr/bin/env bash
# Structural smoke contract for quant-research: manifest fields, every
# skill has a SKILL.md with name + description frontmatter, agent and
# command files exist with frontmatter.
set -euo pipefail
PLUGIN_DIR="$(cd "$(dirname "$0")/.." && pwd)"
fail() { echo "FAIL: $*"; exit 1; }

node -e '
  const m = JSON.parse(require("fs").readFileSync(process.argv[1], "utf8"));
  for (const k of ["name", "description", "version"]) if (!m[k]) throw new Error("manifest missing " + k);
  if (!m.author || !m.author.name) throw new Error("manifest missing author.name");
' "$PLUGIN_DIR/.claude-plugin/plugin.json" || fail "plugin.json"

has_frontmatter() {
  local f="$1"
  [ -f "$f" ] || fail "missing $f"
  head -1 "$f" | grep -q '^---$' || fail "no frontmatter in $f"
  grep -q '^name: ' "$f" || fail "no name in $f"
  grep -q '^description: ' "$f" || fail "no description in $f"
}

for skill in regression-diagnostics panel-data event-study results-writeup; do
  has_frontmatter "$PLUGIN_DIR/skills/$skill/SKILL.md"
done
has_frontmatter "$PLUGIN_DIR/agents/econometrician.md"
has_frontmatter "$PLUGIN_DIR/commands/quant.md"

echo "quant-research smoke: OK"

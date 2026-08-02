#!/usr/bin/env bash

# ==============================================================================
# Lumusitech AI Workspace - Machine Setup Script
# ==============================================================================
# Idempotent setup script to link custom skills, MCP configurations, and global
# agent directives for OpenCode and Antigravity (TUI / IDE) across machines.
# ==============================================================================

set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
echo "🚀 Initializing AI Workspace Setup from: ${REPO_DIR}"

# 1. Environment & Credentials Setup
if [ ! -f "${REPO_DIR}/.env" ]; then
    echo "⚠️  .env file missing. Creating from .env.template..."
    cp "${REPO_DIR}/.env.template" "${REPO_DIR}/.env"
    echo "🔑 Please edit ${REPO_DIR}/.env with your actual tokens (e.g., GITHUB_TOKEN)."
else
    echo "✅ .env configuration file exists."
fi

# Load variables if .env exists
if [ -f "${REPO_DIR}/.env" ]; then
    set -a
    # shellcheck disable=SC1091
    source "${REPO_DIR}/.env" || true
    set +a
fi

# 2. Antigravity Configuration Links (~/.gemini/config)
GEMINI_CONFIG_DIR="${HOME}/.gemini/config"
mkdir -p "${GEMINI_CONFIG_DIR}"

echo "🔗 Linking skills to Antigravity global config (${GEMINI_CONFIG_DIR}/skills)..."
ln -sfn "${REPO_DIR}/skills" "${GEMINI_CONFIG_DIR}/skills"

echo "🔗 Linking mcp.json to Antigravity global config (${GEMINI_CONFIG_DIR}/mcp.json)..."
ln -sfn "${REPO_DIR}/mcp.json" "${GEMINI_CONFIG_DIR}/mcp.json"

# Remove legacy hardcoded backup tokens if existing
if [ -f "${GEMINI_CONFIG_DIR}/mcp_config.json.backup" ]; then
    rm -f "${GEMINI_CONFIG_DIR}/mcp_config.json.backup"
fi

# 3. OpenCode Configuration Links (~/.config/opencode)
OPENCODE_CONFIG_DIR="${HOME}/.config/opencode"
mkdir -p "${OPENCODE_CONFIG_DIR}"

echo "🔗 Linking opencode.jsonc to OpenCode config (${OPENCODE_CONFIG_DIR}/opencode.jsonc)..."
ln -sfn "${REPO_DIR}/opencode.jsonc" "${OPENCODE_CONFIG_DIR}/opencode.jsonc"

echo "🔗 Linking AGENTS.md to OpenCode config (${OPENCODE_CONFIG_DIR}/AGENTS.md)..."
ln -sfn "${REPO_DIR}/AGENTS.md" "${OPENCODE_CONFIG_DIR}/AGENTS.md"

# 4. Clean up legacy skill & temporary directories to prevent duplicate loading & save space
echo "🧹 Cleaning legacy paths (~/.agents, ~/.claude, ~/temp/antigravity-awesome-skills)..."
rm -rf "${HOME}/.agents"
rm -rf "${HOME}/.claude"
rm -rf "${HOME}/temp/antigravity-awesome-skills"

# 5. MCP package availability check
echo "🔎 Verifying MCP npm packages..."
MCP_PACKAGES=(
  "@astudioplus/codegraph-mcp"
  "@upstash/context7-mcp"
  "@modelcontextprotocol/server-github"
  "@modelcontextprotocol/server-memory"
  "@playwright/mcp"
)
MCP_OK=0
MCP_FAIL=0
for pkg in "${MCP_PACKAGES[@]}"; do
  if npm view "${pkg}" version >/dev/null 2>&1; then
    echo "  ✅ OK    ${pkg}"
    MCP_OK=$((MCP_OK + 1))
  else
    echo "  ❌ FAIL  ${pkg} (not found in npm registry)"
    MCP_FAIL=$((MCP_FAIL + 1))
  fi
done
if [ "${MCP_FAIL}" -gt 0 ]; then
  echo "⚠️  ${MCP_FAIL} MCP package(s) missing. Check your npm registry access."
fi

# 6. Summary & Verification
SKILL_COUNT=$(ls -d "${REPO_DIR}/skills"/*/ 2>/dev/null | wc -l || echo "0")

echo ""
echo "======================================================================"
echo "🎉 Setup Complete!"
echo "----------------------------------------------------------------------"
echo "  • Total Curated Skills: ${SKILL_COUNT}"
echo "  • MCP Packages OK/FAIL: ${MCP_OK}/${MCP_FAIL}"
echo "  • OpenCode Config:      ${OPENCODE_CONFIG_DIR}/opencode.jsonc"
echo "  • OpenCode Directives:  ${OPENCODE_CONFIG_DIR}/AGENTS.md"
echo "  • Antigravity Skills:   ${GEMINI_CONFIG_DIR}/skills"
echo "  • Antigravity MCPs:     ${GEMINI_CONFIG_DIR}/mcp.json"
echo "  • MCPs Configured:      context7, codegraph, github, memory, playwright"
echo "======================================================================"

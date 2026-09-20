#!/usr/bin/env node
/**
 * GitHub MCP auth bridge.
 *
 * Resolves the GitHub PAT from `gh auth token` (keyring / OAuth) and spawns
 * the real `mcp-server-github` with `GITHUB_PERSONAL_ACCESS_TOKEN` set.
 *
 * Priority:
 *   1. Existing GITHUB_PERSONAL_ACCESS_TOKEN or GITHUB_TOKEN in the environment
 *      (explicit override — e.g. from a .env with a real PAT).
 *   2. `gh auth token` from the CLI keyring (OAuth login).
 *
 * This avoids storing tokens in .env and lets the MCP server piggyback on
 * `gh`'s authentication without requiring a separate PAT.
 */
import { spawn } from "node:child_process"
import { execFileSync } from "node:child_process"
import { resolve } from "node:path"

// --- Resolve token -----------------------------------------------------------

function resolveToken() {
  // 1. Explicit env override (already set by caller or .env).
  const explicit =
    process.env.GITHUB_PERSONAL_ACCESS_TOKEN || process.env.GITHUB_TOKEN
  if (explicit && explicit.length > 10) return explicit

  // 2. Ask gh CLI for the token from its keyring / OAuth flow.
  try {
    const token = execFileSync("gh", ["auth", "token"], {
      stdio: ["pipe", "pipe", "pipe"],
      timeout: 5_000,
      windowsHide: true,
    })
      .toString()
      .trim()
    if (token.length > 10) return token
  } catch {
    // gh not installed or not logged in — fall through.
  }

  return undefined
}

const token = resolveToken()

// --- Spawn the real MCP server -----------------------------------------------

// Resolve the real binary. On Windows the shim is mcp-server-github.cmd;
// on Unix it's mcp-server-github (or mcp-server-github.js).
function findServerBin() {
  const candidates =
    process.platform === "win32"
      ? ["mcp-server-github.cmd", "mcp-server-github.exe"]
      : ["mcp-server-github"]

  for (const name of candidates) {
    try {
      // `which` on Unix, `where` on Windows.
      const cmd = process.platform === "win32" ? "where" : "which"
      const result = execFileSync(cmd, [name], {
        stdio: ["pipe", "pipe", "pipe"],
        timeout: 3_000,
        windowsHide: true,
      })
        .toString()
        .trim()
        .split("\n")[0]
      if (result) return result
    } catch {
      // Not found via PATH; continue.
    }
  }

  // Fallback: rely on PATH resolution by the OS (spawn will throw if missing).
  return process.platform === "win32" ? "mcp-server-github.cmd" : "mcp-server-github"
}

const serverBin = findServerBin()

// Build env: copy parent env, inject token if resolved, strip placeholders.
const childEnv = { ...process.env }

if (token) {
  childEnv.GITHUB_PERSONAL_ACCESS_TOKEN = token
  // Also set GITHUB_TOKEN so the server sees it everywhere.
  childEnv.GITHUB_TOKEN = token
} else {
  // No token found — let the server fail with its own error message.
  delete childEnv.GITHUB_PERSONAL_ACCESS_TOKEN
  delete childEnv.GITHUB_TOKEN
}

// Remove GH_TOKEN to avoid confusion (gh uses keyring, not env, for `gh auth token`).
delete childEnv.GH_TOKEN

// Pass through args (usually none — the MCP server reads from stdio).
const args = process.argv.slice(2)

const child = spawn(serverBin, args, {
  stdio: "inherit",
  env: childEnv,
  shell: process.platform === "win32",
})

child.on("error", (err) => {
  console.error(`[github-mcp-bridge] Failed to start ${serverBin}:`, err.message)
  process.exit(1)
})

child.on("exit", (code) => {
  process.exit(code ?? 0)
})

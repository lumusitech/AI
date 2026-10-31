#!/usr/bin/env node
/**
 * GitHub MCP auth bridge.
 *
 * Resolves the GitHub PAT from `gh auth token` (keyring / OAuth) and spawns
 * the real `mcp-server-github` with `GITHUB_PERSONAL_ACCESS_TOKEN` set.
 *
 * Priority:
 *   1. GITHUB_MCP_TOKEN in the environment (explicit opt-in override).
 *   2. `gh auth token` from the CLI keyring (OAuth login).
 *   3. GITHUB_PERSONAL_ACCESS_TOKEN or GITHUB_TOKEN from the environment
 *      (e.g. a PAT stored in .env on machines without gh).
 *
 * The keyring comes before the environment on purpose: a stale PAT exported by
 * `.env` used to shadow a perfectly valid `gh` login and every MCP call failed
 * with "Bad credentials", even though the server itself started fine.
 */
import { spawn } from "node:child_process"
import { execFileSync } from "node:child_process"
import { resolve } from "node:path"

// --- Resolve token -----------------------------------------------------------

function isUsableToken(value) {
  // Reject empty values, unresolved placeholders (${GITHUB_TOKEN}) and
  // obviously truncated secrets.
  if (!value) return false
  const token = value.trim()
  if (token.length <= 10) return false
  if (token.includes("${") || token.toLowerCase().includes("your_")) return false
  return true
}

function resolveToken() {
  // 1. Explicit override for this bridge only.
  if (isUsableToken(process.env.GITHUB_MCP_TOKEN)) {
    return process.env.GITHUB_MCP_TOKEN.trim()
  }

  // 2. Ask gh CLI for the token from its keyring / OAuth flow. This is the
  //    token gh itself validated, so it is the most trustworthy source.
  //    The env is sanitized because gh prefers GITHUB_TOKEN/GH_TOKEN over the
  //    keyring: a stale PAT inherited from .env would make `gh auth token` fail
  //    with the very error we are trying to avoid.
  const ghEnv = { ...process.env }
  delete ghEnv.GITHUB_TOKEN
  delete ghEnv.GH_TOKEN
  delete ghEnv.GITHUB_PERSONAL_ACCESS_TOKEN
  try {
    const token = execFileSync("gh", ["auth", "token"], {
      stdio: ["pipe", "pipe", "pipe"],
      timeout: 5_000,
      windowsHide: true,
      env: ghEnv,
    })
      .toString()
      .trim()
    if (isUsableToken(token)) return token
  } catch {
    // gh not installed or not logged in — fall through.
  }

  // 3. Fall back to an explicit PAT from the environment.
  const fromEnv =
    process.env.GITHUB_PERSONAL_ACCESS_TOKEN || process.env.GITHUB_TOKEN
  if (isUsableToken(fromEnv)) return fromEnv.trim()

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

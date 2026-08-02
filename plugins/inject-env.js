/**
 * Environment injection plugin.
 *
 * Loads variables from ~/.agent/.env (if present) and injects them into every
 * shell and tool execution, so the agent has access to the same credentials
 * the user has in their terminal.
 */
import { existsSync, readFileSync } from "node:fs"
import { homedir } from "node:os"
import { join } from "node:path"

const envPath = join(homedir(), ".agent", ".env")

function loadDotEnv() {
  const result = {}
  if (!existsSync(envPath)) return result
  const lines = readFileSync(envPath, "utf8").split("\n")
  for (const rawLine of lines) {
    const line = rawLine.trim()
    if (!line || line.startsWith("#")) continue
    const eq = line.indexOf("=")
    if (eq === -1) continue
    const key = line.slice(0, eq).trim()
    const value = line.slice(eq + 1).trim().replace(/^["']|["']$/g, "")
    if (key) result[key] = value
  }
  return result
}

export const InjectEnvPlugin = async () => {
  const env = loadDotEnv()
  return {
    "shell.env": async (_input, output) => {
      Object.assign(output.env, env)
    },
  }
}

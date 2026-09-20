/**
 * Environment injection plugin (OpenCode V2 API).
 *
 * Loads variables from ~/.agent/.env (if present) and injects them into every
 * shell execution, so the agent has access to the same credentials
 * the user has in their terminal.
 *
 * V2: exports { id, setup } via module.exports for maximum loader compatibility.
 *     Registers ctx.shell.hook("create.before", ...) mutating event.env.
 *     (see https://opencode.ai/v2/docs/build/plugins/migrate-v1/).
 *
 * Only node: builtins are imported (offline-safe, no node_modules needed).
 */
const { existsSync, readFileSync } = require("node:fs")
const { homedir } = require("node:os")
const { join } = require("node:path")

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

module.exports = {
  id: "lumus.inject-env",
  async setup(ctx) {
    const env = loadDotEnv()
    if (Object.keys(env).length === 0) return
    await ctx.shell.hook("create.before", (event) => {
      Object.assign(event.env, env)
    })
  },
}

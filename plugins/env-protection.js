/**
 * Environment protection plugin (OpenCode V2 API).
 *
 * Blocks OpenCode from reading or exposing sensitive `.env` files through the
 * read/write tools, reducing the risk of leaking credentials to the model or
 * committing secrets. Also blocks `export VAR=...` assignments in bash,
 * `$env:VAR=...` assignments in PowerShell, and `setx` commands (but allows
 * commands that merely reference the word "export", e.g. grep/search).
 *
 * V1: exported a named function returning { "tool.execute.before": (input, output) => ... }.
 * V2: default-export { id, setup } and register ctx.tool.hook("execute.before", ...),
 *     reading the tool name from event.tool and args from event.input
 *     (see https://opencode.ai/v2/docs/build/plugins/migrate-v1/).
 *
 * NOTE: self-contained on purpose. It never shells out to
 * hooks/env-protection.ps1 (or any .ps1), so it cannot flash PowerShell
 * popups or hit UTF-8 decoding errors in the hook host. It also imports
 * nothing except the loader-provided ctx (offline-safe, no node_modules needed).
 */
export default {
  id: "lumus.env-protection",
  async setup(ctx) {
    await ctx.tool.hook("execute.before", (event) => {
      const input = event.input ?? {}
      const tool = event.tool ?? ""

      if (tool === "read" || tool === "edit" || tool === "write") {
        const candidates = [
          input.filePath,
          input.path,
          input.file,
          input.filename,
          input.uri,
          input.target,
        ]
        for (const candidate of candidates) {
          if (typeof candidate === "string" && candidate.length > 0) {
            const blocked = candidate
              .split(/[\\/]/)
              .some((segment) => segment === ".env" || segment.startsWith(".env."))
            if (blocked) {
              throw new Error("Access to .env files is blocked by the env-protection plugin.")
            }
          }
        }
      }

      if (tool === "bash" || tool === "shell" || tool === "exec" || tool === "command") {
        const command = input.command ?? input.cmd ?? input.script ?? input.code ?? ""
        if (typeof command === "string" && command.length > 0) {
          if (/\bexport\s+[A-Za-z_][A-Za-z0-9_]*\s*=/.test(command)) {
            throw new Error("The export command is blocked by the env-protection plugin.")
          }
          if (/\$env:[A-Za-z_][A-Za-z0-9_]*\s*=/.test(command)) {
            throw new Error("The $env: assignment is blocked by the env-protection plugin.")
          }
          if (/\bsetx\s+[A-Za-z_][A-Za-z0-9_]*\s*(\s\S|$)/i.test(command)) {
            throw new Error("The setx command is blocked by the env-protection plugin.")
          }
        }
      }
    })
  },
}

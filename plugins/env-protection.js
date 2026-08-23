/**
 * Environment protection plugin.
 *
 * Blocks OpenCode from reading or exposing sensitive `.env` files through the
 * read/write tools, reducing the risk of leaking credentials to the model or
 * committing secrets. Also blocks `export VAR=...` assignments in bash,
 * `$env:VAR=...` assignments in PowerShell, and `setx` commands (but allows
 * commands that merely reference the word "export", e.g. grep/search).
 */
export const EnvProtectionPlugin = async () => {
  return {
    "tool.execute.before": async (input, output) => {
      if (input.tool === "read" || input.tool === "edit" || input.tool === "write") {
        const filePath = output.args?.filePath ?? output.args?.path ?? "";
        if (typeof filePath === "string" && filePath.split(/[\\/]/).includes(".env")) {
          throw new Error("Access to .env files is blocked by the env-protection plugin.")
        }
      }
      if (input.tool === "bash") {
        const command = output.args?.command ?? "";
        if (typeof command === "string") {
          if (/\bexport\s+[A-Za-z_][A-Za-z0-9_]*\s*=/.test(command)) {
            throw new Error("The export command is blocked by the env-protection plugin.")
          }
          if (/\$env:[A-Za-z_][A-Za-z0-9_]*\s*=/.test(command)) {
            throw new Error("The $env: assignment is blocked by the env-protection plugin.")
          }
          if (/\bsetx\s+[A-Za-z_][A-Za-z0-9_]*\s*(\s\S|$)/.test(command)) {
            throw new Error("The setx command is blocked by the env-protection plugin.")
          }
        }
      }
    },
  }
}

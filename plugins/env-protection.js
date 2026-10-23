/**
 * Environment / credential protection plugin (OpenCode V2 API).
 *
 * Blocks OpenCode from reading, writing or editing sensitive files through the
 * file tools, and blocks destructive shell commands. This reduces the risk of
 * leaking credentials to the model, committing secrets, or running an
 * irreversible delete.
 *
 * Ported (and self-contained) from gentle-ai's security permission deny-list:
 *   - secret/key files: .env*, *.pem, *.key, .netrc
 *   - secret dirs:      .ssh, .credentials, .gnupg, secrets, keychains
 *   - known spots:      .aws/credentials, .config/gh/hosts.yml
 *   - destructive:      rm -rf /  and  rm -rf ~  (with or without sudo)
 *   - shell assignments: `export VAR=`, `$env:VAR=`, `setx`
 *
 * V2: exports { id, setup } via module.exports for maximum loader compatibility.
 *     Registers ctx.tool.hook("execute.before", ...) reading the tool name from
 *     event.tool and args from event.input.
 *     (see https://opencode.ai/v2/docs/build/plugins/migrate-v1/).
 *
 * NOTE: self-contained on purpose. It never shells out to any .ps1, so it cannot
 * flash PowerShell popups or hit UTF-8 decoding errors in the hook host. It also
 * imports nothing (offline-safe, no node_modules needed).
 */

const SECRET_DIR_SEGMENTS = new Set([
  ".ssh",
  ".credentials",
  ".gnupg",
  "secrets",
  "keychains",
])

const SECRET_EXTENSIONS = [".pem", ".key"]

function basename(p) {
  const parts = p.split(/[\\/]/)
  return (parts[parts.length - 1] || "").toLowerCase()
}

function segments(p) {
  return p.split(/[\\/]/).map((s) => s.toLowerCase())
}

/** True when a path points at a secret/credential file the model must not touch. */
function isSensitivePath(rawPath) {
  if (typeof rawPath !== "string" || rawPath.length === 0) return false
  const p = rawPath.toLowerCase()
  const base = basename(p)
  const segs = segments(p)

  // Secret directories anywhere in the path.
  if (segs.some((s) => SECRET_DIR_SEGMENTS.has(s))) return true

  // .env and friends.
  if (base === ".env" || base.startsWith(".env.")) return true

  // Private keys / certificates.
  if (SECRET_EXTENSIONS.some((ext) => base.endsWith(ext))) return true

  // .netrc
  if (base === ".netrc") return true

  // Known credential spots.
  if (segs.includes(".aws") && base === "credentials") return true
  if (segs.includes(".config") && segs.includes("gh") && base === "hosts.yml") return true

  return false
}

/** True when the command is a recursive+force `rm` aimed at `/` or `~`. */
function isDestructiveRm(command) {
  const m = command.match(/\brm\b([^\n;|&]*)/i)
  if (!m) return false
  const rest = m[1]
  const recursive = /(^|\s)-[A-Za-z]*[rR][A-Za-z]*(\s|$)/.test(rest)
  const force = /(^|\s)-[A-Za-z]*f[A-Za-z]*(\s|$)/.test(rest)
  if (!(recursive && force)) return false
  // Target is `/`, `~` or `$HOME` (optionally with `/*` or `~/`), not a subpath.
  return /(^|\s)(\/\*?|~\/?\*?|\$HOME\/?\*?)(\s|$)/.test(rest)
}

module.exports = {
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
          if (isSensitivePath(candidate)) {
            throw new Error(
              "Access to a sensitive file (.env, key, credential) is blocked by the env-protection plugin.",
            )
          }
        }
      }

      if (tool === "bash" || tool === "shell" || tool === "exec" || tool === "command") {
        const command = input.command ?? input.cmd ?? input.script ?? input.code ?? ""
        if (typeof command === "string" && command.length > 0) {
          if (isDestructiveRm(command)) {
            throw new Error("Destructive `rm -rf /` or `rm -rf ~` is blocked by the env-protection plugin.")
          }
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

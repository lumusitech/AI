/**
 * Session notifications plugin (OpenCode V2 API).
 *
 * Sends a native desktop notification when a session goes idle,
 * so you know when a background task has finished.
 *
 * V2: exports { id, setup } via module.exports for maximum loader compatibility.
 *     Subscribes via ctx.event.subscribe(), aborting the stream in the cleanup
 *     function returned by setup.
 *     (see https://opencode.ai/v2/docs/build/plugins/migrate-v1/).
 *
 * NOTE: self-contained on purpose. It never shells out to hooks/notify.ps1.
 * On Windows it only notifies via BurntToast when that module is installed,
 * spawned with windowsHide so no console window flashes. All failures are
 * swallowed: notifications are best-effort and must never crash the agent.
 * No external imports (offline-safe, no node_modules needed).
 */
const TITLE = "OpenCode session finished"
const MESSAGE = "Your OpenCode session is idle."

function notifyBestEffort() {
  try {
    const platform = process.platform
    if (platform === "darwin") {
      const { execFileSync } = require("node:child_process")
      try {
        execFileSync("osascript", ["-e", `display notification "${MESSAGE}" with title "${TITLE}"`], {
          stdio: "pipe",
        })
      } catch {
        // Best-effort only.
      }
    } else if (platform === "linux" && process.env.DISPLAY) {
      const { execFileSync } = require("node:child_process")
      try {
        execFileSync("notify-send", [TITLE, MESSAGE], { stdio: "pipe" })
      } catch {
        // Best-effort only.
      }
    } else if (platform === "win32") {
      const { execFileSync } = require("node:child_process")
      try {
        execFileSync(
          "pwsh",
          [
            "-NoProfile",
            "-NonInteractive",
            "-Command",
            `if (Get-Module -ListAvailable -Name BurntToast) { Import-Module BurntToast; New-BurntToastNotification -Text '${TITLE}', '${MESSAGE}' }`,
          ],
          { stdio: "pipe", windowsHide: true },
        )
      } catch {
        // Best-effort only.
      }
    }
  } catch {
    // Best-effort only.
  }
}

module.exports = {
  id: "lumus.notifications",
  setup(ctx) {
    const controller = new AbortController()
    void (async () => {
      try {
        for await (const event of ctx.event.subscribe({ signal: controller.signal })) {
          if (event != null && event.type === "session.idle") {
            notifyBestEffort()
          }
        }
      } catch {
        // Aborted on unload; ignore.
      }
    })()
    return () => controller.abort()
  },
}

/**
 * Session notifications plugin.
 *
 * Sends a native desktop notification when a long-running session goes idle,
 * so you know when a background task has finished.
 */
export const NotificationsPlugin = async () => {
  return {
    event: async ({ event }) => {
      if (event.type === "session.idle") {
        const platform = process.platform
        const title = "OpenCode session finished"
        const message = "Your OpenCode session is idle."
        try {
          if (platform === "darwin") {
            const { execSync } = await import("node:child_process")
            execSync(`osascript -e 'display notification "${message}" with title "${title}"'`)
          } else if (platform === "linux" && process.env.DISPLAY) {
            const { execSync } = await import("node:child_process")
            execSync(`notify-send "${title}" "${message}"`)
          }
        } catch {
          // Notifications are best-effort; never crash the agent.
        }
      }
    },
  }
}

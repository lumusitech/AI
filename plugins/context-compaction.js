/**
 * Context compaction plugin (OpenCode V2 API).
 *
 * Injects a persistence checklist into the compaction request so that state
 * survives long sessions: current task, files in play, decisions, and blockers.
 *
 * V2: exports { id, setup } via module.exports for maximum loader compatibility.
 *     Registers ctx.session.hook("compaction", ...) pushing to event.system.
 *     (see https://opencode.ai/v2/docs/build/plugins/migrate-v1/).
 *
 * NOTE: intentionally no `import { Plugin } from "@opencode/plugin"`.
 * Plugin.define() is only a type-checking identity helper; the loader decodes
 * the plain { id, setup } object directly, and local plugins have no
 * node_modules to resolve the package from (offline-safe).
 */
module.exports = {
  id: "lumus.context-compaction",
  async setup(ctx) {
    await ctx.session.hook("compaction", (event) => {
      event.system.push({
        type: "text",
        text: `## Persisted session state

When summarizing, preserve the following explicitly:
1. The current task and its status.
2. Files being actively modified and by whom.
3. Key decisions made and their rationale.
4. Any blockers or open questions.
5. The next steps to continue the work.
`,
      })
    })
  },
}

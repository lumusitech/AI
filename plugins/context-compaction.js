/**
 * Context compaction plugin.
 *
 * Injects a persistence checklist into the compaction prompt so that state
 * survives long sessions: current task, files in play, decisions, and blockers.
 */
export const ContextCompactionPlugin = async () => {
  return {
    "experimental.session.compacting": async (_input, output) => {
      output.context.push(`
## Persisted session state

When summarizing, preserve the following explicitly:
1. The current task and its status.
2. Files being actively modified and by whom.
3. Key decisions made and their rationale.
4. Any blockers or open questions.
5. The next steps to continue the work.
`)
    },
  }
}

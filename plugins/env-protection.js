/**
 * Environment protection plugin.
 *
 * Blocks OpenCode from reading or exposing sensitive `.env` files through the
 * read/write tools, reducing the risk of leaking credentials to the model or
 * committing secrets.
 */
export const EnvProtectionPlugin = async () => {
  return {
    "tool.execute.before": async (input, output) => {
      if (input.tool === "read" || input.tool === "edit" || input.tool === "write") {
        const filePath = output.args?.filePath ?? output.args?.path ?? "";
        if (typeof filePath === "string" && filePath.split("/").includes(".env")) {
          throw new Error("Access to .env files is blocked by the env-protection plugin.")
        }
      }
    },
  }
}

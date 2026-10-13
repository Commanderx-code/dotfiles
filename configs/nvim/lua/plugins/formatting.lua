return {
  {
    "stevearc/conform.nvim",
    -- Python's formatter is set with its linter in ruff.lua.
    opts = {
      default_format_opts = { timeout_ms = 3000, lsp_format = "fallback" },
    },
  },
}

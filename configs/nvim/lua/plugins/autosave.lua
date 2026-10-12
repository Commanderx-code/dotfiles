return {
  {
    "stevearc/conform.nvim",
    opts = {
      formatters_by_ft = { python = { "ruff_format" } },
      default_format_opts = { timeout_ms = 3000, lsp_format = "fallback" },
    },
  },
}

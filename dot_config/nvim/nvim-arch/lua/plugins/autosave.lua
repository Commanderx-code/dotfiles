return {
  {
    "stevearc/conform.nvim",
    opts = function(_, opts)
    opts.formatters_by_ft = opts.formatters_by_ft or {}
    opts.formatters_by_ft.python = { "ruff_format" }

    opts.format_on_save = function(bufnr)
    local max_size = 1024 * 1024 -- 1MB
    local ok, stats = pcall(vim.uv.fs_stat, vim.api.nvim_buf_get_name(bufnr))
    if ok and stats and stats.size > max_size then
      return
      end

      return {
        timeout_ms = 3000,
        lsp_fallback = true,
      }
      end
      end,
  },
}

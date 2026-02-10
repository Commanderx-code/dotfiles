return {
  -- Formatting (Conform)
  {
    "stevearc/conform.nvim",
    opts = function(_, opts)
    opts.formatters_by_ft = opts.formatters_by_ft or {}
    opts.formatters_by_ft.python = { "ruff_format" }
    end,
  },

  -- Linting (nvim-lint)
  {
    "mfussenegger/nvim-lint",
    opts = function(_, opts)
    opts.linters_by_ft = opts.linters_by_ft or {}
    opts.linters_by_ft.python = { "ruff" }
    end,
  },
} 

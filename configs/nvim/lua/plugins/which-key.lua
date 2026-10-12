return {
  {
    "folke/which-key.nvim",
    opts = function(_, opts)
    opts.spec = opts.spec or {}

    -- Add ONLY custom groups/prefixes that LazyVim doesn't already define.
    vim.list_extend(opts.spec, {
      -- examples (uncomment if you actually use these):
      -- { "<leader>m", group = "messages" },
      -- { "<leader>t", group = "tests" },
      -- { "<leader>d", group = "debug" }, -- only if you added your own debug prefix
    })

    return opts
    end,
  },
}

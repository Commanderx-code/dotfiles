return {
  {
    "nvim-lualine/lualine.nvim",
    opts = function(_, opts)
    opts.options = opts.options or {}
    opts.options.disabled_filetypes = opts.options.disabled_filetypes or {}
    opts.options.disabled_filetypes.statusline = opts.options.disabled_filetypes.statusline or {}

    local list = opts.options.disabled_filetypes.statusline
    if not vim.tbl_contains(list, "alpha") then
      table.insert(list, "alpha")
      end
      end,
  },
}

return {
  {
    "goolord/alpha-nvim",
    config = function(_, opts)
      require("alpha").setup(opts.config)

      -- Hide status/tab/cmdline when Alpha is visible
      vim.api.nvim_create_autocmd("User", {
        pattern = "AlphaReady",
        callback = function()
          vim.defer_fn(function()
            vim.opt.laststatus = 0
            vim.opt.cmdheight = 0
            vim.opt.showtabline = 0
            vim.b.lualine_disable = true
          end, 150)
        end,
      })

      -- Restore them once you leave Alpha
      vim.api.nvim_create_autocmd({ "BufLeave", "BufUnload" }, {
        callback = function()
          if vim.bo.filetype == "alpha" then
            vim.defer_fn(function()
              vim.opt.laststatus = 3
              vim.opt.cmdheight = 1
              vim.opt.showtabline = 2
              vim.b.lualine_disable = false
            end, 100)
          end
        end,
      })
    end,
  },
}

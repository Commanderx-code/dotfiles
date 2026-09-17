return {
  {
    "folke/persistence.nvim",
    opts = { branch = true },
    keys = {
      {
        "<leader>qv",
        function()
          local persistence = require("persistence")
          persistence.start()
          persistence.save()
          vim.notify("Project session saved")
        end,
        desc = "Save Session",
      },
    },
  },
  {
    "lewis6991/gitsigns.nvim",
    keys = {
      { "<leader>ghP", function() require("gitsigns").preview_hunk() end, desc = "Preview Hunk Popup" },
    },
  },
  {
    "neovim/nvim-lspconfig",
    opts = {
      diagnostics = {
        update_in_insert = false,
        severity_sort = true,
        virtual_lines = false,
        virtual_text = {
          spacing = 2,
          source = false,
          severity = { min = vim.diagnostic.severity.WARN },
          format = function(diagnostic)
            local message = diagnostic.message:match("[^\r\n]+") or ""
            if vim.fn.strchars(message) > 60 then
              return vim.fn.strcharpart(message, 0, 59) .. "…"
            end
            return message
          end,
        },
        float = {
          border = "rounded",
          source = "if_many",
          scope = "line",
          max_width = 80,
        },
      },
    },
  },
  -- Escape insert mode with jk or jj, without delaying ordinary typing.
  {
    "max397574/better-escape.nvim",
    event = "InsertEnter",
    opts = {
      default_mappings = false,
      mappings = { i = { j = { k = "<Esc>", j = "<Esc>" } } },
      timeout = 200,
    },
  },
}

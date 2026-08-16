return {
  {
    "nvim-neo-tree/neo-tree.nvim",

    keys = {
      { "<C-n>", "<cmd>Neotree filesystem reveal left toggle<cr>", desc = "Neo-tree Toggle" },
      { "-", "<cmd>Neotree filesystem focus<cr>", desc = "Neo-tree Focus" },
    },

    opts = function(_, opts)
    opts.enable_git_status = true
    opts.popup_border_style = "rounded"

    opts.git_status = opts.git_status or {}
    opts.git_status.symbols = vim.tbl_deep_extend("force", opts.git_status.symbols or {}, {
      added = "A",
      modified = "M",
      deleted = "X",
      renamed = "=>",
      untracked = "?",
      ignored = "[/]",
      unstaged = "[]",
      staged = "S",
      conflict = "Y",
    })
    end,

    config = function()
    -----------------------------------------------------------------------
    -- 🧠 Auto-open Neo-tree when entering a real file buffer
    -----------------------------------------------------------------------
    vim.api.nvim_create_autocmd("BufWinEnter", {
      group = vim.api.nvim_create_augroup("AutoOpenNeoTree", { clear = true }),
                                callback = function()
                                local buftype = vim.api.nvim_get_option_value("buftype", { buf = 0 })
                                local filetype = vim.bo.filetype
                                if buftype == "" and filetype ~= "alpha" and vim.fn.expand("%") ~= "" then
                                  if not vim.g.neo_tree_opened then
                                    vim.g.neo_tree_opened = true
                                    vim.cmd("Neotree filesystem reveal left")
                                    end
                                    end
                                    end,
    })

    -----------------------------------------------------------------------
    -- 🎨 FINAL FIX: ensure Neo-tree matches transparent background
    -----------------------------------------------------------------------
    local function fix_neotree_bg()
    local normal = vim.api.nvim_get_hl(0, { name = "Normal" })
    local bg = normal.bg and string.format("#%06x", normal.bg) or "NONE"

    vim.api.nvim_set_hl(0, "NeoTreeNormal", { bg = bg })
    vim.api.nvim_set_hl(0, "NeoTreeNormalNC", { bg = bg })
    vim.api.nvim_set_hl(0, "NeoTreeEndOfBuffer", { bg = bg })
    end

    -- When theme loads
    vim.api.nvim_create_autocmd("ColorScheme", {
      group = vim.api.nvim_create_augroup("NeoTreeFinalFix", { clear = true }),
                                callback = function()
                                vim.defer_fn(fix_neotree_bg, 200)
                                end,
    })

    -- When Neo-tree opens
    vim.api.nvim_create_autocmd("User", {
      pattern = "NeoTreeBufferEnter",
      group = vim.api.nvim_create_augroup("NeoTreeFinalFixEnter", { clear = true }),
                                callback = function()
                                vim.defer_fn(fix_neotree_bg, 100)
                                end,
    })
    end,
  },
}

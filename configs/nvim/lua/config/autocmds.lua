-- Dashboard bars are managed by config.dashboard_hidebars at plugin startup.
require("config.autosave").setup()

local prose = { markdown = true, ["markdown.mdx"] = true, text = true, gitcommit = true }
vim.api.nvim_create_autocmd({ "FileType", "BufWinEnter" }, {
  group = vim.api.nvim_create_augroup("EditingByFiletype", { clear = true }),
  callback = function(ev)
    if vim.bo[ev.buf].buftype ~= "" then return end
    local writing = prose[vim.bo[ev.buf].filetype] == true
    vim.bo[ev.buf].textwidth = writing and 140 or 0
    if vim.api.nvim_get_current_buf() == ev.buf then
      vim.opt_local.spell = writing
      vim.opt_local.wrap = writing
      vim.opt_local.linebreak = writing
    end
  end,
})

vim.api.nvim_create_autocmd("TermOpen", {
  group = vim.api.nvim_create_augroup("TermNoNumbers", { clear = true }),
  callback = function()
    vim.opt_local.number = false
    vim.opt_local.relativenumber = false
  end,
})

-- Some colorschemes draw window separators almost in the background colour.
-- The explorer's takes the tree guides' colour, so the line beside it shows.
local function explorer_separator()
  vim.api.nvim_set_hl(0, "SnacksWinSeparator", { link = "SnacksPickerTree" })
end
vim.api.nvim_create_autocmd("ColorScheme", {
  group = vim.api.nvim_create_augroup("ExplorerSeparator", { clear = true }),
  callback = explorer_separator,
})
explorer_separator()

require("config.explorer").setup()

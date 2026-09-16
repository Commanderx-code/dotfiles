-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

-- setting up the var of r lazyterm
local lazyterm = function()
  Snacks.terminal(nil, { cwd = LazyVim.root() })
end

-- Insert-mode jk/jj are managed by better-escape (plugins/editor.lua).
vim.keymap.set("n", "<leader>qw", "<cmd>quit<CR>", { desc = "Quit Window" })

vim.keymap.set("i", "<C-b>", "<ESC>^i", { desc = "Beginning of line" })
vim.keymap.set("i", "<C-e>", "<End>", { desc = "End of line" })
vim.keymap.set("i", "<C-h>", "<Left>", { desc = "Move left" })
vim.keymap.set("i", "<C-l>", "<Right>", { desc = "Move right" })
vim.keymap.set("i", "<C-j>", "<Down>", { desc = "Move down" })
vim.keymap.set("i", "<C-k>", "<Up>", { desc = "Move up" })

-- terminal keymaps
vim.keymap.set({ "t" }, "<C-q>", "<C-\\><C-n>")
vim.keymap.set({ "t" }, "<C-h>", "<C-\\><C-n><C-w>h")
vim.keymap.set({ "t" }, "<C-j>", "<C-\\><C-n><C-w>j")
vim.keymap.set({ "t" }, "<C-k>", "<C-\\><C-n><C-w>k")
vim.keymap.set({ "t" }, "<C-l>", "<C-\\><C-n><C-w>l")

vim.keymap.set("n", "<C-K>", "<C-W>K", { desc = "Move to top window" })
vim.keymap.set("n", "<leader>tb", ":12split | :terminal <CR>", { desc = "Open horizontal terminal split" })

-- open finder 
vim.keymap.set("n", "<leader>of", function() vim.ui.open(vim.fn.getcwd()) end, { desc = "Open directory in file manager" })

-- vim.keymap.set("n", ";", ":", { desc = "Enter command mode" })
-- Use LazyVim defaults: <leader>bd deletes a buffer; <leader>cd shows diagnostics.
-- vim.keymap.set("n", "<Tab>", "]b", { desc = "Next buffer", remap = true })
-- vim.keymap.set("n", "<S-Tab>", "[b", { desc = "Previous buffer", remap = true })
vim.keymap.set("v", "<leader>/", "gc", { desc = "Comment selected", remap = true })
vim.keymap.set("n", "<leader>/", "gcc", { desc = "Comment Line", remap = true })
vim.keymap.set("n", "<leader>fw", function() Snacks.picker.grep() end, { desc = "Live Grep" })
vim.keymap.set({ "n", "t" }, "<A-i>", lazyterm, { desc = "Toggle Terminal", remap = true })

--color scheme
vim.keymap.set("n", "<leader>th", function() Snacks.picker.colorschemes() end, { desc = "Colorschemes" })

-- move selection in visual mode
vim.keymap.set("v", "K", ":move '<-2<CR>gv=gv", { desc = "Move selection up" })
vim.keymap.set("v", "J", ":move '>+1<CR>gv=gv", { desc = "Move selection down" })

-- Notes
vim.keymap.set("n", "<leader>nt", function() Snacks.picker.files({ cwd = vim.fn.expand("~/Documents/Notes") }) end, { desc = "Notes" })
vim.keymap.set(
  "n",
  "<leader>dn",
  function() Snacks.picker.files({ cwd = vim.fn.expand("~/Documents/Gambhir/Daily-Todos") }) end,
  { desc = "Daily Journal" }
)

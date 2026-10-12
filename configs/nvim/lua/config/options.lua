-- Use Snacks for search, LSP pickers, and the file explorer.
vim.g.lazyvim_picker = "snacks"
vim.g.lazyvim_explorer = "snacks"

vim.opt.spelllang = 'en_us'
vim.opt.spell = false

vim.opt.textwidth = 0
vim.opt.wrap = false

vim.g.nightflyTransparent = true

-- Optional: silence providers you don't use
vim.g.loaded_perl_provider = 0
vim.g.loaded_ruby_provider = 0
-- Global formats
vim.g.autoformat = true


-- Register before LazyVim's formatter so the limit also applies to a write
-- immediately after programmatic edits. Manual :LazyFormat remains available.
local format_limits = {}
vim.api.nvim_create_autocmd({ "BufReadPost", "BufNewFile", "TextChanged", "TextChangedI", "BufWritePre" }, {
  group = vim.api.nvim_create_augroup("LargeFileAutoformat", { clear = true }),
  callback = function(event)
    local buf = event.buf
    local size = vim.api.nvim_buf_get_offset(buf, vim.api.nvim_buf_line_count(buf))
    if size > 1024 * 1024 then
      if not format_limits[buf] then
        format_limits[buf] = { previous = vim.b[buf].autoformat }
      end
      vim.b[buf].autoformat = false
    elseif format_limits[buf] then
      if vim.b[buf].autoformat == false then
        vim.b[buf].autoformat = format_limits[buf].previous
      end
      format_limits[buf] = nil
    end
  end,
})
vim.api.nvim_create_autocmd("BufWipeout", {
  group = "LargeFileAutoformat",
  callback = function(event) format_limits[event.buf] = nil end,
})

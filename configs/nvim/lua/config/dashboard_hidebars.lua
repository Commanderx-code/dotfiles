local M = {}

function M.setup()
  local group = vim.api.nvim_create_augroup("DashboardHideBars", { clear = true })
  local saved

  local function update()
    local buf = vim.api.nvim_get_current_buf()
    if vim.bo[buf].filetype == "snacks_dashboard" then
      if not saved then
        saved = { vim.o.laststatus, vim.o.showtabline, vim.o.cmdheight }
      end
      vim.o.laststatus = 0
      vim.o.showtabline = 0
      vim.o.cmdheight = 0
    elseif saved then
      vim.o.laststatus, vim.o.showtabline, vim.o.cmdheight = unpack(saved)
      saved = nil
    end
  end

  vim.api.nvim_create_autocmd({ "BufEnter", "WinEnter", "FileType" }, {
    group = group,
    callback = update,
  })
  vim.api.nvim_create_autocmd("User", {
    group = group,
    pattern = "SnacksDashboardOpened",
    callback = update,
  })
end

return M

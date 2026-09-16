local M = {}

function M.toggle()
  local picker = Snacks.picker.get({ source = "explorer" })[1]
  if picker then
    picker:close()
  else
    Snacks.explorer()
  end
end

function M.focus()
  local picker = Snacks.picker.get({ source = "explorer" })[1]
  if picker then
    picker:focus()
  else
    Snacks.explorer()
  end
end

function M.setup()
  local opened = false
  local function open_once()
    if opened or not _G.Snacks or not Snacks.config.explorer.enabled then
      return
    end
    local buf = vim.api.nvim_get_current_buf()
    local path = vim.api.nvim_buf_get_name(buf)
    if vim.bo[buf].buftype ~= "" or path == "" or vim.fn.isdirectory(path) == 1 then
      return
    end
    opened = true
    -- Defer window changes until the buffer event is finished.
    vim.schedule(function()
      if vim.api.nvim_get_current_buf() == buf and not Snacks.picker.get({ source = "explorer" })[1] then
        Snacks.explorer()
      end
    end)
  end
  vim.api.nvim_create_autocmd("BufWinEnter", {
    group = vim.api.nvim_create_augroup("AutoOpenSnacksExplorer", { clear = true }),
    callback = open_once,
  })
  open_once()
end

return M

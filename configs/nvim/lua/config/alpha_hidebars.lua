local M = {}

function M.setup()
  local group = vim.api.nvim_create_augroup("AlphaHideBars", { clear = true })
  local saved
  local disabled = {}

  local function update()
    local buf = vim.api.nvim_get_current_buf()
    if vim.bo[buf].filetype == "alpha" then
      if not saved then
        saved = { vim.o.laststatus, vim.o.showtabline, vim.o.cmdheight }
      end
      if disabled[buf] == nil then
        disabled[buf] = { value = vim.b[buf].lualine_disable }
      end
      vim.b[buf].lualine_disable = true
      vim.o.laststatus = 0
      vim.o.showtabline = 0
      vim.o.cmdheight = 0
    elseif saved then
      vim.o.laststatus, vim.o.showtabline, vim.o.cmdheight = unpack(saved)
      saved = nil
      for alpha_buf, state in pairs(disabled) do
        if vim.api.nvim_buf_is_valid(alpha_buf) then
          vim.b[alpha_buf].lualine_disable = state.value
        end
      end
      disabled = {}
    end
  end

  vim.api.nvim_create_autocmd({ "BufEnter", "WinEnter", "FileType" }, {
    group = group,
    callback = update,
  })
  vim.api.nvim_create_autocmd("User", {
    group = group,
    pattern = "AlphaReady",
    callback = update,
  })
end

return M

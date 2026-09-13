-- Run without plugins, user configuration, or persistent Neovim state.
local function check()
  for _, path in ipairs(vim.fn.glob("configs/nvim/**/*.lua", false, true)) do
    assert(loadfile(path))
  end
  vim.opt.runtimepath:prepend(vim.fn.getcwd() .. "/configs/nvim")
  package.path = "configs/nvim/lua/?.lua;" .. package.path
  local notifications = {}
  vim.notify = function(message) table.insert(notifications, message) end
  vim.api.nvim_echo = function(chunks) table.insert(notifications, chunks[1][1]) end
  dofile("configs/nvim/lua/config/autocmds.lua")

  -- A nonexistent parent makes writes fail even when tests run as root.
  local directory = vim.fn.tempname()
  vim.fn.mkdir(directory)
  local failed = vim.api.nvim_create_buf(true, false)
  vim.api.nvim_set_current_buf(failed)
  vim.api.nvim_buf_set_name(failed, directory .. "/missing/file.txt")
  vim.api.nvim_buf_set_lines(failed, 0, -1, false, { "unsaved" })
  vim.api.nvim_exec_autocmds("InsertLeave", { buffer = failed })
  assert(vim.bo[failed].modified, "failed write must remain modified")
  assert(notifications[#notifications]:find("AutoSave failed", 1, true))
  for _, message in ipairs(notifications) do
    assert(not message:find("Saved:", 1, true), "failed write claimed success")
  end

  vim.api.nvim_buf_set_name(failed, directory .. "/saved.txt")
  vim.api.nvim_exec_autocmds("InsertLeave", { buffer = failed })
  assert(not vim.bo[failed].modified)
  assert(vim.fn.readfile(directory .. "/saved.txt")[1] == "unsaved")
  assert(notifications[#notifications]:find("Saved:", 1, true))

  -- The size guard is registered during options loading, before LazyFormat.
  dofile("configs/nvim/lua/config/options.lua")
  local large = vim.api.nvim_create_buf(true, false)
  vim.api.nvim_set_current_buf(large)
  vim.api.nvim_buf_set_lines(large, 0, -1, false, { string.rep("x", 1024 * 1024 + 1) })
  vim.api.nvim_exec_autocmds("BufWritePre", { buffer = large })
  assert(vim.b[large].autoformat == false, "large buffers must disable autoformat")
  vim.api.nvim_buf_set_lines(large, 0, -1, false, { "small" })
  vim.api.nvim_exec_autocmds("BufWritePre", { buffer = large })
  assert(vim.b[large].autoformat == nil, "small buffers must restore inherited preference")
  vim.b[large].autoformat = false
  vim.api.nvim_buf_set_lines(large, 0, -1, false, { string.rep("x", 1024 * 1024 + 1) })
  vim.api.nvim_exec_autocmds("BufWritePre", { buffer = large })
  vim.api.nvim_buf_set_lines(large, 0, -1, false, { "small" })
  vim.api.nvim_exec_autocmds("BufWritePre", { buffer = large })
  assert(vim.b[large].autoformat == false, "preserve explicit user disable")
  vim.api.nvim_set_current_buf(failed)

  -- Repeated Alpha events and rapid transitions must preserve actual UI values.
  vim.o.laststatus, vim.o.showtabline, vim.o.cmdheight = 2, 1, 2
  local alpha = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_set_current_buf(alpha)
  vim.bo[alpha].filetype = "alpha"
  vim.api.nvim_exec_autocmds("User", { pattern = "AlphaReady" })
  assert(vim.o.laststatus == 0 and vim.o.cmdheight == 0)
  vim.api.nvim_set_current_buf(failed)
  assert(vim.o.laststatus == 2 and vim.o.showtabline == 1 and vim.o.cmdheight == 2)
  assert(vim.b[alpha].lualine_disable == nil)
  vim.api.nvim_set_current_buf(alpha)
  vim.api.nvim_set_current_buf(failed)
  vim.wait(200, function() return false end)
  assert(vim.o.laststatus == 2 and vim.o.cmdheight == 2)
  vim.fn.delete(directory, "rf")
  print("Neovim syntax, autosave, and dashboard checks passed")
end
local ok, err = pcall(check)
if not ok then
  io.stderr:write(tostring(err) .. "\n")
  vim.cmd("cquit 1")
end
vim.cmd("qa!")

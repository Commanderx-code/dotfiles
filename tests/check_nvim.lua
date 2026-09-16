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
  require("config.dashboard_hidebars").setup()
  require("config.autosave").setup({ delay = 40 })

  -- A nonexistent parent makes writes fail even when tests run as root.
  local directory = vim.fn.tempname()
  vim.fn.mkdir(directory)
  local failed = vim.api.nvim_create_buf(true, false)
  vim.api.nvim_set_current_buf(failed)
  vim.api.nvim_buf_set_name(failed, directory .. "/missing/file.txt")
  vim.api.nvim_buf_set_lines(failed, 0, -1, false, { "unsaved" })
  vim.api.nvim_exec_autocmds("InsertLeave", { buffer = failed })
  assert(vim.wait(500, function() return #notifications > 0 end), "failed save must report an error")
  assert(vim.bo[failed].modified, "failed write must remain modified")
  assert(notifications[#notifications]:find("AutoSave failed", 1, true))
  for _, message in ipairs(notifications) do
    assert(not message:find("Saved:", 1, true), "failed write claimed success")
  end

  local error_count = #notifications
  vim.api.nvim_buf_set_name(failed, directory .. "/saved.txt")
  vim.api.nvim_exec_autocmds("InsertLeave", { buffer = failed })
  assert(vim.wait(500, function() return not vim.bo[failed].modified end), "debounced save did not run")
  assert(vim.fn.readfile(directory .. "/saved.txt")[1] == "unsaved")
  assert(#notifications == error_count, "successful saves must be silent")

  local writes = 0
  vim.api.nvim_create_autocmd("BufWritePost", {
    buffer = failed,
    callback = function() writes = writes + 1 end,
  })
  for i = 1, 5 do
    vim.api.nvim_buf_set_lines(failed, 0, -1, false, { "edit " .. i })
    vim.api.nvim_exec_autocmds("TextChanged", { buffer = failed })
  end
  assert(writes == 0, "autosave must wait for idle time")
  assert(vim.wait(500, function() return writes == 1 end))
  vim.wait(100, function() return false end)
  assert(writes == 1, "burst of changes must produce only one write")
  assert(vim.fn.readfile(directory .. "/saved.txt")[1] == "edit 5")

  vim.api.nvim_buf_set_lines(failed, 0, -1, false, { "typing" })
  vim.api.nvim_exec_autocmds("TextChanged", { buffer = failed })
  vim.api.nvim_exec_autocmds("InsertEnter", { buffer = failed })
  vim.wait(100, function() return false end)
  assert(writes == 1 and vim.bo[failed].modified, "starting insert mode must cancel queued save")
  vim.api.nvim_exec_autocmds("InsertLeave", { buffer = failed })
  assert(vim.wait(500, function() return writes == 2 end))

  vim.bo[failed].filetype = "markdown"
  vim.api.nvim_exec_autocmds("FileType", { buffer = failed })
  assert(vim.wo.spell and vim.wo.wrap and vim.bo.textwidth == 140)
  vim.bo[failed].filetype = "nix"
  vim.api.nvim_exec_autocmds("FileType", { buffer = failed })
  assert(not vim.wo.spell and not vim.wo.wrap and vim.bo.textwidth == 0)


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

  -- Repeated Dashboard events and rapid transitions must preserve actual UI values.
  vim.o.laststatus, vim.o.showtabline, vim.o.cmdheight = 2, 1, 2
  local dashboard = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_set_current_buf(dashboard)
  vim.bo[dashboard].filetype = "snacks_dashboard"
  vim.api.nvim_exec_autocmds("User", { pattern = "SnacksDashboardOpened" })
  assert(vim.o.laststatus == 0 and vim.o.cmdheight == 0)
  vim.api.nvim_set_current_buf(failed)
  assert(vim.o.laststatus == 2 and vim.o.showtabline == 1 and vim.o.cmdheight == 2)
  assert(vim.b[dashboard].lualine_disable == nil)
  vim.api.nvim_set_current_buf(dashboard)
  vim.api.nvim_set_current_buf(failed)
  vim.wait(200, function() return false end)
  assert(vim.o.laststatus == 2 and vim.o.cmdheight == 2)
  -- Opening a named file should show the sidebar once, never reopen it after
  -- an explicit close; focusing an existing explorer must not duplicate it.
  local current, opens, focuses = nil, 0, 0
  _G.Snacks = {
    config = { explorer = { enabled = true } },
    picker = { get = function() return current and { current } or {} end },
    explorer = function()
      opens = opens + 1
      current = {
        close = function() current = nil end,
        focus = function() focuses = focuses + 1 end,
      }
    end,
  }
  local explorer = require("config.explorer")
  vim.api.nvim_set_current_buf(dashboard)
  explorer.setup()
  vim.wait(20, function() return false end)
  assert(opens == 0, "dashboard must not open the explorer")
  vim.api.nvim_set_current_buf(failed)
  assert(vim.wait(200, function() return opens == 1 end), "named file must open explorer")
  explorer.focus()
  assert(opens == 1 and focuses == 1, "focus must reuse explorer")
  explorer.toggle()
  assert(current == nil, "toggle must close explorer")
  vim.api.nvim_exec_autocmds("BufWinEnter", { buffer = failed })
  vim.wait(20, function() return false end)
  assert(opens == 1, "closed explorer must not automatically reopen")
  explorer.toggle()
  assert(opens == 2 and current, "toggle must reopen explorer")
  _G.Snacks = nil
  vim.fn.delete(directory, "rf")
  print("Neovim syntax, autosave, dashboard, and explorer checks passed")
end
local ok, err = pcall(check)
if not ok then
  io.stderr:write(tostring(err) .. "\n")
  vim.cmd("cquit 1")
end
vim.cmd("qa!")

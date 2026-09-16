local M = {}

function M.setup(opts)
  opts = opts or {}
  local delay = opts.delay or 750
  local pending, errors, saving = {}, {}, {}
  local group = vim.api.nvim_create_augroup("AutoSave", { clear = true })

  local function cancel(buf)
    local timer = pending[buf]
    pending[buf] = nil
    if timer and not timer:is_closing() then
      timer:stop()
      timer:close()
    end
  end

  local function save(buf)
    if not vim.api.nvim_buf_is_valid(buf) or saving[buf] then return end
    local bo = vim.bo[buf]
    if bo.buftype ~= "" or bo.readonly or not bo.modifiable or not bo.modified then return end
    if vim.api.nvim_buf_get_name(buf) == "" then return end
    -- Leave formatting and cursor position alone while the user is typing.
    if vim.api.nvim_get_current_buf() == buf and vim.fn.mode():match("^[iR]") then return end
    saving[buf] = true
    local tick = vim.api.nvim_buf_get_changedtick(buf)
    local ok, err = pcall(vim.api.nvim_buf_call, buf, function() vim.cmd("silent update") end)
    saving[buf] = nil
    if not ok or (vim.api.nvim_buf_is_valid(buf) and vim.bo[buf].modified) then
      local message = tostring(err or vim.api.nvim_buf_get_name(buf))
      local key = tostring(tick) .. message
      if errors[buf] ~= key then
        errors[buf] = key
        vim.notify("AutoSave failed: " .. message, vim.log.levels.ERROR)
      end
    else
      errors[buf] = nil
    end
  end

  vim.api.nvim_create_autocmd({ "InsertLeave", "TextChanged" }, {
    group = group,
    callback = function(ev)
      cancel(ev.buf)
      if saving[ev.buf] then return end
      local timer
      timer = vim.defer_fn(function()
        if pending[ev.buf] ~= timer then return end
        pending[ev.buf] = nil
        save(ev.buf)
      end, delay)
      pending[ev.buf] = timer
    end,
  })
  vim.api.nvim_create_autocmd({ "InsertEnter", "TextChangedI", "BufWritePost" }, {
    group = group,
    callback = function(ev) cancel(ev.buf) end,
  })
  vim.api.nvim_create_autocmd("BufWipeout", {
    group = group,
    callback = function(ev)
      cancel(ev.buf)
      errors[ev.buf], saving[ev.buf] = nil, nil
    end,
  })
  vim.api.nvim_create_autocmd("VimLeavePre", {
    group = group,
    callback = function()
      for buf in pairs(pending) do cancel(buf) end
    end,
  })
end

return M

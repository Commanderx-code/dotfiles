-- ~/.config/nvim/lua/config/autocmds.lua
-- Add any additional autocmds here

-- 1) Hide lualine/statusline/tabline only on Alpha
require("config.alpha_hidebars").setup()

-- 2) Autosave (writes the file, not just formatting)
local autosave_grp = vim.api.nvim_create_augroup("AutoSave", { clear = true })

local function should_autosave(buf)
if not vim.api.nvim_buf_is_valid(buf) then
  return false
  end
  if vim.bo[buf].buftype ~= "" then
    return false
    end
    if vim.bo[buf].filetype == "alpha" then
      return false
      end
      if vim.bo[buf].readonly or not vim.bo[buf].modifiable then
        return false
        end
        if vim.api.nvim_buf_get_name(buf) == "" then
          return false
          end
          if not vim.bo[buf].modified then
            return false
            end
            return true
            end

            local function notify_saved(filepath)
            local ok, notify = pcall(require, "notify")
            if ok then
              notify("💾 Saved: " .. filepath, "info", { title = "AutoSave", timeout = 1000 })
              else
                vim.api.nvim_echo({ { "💾 Saved: " .. filepath, "None" } }, false, {})
                end
                end

                vim.api.nvim_create_autocmd({ "InsertLeave", "TextChanged" }, {
                  group = autosave_grp,
                  callback = function(ev)
                  if not should_autosave(ev.buf) then
                    return
                    end

                    local filepath = vim.fn.expand("%:p")
                    vim.api.nvim_buf_call(ev.buf, function()
                    vim.cmd("silent! write")
                    end)
                    notify_saved(filepath)
                    end,
                })

                -- 3) Terminal buffers: hide numbers
                local term_grp = vim.api.nvim_create_augroup("TermNoNumbers", { clear = true })

                vim.api.nvim_create_autocmd("TermOpen", {
                  group = term_grp,
                  callback = function()
                  vim.opt_local.number = false
                  vim.opt_local.relativenumber = false
                  end,
                })

                -- 4) Neo-tree: remove hard-coded background so it inherits transparency
                local neotree_grp = vim.api.nvim_create_augroup("NeoTreeTransparent", { clear = true })

                vim.api.nvim_create_autocmd("ColorScheme", {
                  group = neotree_grp,
                  callback = function()
                  vim.cmd([[
                    hi NeoTreeNormal guibg=NONE
                    hi NeoTreeNormalNC guibg=NONE
                    hi NeoTreeEndOfBuffer guibg=NONE
                  ]])
                  end,
                })

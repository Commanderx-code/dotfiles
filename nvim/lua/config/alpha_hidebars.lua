-- ~/.config/nvim/lua/config/alpha_hidebars.lua
local M = {}

function M.setup()
local grp = vim.api.nvim_create_augroup("AlphaHideBars", { clear = true })

local function save_ui_state()
if vim.g._alpha_ui_saved then
  return
  end
  vim.g._alpha_ui_saved = true
  vim.g._alpha_laststatus = vim.o.laststatus
  vim.g._alpha_showtabline = vim.o.showtabline
  vim.g._alpha_cmdheight = vim.o.cmdheight
  end

  local function hide_ui_for_alpha()
  if vim.bo.filetype ~= "alpha" then
    return
    end

    save_ui_state()

    -- Disable lualine on Alpha
    vim.b.lualine_disable = true

    -- Hide bars while Alpha is visible
    vim.o.laststatus = 0
    vim.o.showtabline = 0
    vim.o.cmdheight = 0
    end

    local function restore_ui()
    if not vim.g._alpha_ui_saved then
      return
      end

      vim.o.laststatus = vim.g._alpha_laststatus or vim.o.laststatus
      vim.o.showtabline = vim.g._alpha_showtabline or vim.o.showtabline
      vim.o.cmdheight = vim.g._alpha_cmdheight or vim.o.cmdheight

      vim.g._alpha_ui_saved = nil
      vim.g._alpha_laststatus = nil
      vim.g._alpha_showtabline = nil
      vim.g._alpha_cmdheight = nil
      end

      -- Primary: when Alpha filetype opens
      vim.api.nvim_create_autocmd("FileType", {
        group = grp,
        pattern = "alpha",
        callback = function()
        -- run right away, and again shortly after (helps with late redraws)
      hide_ui_for_alpha()
      vim.defer_fn(hide_ui_for_alpha, 50)
      vim.defer_fn(hide_ui_for_alpha, 150)
      end,
      })

      -- Extra: AlphaReady event (some setups only render after this)
      vim.api.nvim_create_autocmd("User", {
        group = grp,
        pattern = "AlphaReady",
        callback = function()
        vim.defer_fn(hide_ui_for_alpha, 50)
        end,
      })

      -- Restore when leaving Alpha
      vim.api.nvim_create_autocmd({ "BufLeave", "BufUnload" }, {
        group = grp,
        callback = function(ev)
        if vim.bo[ev.buf].filetype == "alpha" then
          vim.defer_fn(restore_ui, 50)
          end
          end,
      })
      end

      return M

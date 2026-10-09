-- The startup colorscheme, and a picker that remembers its choice.
--
-- Home Manager generates lua/config/rice.lua with the palette's colorscheme and
-- the path of home-manager/rice.json. An "nvim" entry in that file wins: the
-- picker writes it, so a pick survives restarts without a rebuild, and `rice`
-- keeps it when the palette changes.
local M = {}

local function generated()
  local ok, rice = pcall(require, "config.rice")
  return ok and rice or {}
end

local function read(path)
  local file = path and io.open(path, "r")
  if not file then return nil end
  local text = file:read("*a")
  file:close()
  local ok, data = pcall(vim.json.decode, text)
  return ok and type(data) == "table" and data or nil
end

-- The colorscheme to start with: the saved pick, else the palette's, else Eldritch.
function M.default(path)
  local rice = generated()
  local selection = read(path or rice.selection)
  local saved = selection and selection.nvim
  if type(saved) == "string" and saved ~= "" then return saved end
  return rice.colorscheme or "eldritch"
end

-- Record `name` as the "nvim" entry, keeping the file's other entries and layout.
function M.save(name, path)
  path = path or generated().selection
  if not read(path) then return false, "no rice.json to save to" end
  local result = vim.system({ "jq", "--arg", "name", name, ".nvim = $name", path }, { text = true }):wait()
  if result.code ~= 0 or result.stdout == "" then return false, vim.trim(result.stderr or "jq failed") end
  local file, err = io.open(path, "w")
  if not file then return false, err end
  file:write(result.stdout)
  file:close()
  return true
end

-- Snacks' colorscheme picker, with the confirmed choice saved as well as applied.
function M.pick()
  local confirm = require("snacks.picker.config.sources").colorschemes.confirm
  Snacks.picker.colorschemes({
    confirm = function(picker, item)
      confirm(picker, item)
      if not item then return end
      local ok, err = M.save(item.text)
      if ok then
        vim.notify("Colorscheme saved: " .. item.text)
      else
        vim.notify("Colorscheme applied for this session only: " .. tostring(err), vim.log.levels.WARN)
      end
    end,
  })
end

return M

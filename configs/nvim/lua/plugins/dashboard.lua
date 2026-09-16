return {
  {
    "folke/snacks.nvim",
    init = function()
      require("config.dashboard_hidebars").setup()
    end,
    opts = {
      dashboard = {
        enabled = true,
        width = 80,
        formats = {
          header = function(item)
            -- Snacks centers each line separately. Pad by display cells so the
            -- original multi-line artwork is centered as one rectangular block.
            local lines = vim.split(item.header, "\n", { plain = true })
            local width = 0
            for _, line in ipairs(lines) do
              width = math.max(width, vim.api.nvim_strwidth(line))
            end
            for i, line in ipairs(lines) do
              lines[i] = line .. string.rep(" ", width - vim.api.nvim_strwidth(line))
            end
            return { table.concat(lines, "\n"), align = "center", hl = "SnacksDashboardHeader" }
          end,
        },
        preset = {
          header = [[
                                              
       ████ ██████           █████      ██
      ███████████             █████ 
      █████████ ███████████████████ ███   ███████████
     █████████  ███    █████████████ █████ ██████████████
    █████████ ██████████ █████████ █████ █████ ████ █████
  ███████████ ███    ███ █████████ █████ █████ ████ █████
 ██████  █████████████████████ ████ █████ █████ ████ ██████

                              [ Revan ]
]],
          -- Preserve Alpha's shortcut order and use the Snacks picker.
          keys = {
            { icon = " ", key = "f", desc = "Find File", action = function() LazyVim.pick()() end },
            { icon = " ", key = "n", desc = "New File", action = ":ene | startinsert" },
            { icon = " ", key = "r", desc = "Recent Files", action = function() LazyVim.pick("oldfiles")() end },
            { icon = " ", key = "g", desc = "Find Text", action = function() LazyVim.pick("live_grep")() end },
            { icon = " ", key = "c", desc = "Config", action = function() LazyVim.pick.config_files()() end },
            { icon = " ", key = "s", desc = "Restore Session", action = function() require("persistence").load() end },
            { icon = " ", key = "x", desc = "Lazy Extras", action = ":LazyExtras" },
            { icon = "󰒲 ", key = "l", desc = "Lazy", action = ":Lazy" },
            { icon = " ", key = "q", desc = "Quit", action = ":qa" },
          },
        },
        sections = {
          { section = "header" },
          { section = "keys", gap = 1, padding = 1 },
          function()
            local stats = require("lazy").stats()
            return {
              text = { { ("⚡ Neovim loaded %d/%d plugins in %.2fms"):format(stats.loaded, stats.count, stats.startuptime), hl = "Comment" } },
              align = "center",
              padding = 1,
            }
          end,
          { text = { { "Ready to code!", hl = "SnacksDashboardKey" } }, align = "center" },
        },
      },
    },
  },
}

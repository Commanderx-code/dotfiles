return {
  {
    "folke/snacks.nvim",
    keys = {
      { "<leader>n", false },
      { "<leader>nn", function() Snacks.picker.notifications() end, desc = "Notification History" },
      -- Retain the existing picker shortcuts and cwd-based searches.
      { "<leader>ff", function() Snacks.picker.files() end, desc = "Find Files" },
      { "<leader>fg", function() Snacks.picker.grep() end, desc = "Find Text" },
      { "<leader>fb", function() Snacks.picker.buffers() end, desc = "Find Buffers" },
      { "<leader>fh", function() Snacks.picker.help() end, desc = "Help Tags" },
      { "<leader>fr", function() Snacks.picker.recent() end, desc = "Recent Files" },
      { "<C-n>", function() require("config.explorer").toggle() end, desc = "Explorer Toggle" },
      { "-", function() require("config.explorer").focus() end, desc = "Explorer Focus" },
      { "<leader>ge", function() Snacks.picker.git_status() end, desc = "Git Explorer" },
      { "<leader>be", function() Snacks.picker.buffers() end, desc = "Buffer Explorer" },
    },
    opts = {
      explorer = { enabled = true },
      picker = {
        enabled = true,
        -- Search results on top, file preview below.
        layout = { preset = "vertical" },
        layouts = { vertical = { layout = { width = 0.8 } } },
        win = {
          input = { keys = {
            ["<c-j>"] = { "list_down", mode = { "n", "i" } },
            ["<c-k>"] = { "list_up", mode = { "n", "i" } },
          } },
          list = { keys = { ["<c-j>"] = "list_down", ["<c-k>"] = "list_up" } },
        },
        sources = {
          explorer = {
            hidden = true,
            ignored = true,
            follow_file = true,
            git_status = true,
            on_show = function(picker)
              -- The sidebar uses a separate split underneath its floating windows.
              local root = picker.layout.root
              vim.api.nvim_win_call(root.win, function()
                vim.opt_local.fillchars:append({ vert = " " })
                root.opts.wo.fillchars = vim.wo.fillchars
              end)
            end,
            layout = { preset = "sidebar", layout = { position = "left" } },
            icons = { git = {
              added = "A", modified = "M", deleted = "X", renamed = "=>",
              untracked = "?", ignored = "[/]", staged = "S", unmerged = "Y",
            } },
            win = {
              input = { border = "rounded" },
              list = {
                wo = { winhighlight = "Normal:Normal,NormalNC:NormalNC,EndOfBuffer:Normal" },
                keys = {
                  ["O"] = "explorer_open",
                  ["Y"] = function(picker)
                    local item = picker:current()
                    if item then
                      vim.fn.setreg("+", Snacks.picker.util.path(item), "c")
                    end
                  end,
                },
              },
            },
          },
        },
      },
    },
  },
}

-- ~/.config/nvim/lua/plugins/colorscheme.lua
return {
    -- =========================
    -- Active theme (current)
    -- =========================
    {
        "olivercederborg/poimandres.nvim",
        lazy = false,
        priority = 1000,
        config = function()
        require("poimandres").setup({
            dim_nc_background = true,
            disable_background = false,
            disable_float_background = true,
            bold_vert_split = false,
            disable_italics = false,
        })
        vim.cmd.colorscheme("eldritch")
        end,
    },

    -- =================================
    -- Installed themes (switch later)
    -- =================================
    { "folke/tokyonight.nvim", lazy = true, priority = 1000 },
    { "shaunsingh/nord.nvim", lazy = true, priority = 1000 },
    { "EdenEast/nightfox.nvim", lazy = true, priority = 1000 },
    { "catppuccin/nvim", name = "catppuccin", lazy = true, priority = 1000 },

    -- Nordern
    { "fcancelinha/nordern.nvim", lazy = true, priority = 1000 },

    -- Monokai Pro (Octagon filter available)
    {
        "loctvl842/monokai-pro.nvim",
        lazy = true,
        priority = 1000,
        config = function()
        require("monokai-pro").setup({
            filter = "octagon",
        })
        end,
    }, -- :contentReference[oaicite:5]{index=5}

    { "eldritch-theme/eldritch.nvim", lazy = true, priority = 1000 },

    {
        "luisiacc/gruvbox-baby",
        lazy = true,
        priority = 1000,
        init = function()
        -- gruvbox-baby reads globals early
        vim.g.gruvbox_baby_transparent_mode = 1
        end,
    },

    -- Tell LazyVim the default (optional but nice to keep consistent)
    {
        "LazyVim/LazyVim",
        opts = {
            colorscheme = "eldritch",
        },
    },
}

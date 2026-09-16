{ pkgs, ... }:

{
  home.packages = with pkgs; [
    neovim
    tree-sitter
    nil
    nixfmt
    statix
    marksman
    markdownlint-cli2
    markdown-toc
    prettier
  ];

  xdg.configFile."nvim" = {
    source = ../../configs/nvim;
    recursive = true;
  };

  # LuaJIT's library loader does not search Nix store paths automatically.
  xdg.configFile."nvim/lua/plugins/nix-dependencies.lua".text = ''
    return {
      -- Keep language tools and browser preview reproducible through Nix.
      {
        "neovim/nvim-lspconfig",
        opts = { servers = { nil_ls = { mason = false }, marksman = { mason = false } } },
      },
      {
        "mason-org/mason.nvim",
        opts = function(_, opts)
          local provided = { ["markdownlint-cli2"] = true, ["markdown-toc"] = true, prettier = true }
          opts.ensure_installed = vim.tbl_filter(function(tool) return not provided[tool] end, opts.ensure_installed or {})
        end,
      },
      {
        "iamcco/markdown-preview.nvim",
        dir = "${pkgs.vimPlugins.markdown-preview-nvim}",
        build = false,
      },
      {
        "MeanderingProgrammer/render-markdown.nvim",
        dir = "${pkgs.vimPlugins.render-markdown-nvim}",
      },
      {
        "folke/snacks.nvim",
        opts = {
          picker = {
            db = { sqlite3_path = "${pkgs.sqlite.out}/lib/libsqlite3.so" },
          },
        },
      },
    }
  '';
}

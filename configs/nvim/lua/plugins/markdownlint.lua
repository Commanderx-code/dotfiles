return {
  -- markdownlint-cli2 reads the buffer from stdin, so it only finds a
  -- .markdownlint.* config in its working directory. Run it from the
  -- buffer's git root so each repo's config applies.
  {
    "mfussenegger/nvim-lint",
    opts = function(_, opts)
      opts.linters = opts.linters or {}
      opts.linters["markdownlint-cli2"] = function()
        local linter = require("lint.linters.markdownlint-cli2")
        return vim.tbl_extend("force", linter, { cwd = vim.fs.root(0, ".git") })
      end
    end,
  },
}

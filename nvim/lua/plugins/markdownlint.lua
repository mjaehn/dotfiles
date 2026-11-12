-- nvim-lint pipes the buffer via stdin, so ignores in .markdownlint-cli2.yaml do not apply
return {
  "mfussenegger/nvim-lint",
  optional = true,
  opts = {
    linters = {
      ["markdownlint-cli2"] = {
        -- SUMMARY.md files are MkDocs literate-nav navigation, not content pages
        condition = function(ctx)
          return vim.fs.basename(ctx.filename) ~= "SUMMARY.md"
        end,
      },
    },
  },
}

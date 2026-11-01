-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here

-- Yank to the local clipboard via OSC 52, which works under WSL, native Linux, tmux and SSH alike.
-- Paste reads the unnamed register, since most terminals refuse OSC 52 clipboard reads.
local osc52 = require("vim.ui.clipboard.osc52")
local function paste()
  return { vim.fn.split(vim.fn.getreg(""), "\n"), vim.fn.getregtype("") }
end
vim.g.clipboard = {
  name = "OSC 52",
  copy = { ["+"] = osc52.copy("+"), ["*"] = osc52.copy("*") },
  paste = { ["+"] = paste, ["*"] = paste },
}
vim.opt.clipboard = "unnamedplus" -- LazyVim leaves this empty over SSH

-- Show absolute and relative line numbers side by side, keeping the snacks signs and folds.
vim.opt.number = false
vim.opt.relativenumber = true
function _G.dual_statuscolumn()
  local win = vim.g.statusline_winid
  local col = package.loaded.snacks and require("snacks.statuscolumn").get() or ""
  if vim.v.virtnum ~= 0 or not vim.wo[win].relativenumber then
    return col
  end
  local width = #tostring(vim.api.nvim_buf_line_count(vim.api.nvim_win_get_buf(win)))
  return ("%" .. width .. "d "):format(vim.v.lnum) .. col
end
vim.opt.statuscolumn = "%!v:lua.dual_statuscolumn()"

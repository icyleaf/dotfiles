-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua
--
-- Add any additional autocmds here
-- with `vim.api.nvim_create_autocmd`
--
-- Or remove existing autocmds by their group name (which is prefixed with `lazyvim_` for the defaults)
-- e.g. vim.api.nvim_del_augroup_by_name("lazyvim_wrap_spell")

-- Globally disable italics for comments and keywords to avoid cursive fonts in terminals
vim.api.nvim_create_autocmd("ColorScheme", {
  pattern = "*",
  callback = function()
    local comment_hl = vim.api.nvim_get_hl(0, { name = "Comment" })
    comment_hl.italic = false
    vim.api.nvim_set_hl(0, "Comment", comment_hl)

    local keyword_hl = vim.api.nvim_get_hl(0, { name = "Keyword" })
    keyword_hl.italic = false
    vim.api.nvim_set_hl(0, "Keyword", keyword_hl)
  end,
})

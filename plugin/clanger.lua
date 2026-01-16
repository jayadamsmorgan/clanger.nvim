vim.cmd([[
  augroup LoadClangerConfig
    autocmd!
    autocmd VimEnter * lua require('clanger').LoadActiveConfiguration()
  augroup END
]])

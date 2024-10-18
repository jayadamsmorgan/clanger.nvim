vim.api.nvim_set_keymap("n", "<leader>cm", ':lua require("clanger").ShowMenu()<CR>', { noremap = true, silent = true })

vim.cmd([[
  augroup LoadClangerConfig
    autocmd!
    autocmd VimEnter * lua require('clanger').LoadActiveConfiguration()
  augroup END
]])

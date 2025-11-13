return {
  'ms-jpq/chadtree',
  build = 'python3 -m chadtree deps',
  opts = {},
  config = function()
    vim.keymap.set('n', '<leader>e', ':CHADopen<CR>', { desc = 'Chadtree' })
    vim.keymap.set('n', '<C-n>', ':CHADopen<CR>', { desc = 'Chadtree' })
  end,
}

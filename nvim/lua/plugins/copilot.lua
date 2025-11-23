return {
  'github/copilot.vim',
  init = function()
    vim.g.copilot_no_tab_map = true
  end,
  config = function()
    vim.keymap.set('i', '<Tab>', function()
      return vim.fn['copilot#Accept'] ''
    end, { expr = true, silent = true, replace_keycodes = false })

    vim.keymap.set('i', '<C-j>', '<Plug>(copilot-next)')
    vim.keymap.set('i', '<C-k>', '<Plug>(copilot-previous)')
  end,
}

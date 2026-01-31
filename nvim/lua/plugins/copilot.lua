return {
  'github/copilot.vim',
  init = function()
    vim.g.copilot_no_tab_map = true
  end,
  config = function()
    vim.keymap.set('i', '<Tab>', function()
      local accepted = vim.fn['copilot#Accept'] ''
      if accepted ~= '' then
        return accepted
      end
      return '\t'
    end, { expr = true, silent = true, replace_keycodes = false })

    vim.keymap.set('i', '<C-j>', '<Plug>(copilot-next)')
    vim.keymap.set('i', '<C-k>', '<Plug>(copilot-previous)')
  end,
}

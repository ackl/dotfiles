return {
  'nvim-treesitter/nvim-treesitter',
  branch = 'main',
  lazy = false,
  build = ':TSUpdate',
  config = function()
    require('nvim-treesitter').setup()
    local ensure_installed = {
      'bash', 'c', 'diff', 'html', 'lua', 'luadoc',
      'markdown', 'markdown_inline', 'query', 'vim', 'vimdoc',
    }
    require('nvim-treesitter').install(ensure_installed)

    vim.api.nvim_create_autocmd('FileType', {
      pattern = ensure_installed,
      callback = function()
        vim.treesitter.start()
        vim.bo.indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
      end,
    })
  end,
}

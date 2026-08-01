return {
  'stevearc/conform.nvim',
  event = { 'BufWritePre' },
  cmd = { 'ConformInfo' },
  keys = {
    {
      '<leader>F',
      function()
        require('conform').format { async = true, lsp_format = 'fallback' }
      end,
      mode = '',
      desc = '[F]ormat buffer',
    },
  },
  opts = {
    notify_on_error = false,
    format_on_save = {
      timeout_ms = 1000,
      lsp_format = 'fallback',
    },
    formatters_by_ft = {
      lua = { 'stylua' },
      html = { 'htmlbeautifier' },
      json = { 'fixjson' },
      javascript = { 'prettier' },
      javascriptreact = { 'prettier' },
      typescript = { 'prettier' },
      typescriptreact = { 'prettier' },
    },
    formatters = {
      prettier = {
        prepend_args = {
          '--tab-width',
          '2',
          '--no-semi',
          '--single-quote',
          '--no-bracket-spacing',
          '--print-width',
          '80',
          '--config-precedence',
          'prefer-file',
        },
      },
    },
  },
}

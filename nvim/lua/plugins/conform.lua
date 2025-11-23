return {
  'stevearc/conform.nvim',
  event = { 'BufWritePre' },
  cmd = { 'ConformInfo' },
  keys = {
    {
      '<leader>p',
      function()
        require('conform').format { async = true, lsp_format = 'fallback' }
      end,
      mode = '',
      desc = '[F]ormat buffer',
    },
  },
  opts = {
    notify_on_error = false,
    format_on_save = function(bufnr)
      return {
        timeout_ms = 250,
        lsp_format = 'fallback',
      }
    end,
    formatters_by_ft = {
      lua = { 'stylua' },

      -- Conform can also run multiple formatters sequentially
      -- python = { "isort", "black" },
      --
      -- You can use 'stop_after_first' to run the first available formatter from the list
      -- javascript = { "prettierd", "prettier", stop_after_first = true },
    },
  },
  formatters = {
    prettier = {
      prepend_args = function()
        return {
          '--tab-width',
          '2',
          '--no-semi',
          '--single-quote',
          '--no-bracket-spacing',
          '--print-width',
          '80',
          '--config-precedence',
          'prefer-file',
        }
      end,
    },
  },
}

vim.env['CODECOMPANION_TOKEN_PATH'] = vim.fn.expand '~/.config'

return {
  'olimorris/codecompanion.nvim',
  dependencies = {
    -- needed to install additional parsers
    { 'nvim-treesitter/nvim-treesitter', build = ':TSUpdate' },
    { 'nvim-lua/plenary.nvim' },
    -- Test with blink.cmp (delete if not required)
    {
      'saghen/blink.cmp',
      lazy = false,
      version = '*',
      opts = {
        keymap = {
          preset = 'enter',
          ['<S-Tab>'] = { 'select_prev', 'fallback' },
          ['<Tab>'] = { 'select_next', 'fallback' },
        },
        cmdline = { sources = { 'cmdline' } },
        sources = {
          default = { 'lsp', 'path', 'buffer', 'codecompanion' },
        },
      },
    },
    -- Test with nvim-cmp
    -- { "hrsh7th/nvim-cmp" },
  },
  --   `adapters.<adapter_name>` and `adapters.opts` is deprecated, use `adapters.http.<adapter_name
  -- >` and `adapters.http.opts` instead.
  -- Feature will be removed in CodeCompanion v18.0.0

  opts = {
    ---@module "codecompanion"
    ---@type CodeCompanion.Config
    adapters = {
      http = {
        acp = {
          gemini_cli = function()
            return require('codecompanion.adapters').extend('gemini_cli', {
              env = {
                GEMINI_API_KEY = 'REDACTED_GOOGLE_KEY',
              },
            })
          end,
        },
        deepseek = function()
          return require('codecompanion.adapters').extend('deepseek', {
            env = {
              api_key = 'cmd:op read op://personal/DeepSeek_API/credential --no-newline',
            },
          })
        end,
        openrouter = function()
          return require('codecompanion.adapters').extend('openai', {
            opts = {
              stream = true,
            },
            env = {
              api_key = 'REDACTED_OPENROUTER_KEY',
            },
            schema = {
              model = {
                default = function()
                  return 'gpt-5'
                end,
              },
            },
          })
        end,
      },
    },
  },
}

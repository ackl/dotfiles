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
      acp = {
        codex = function()
          return require('codecompanion.adapters').extend('codex', {
            defaults = {
              auth_method = 'chatgpt', -- "openai-api-key"|"codex-api-key"|"chatgpt"
            },
          })
        end,
      },
      http = {
        openrouter = function()
          return require('codecompanion.adapters').extend('openai', {
            opts = {
              stream = true,
            },
            env = {
              api_key = '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',
            },
            schema = {
              model = {
                default = function()
                  return 'gpt-5.1'
                end,
              },
            },
          })
        end,
      },
    },
  },
}

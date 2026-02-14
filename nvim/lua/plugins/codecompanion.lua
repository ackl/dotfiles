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
    adapters = {
      acp = {
        gemini_cli = function()
          return require('codecompanion.adapters').extend('gemini_cli', {
            defaults = {
              model = 'gemini-3-flash-preview',
            },
          })
        end,
      },
    },
    interactions = {
      chat = {
        adapter = 'gemini_cli',
      },
      roles = {
        ---The header name for the LLM's messages
        ---@type string|fun(adapter: CodeCompanion.HTTPAdapter|CodeCompanion.ACPAdapter): string
        llm = function(adapter)
          return 'CodeCompanion (' .. adapter.formatted_name .. ')'
        end,

        ---The header name for your messages
        ---@type string
        user = 'Me',
      },
      keymaps = {
        send = {
          modes = { n = '<CR>', i = '<C-s>' },
          opts = {},
        },
        close = {
          modes = { n = '<C-q>', i = '<C-q>' },
          opts = {},
        },
      },
    },
  },
}

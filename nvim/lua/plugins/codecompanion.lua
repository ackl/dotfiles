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
      interactions = {
        chat = {
          adapter = {
            name = 'opencode',
            model = 'gpt-5.2-codex',
          },
        },
      },
    },
  },
}

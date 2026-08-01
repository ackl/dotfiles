-- Use Omarchy's selected theme without importing the LazyVim distribution.
-- Omarchy replaces this generated file when the desktop theme changes;
-- restart Neovim to load the new plugin specification and palette.
local state_dir = vim.env.XDG_STATE_HOME
if not state_dir or state_dir == '' then
  state_dir = vim.fn.expand '~/.local/state'
end
local theme_file = state_dir .. '/omarchy/current/theme/neovim.lua'
if vim.fn.filereadable(theme_file) == 0 then
  return {}
end

local ok, theme = pcall(dofile, theme_file)
if not ok or type(theme) ~= 'table' then
  vim.schedule(function()
    vim.notify('Could not load Omarchy Neovim theme: ' .. theme_file, vim.log.levels.WARN)
  end)
  return {}
end

local plugins = {}
local colorscheme
for _, spec in ipairs(theme) do
  if spec[1] == 'LazyVim/LazyVim' then
    colorscheme = type(spec.opts) == 'table' and spec.opts.colorscheme or nil
  else
    plugins[#plugins + 1] = spec
  end
end

-- Some Omarchy themes (notably Nord) rely on LazyVim's default theme plugin.
-- Supply that dependency ourselves when the theme does not declare it.
if type(colorscheme) == 'string' and colorscheme:match '^tokyonight' then
  local has_tokyonight = false
  for _, spec in ipairs(plugins) do
    local repo = type(spec) == 'table' and spec[1] or spec
    has_tokyonight = has_tokyonight or repo == 'folke/tokyonight.nvim'
  end
  if not has_tokyonight then
    plugins[#plugins + 1] = { 'folke/tokyonight.nvim' }
  end
end

if type(colorscheme) == 'string' then
  -- Dependencies load and configure the theme before applying its colorscheme.
  return {
    {
      name = 'omarchy-theme',
      dir = vim.fn.stdpath 'config',
      lazy = false,
      priority = 1000,
      dependencies = plugins,
      config = function()
        vim.cmd.colorscheme(colorscheme)
      end,
    },
  }
end

return plugins

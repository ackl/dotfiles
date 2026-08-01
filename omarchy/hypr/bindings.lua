-- Keep only your personal keybinding overrides here. Add new bindings or
-- unbind defaults before replacing them.

-- See current bindings and descriptions:
--   omarchy menu keybindings --print

-- To disable every Omarchy default binding, set this in
-- ~/.config/hypr/hyprland.lua before require("default.hypr.omarchy"), then add
-- only the bindings you want below:
--   omarchy_default_bindings = false

-- To disable all preinstalled app/webapp bindings, set:
--   omarchy_preinstalled_bindings = false

-- Add a new binding.
-- o.bind("SUPER + SHIFT + R", "SSH", "alacritty -e ssh your-server")

-- Change an existing binding by unbinding it first, then binding the key again.
-- This example changes SUPER+SPACE from the launcher to the Omarchy root menu.
-- hl.unbind("SUPER + SPACE")
-- o.bind("SUPER + SPACE", "Omarchy menu", "omarchy-menu toggle root")

-- Disable a default binding without replacing it.
-- hl.unbind("SUPER + SHIFT + B")

-- Logitech MX Keys examples:
-- o.bind("SUPER + SHIFT + S", nil, "omarchy-capture-screenshot")
-- o.bind("SUPER + H", nil, "voxtype record toggle")
-- o.bind("SUPER + PERIOD", nil, "omarchy-shell shell toggle omarchy.emojis")

-- Vim-style window focus. Replaces Super-J (toggle split), Super-K
-- (keybindings menu), and Super-L (toggle workspace layout); Super-H was free.
for _, key in ipairs({ "H", "J", "K", "L" }) do
  hl.unbind("SUPER + " .. key)
end

o.bind("SUPER + H", "Focus on left window", hl.dsp.focus({ direction = "l" }))
o.bind("SUPER + J", "Focus on below window", hl.dsp.focus({ direction = "d" }))
o.bind("SUPER + K", "Focus on above window", hl.dsp.focus({ direction = "u" }))
o.bind("SUPER + L", "Focus on right window", hl.dsp.focus({ direction = "r" }))

-- Move with Super-Shift; swap with Super-Alt (replaces Alt-K's Tmux keybindings).
for _, key in ipairs({ "H", "J", "K", "L" }) do
  hl.unbind("SUPER + SHIFT + " .. key)
  hl.unbind("SUPER + ALT + " .. key)
end

o.bind("SUPER + SHIFT + H", "Move window to the left", hl.dsp.window.move({ direction = "l" }))
o.bind("SUPER + SHIFT + J", "Move window down", hl.dsp.window.move({ direction = "d" }))
o.bind("SUPER + SHIFT + K", "Move window up", hl.dsp.window.move({ direction = "u" }))
o.bind("SUPER + SHIFT + L", "Move window to the right", hl.dsp.window.move({ direction = "r" }))

o.bind("SUPER + ALT + H", "Swap window to the left", hl.dsp.window.swap({ direction = "l" }))
o.bind("SUPER + ALT + J", "Swap window down", hl.dsp.window.swap({ direction = "d" }))
o.bind("SUPER + ALT + K", "Swap window up", hl.dsp.window.swap({ direction = "u" }))
o.bind("SUPER + ALT + L", "Swap window to the right", hl.dsp.window.swap({ direction = "r" }))

o.bind("SUPER + B", "Keybindings", "omarchy-menu-keybindings")

-- Replace the unused pseudo-window shortcut with split orientation.
hl.unbind("SUPER + P")
o.bind("SUPER + P", "Toggle window split", hl.dsp.layout("togglesplit"))
o.bind("SUPER + E", "Toggle workspace layout", "omarchy-hyprland-workspace-layout-toggle")

-- Super-Shift-Space replaces the default top-bar toggle.
hl.unbind("SUPER + SHIFT + SPACE")
o.bind("SUPER + SHIFT + SPACE", "Toggle window floating/tiling", hl.dsp.window.float({ action = "toggle" }))

-- Send Ctrl-T with explicit modifiers, using Omarchy's down/up pattern
-- to avoid including the held Super modifier or leaving a key pressed.
hl.unbind("SUPER + T")
o.bind("SUPER + T", "Send Ctrl-T", function()
  hl.dispatch(hl.dsp.send_key_state({ mods = "CTRL", key = "T", state = "down" }))
  hl.timer(function()
    hl.dispatch(hl.dsp.send_key_state({ mods = "CTRL", key = "T", state = "up" }))
  end, { timeout = 50, type = "oneshot" })
end)

-- boilerplate

local config = {}
if wezterm.config_builder then
  config = wezterm.config_builder()
end

-- fonts

config.font = wezterm.font('SF Mono', { weight = 'DemiBold' })
config.font_size = 11.0
config.initial_cols = 110
config.initial_rows = 35

-- window configuration

config.window_decorations = "INTEGRATED_BUTTONS|RESIZE"
config.window_padding = {
  left = 15,
  right = 15,
  top = 50,
  bottom = 10,
}

-- window frame colors
config.window_frame = {
  inactive_titlebar_bg = '#282c34',
  active_titlebar_bg = '#282c34',
  inactive_titlebar_fg = '#cccccc',
  active_titlebar_fg = '#ffffff',
  inactive_titlebar_border_bottom = '#2b2042',
  active_titlebar_border_bottom = '#2b2042',
  button_fg = '#cccccc',
  button_bg = '#2b2042',
  button_hover_fg = '#ffffff',
  button_hover_bg = '#3b3052',
}

-- window content colors
config.colors = {
  foreground = '#dcdfe4',
  background = '#282c34',

  selection_fg = '#000000',
  selection_bg = '#fffacd',

  ansi = {
    '#5d677a',
    '#e06c75',
    '#98c379',
    '#e5c07b',
    '#61afef',
    '#c678dd',
    '#56b6c2',
    '#dcdfe4',
  },
  brights = {
    '#5d677a',
    '#e06c75',
    '#98c379',
    '#e5c07b',
    '#61afef',
    '#c678dd',
    '#56b6c2',
    '#dcdfe4',
  },

  cursor_bg = '#52ad70',
  cursor_fg = 'black',
  cursor_border = '#52ad70',
}

-- tab bar
config.hide_tab_bar_if_only_one_tab = true
config.tab_bar_at_bottom = true

-- cursor
config.default_cursor_style = 'SteadyBar'
config.cursor_thickness = '3px'

return config
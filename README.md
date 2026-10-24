# wez-timer

A countdown timer for WezTerm, shown in the status bar.

Press the key, type a duration (and optionally a label), and the time left shows up in your status bar. When it runs out you get a notification. Press the key again while a timer runs to cancel it.

Durations: `25m`, `90s`, `1h30m`, or a bare number for minutes. Anything after the first word is a label, e.g. `25m tea`.

The timer is kept in `wezterm.GLOBAL`, so it survives config reloads but not a WezTerm restart. Only one timer runs at a time.

## Installation

```lua
local timer = wezterm.plugin.require("https://github.com/roumail/wez-timer")

timer.apply_to_config(config, {
  key = "T",              -- default
  mods = "LEADER|SHIFT",  -- default
  -- called when the timer runs out; defaults to a toast notification
  on_done = function(window, message)
    window:toast_notification("wez-timer", message, nil, 5000)
  end,
})
```

## Status bar

`timer.component()` returns a function for a status-bar section; it renders nothing while no timer runs. With [tabline.wez](https://github.com/michaelbrusegard/tabline.wez):

```lua
tabline.setup({ sections = { tabline_x = { timer.component() } } })
```

`timer.remaining()` returns the plain text (`"tea 04:59"`, or `""`) if you build your own status.

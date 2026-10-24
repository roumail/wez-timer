-- wez_timer.lua

local M = {}

local wezterm = require("wezterm")
local act = wezterm.action

-- wezterm.GLOBAL survives config reloads, not restarts
local KEY = "wez_timer"

local defaults = {
  key = "T",
  mods = "LEADER|SHIFT",
  on_done = nil,
}

local function get()
  return wezterm.GLOBAL[KEY]
end

local function set(timer)
  -- false rather than nil, to be sure GLOBAL drops the old table
  wezterm.GLOBAL[KEY] = timer or false
end

-- "25m", "90s", "1h30m"; a bare number is minutes
function M.parse(input)
  if not input or input == "" then return nil end
  if input:match("^%d+$") then return tonumber(input) * 60 end

  local units = { h = 3600, m = 60, s = 1 }
  local total = 0
  local rest = input:gsub("(%d+)([hms])", function(n, unit)
    total = total + tonumber(n) * units[unit]
    return ""
  end)
  if rest ~= "" or total == 0 then return nil end
  return total
end

local function format(seconds)
  local h = math.floor(seconds / 3600)
  local m = math.floor(seconds % 3600 / 60)
  local s = seconds % 60
  if h > 0 then
    return string.format("%d:%02d:%02d", h, m, s)
  end
  return string.format("%02d:%02d", m, s)
end

-- First word is the duration, the rest an optional label
local function start(window, line)
  local duration, label = line:match("^%s*(%S*)%s*(.-)%s*$")
  local seconds = M.parse(duration)
  if not seconds then
    window:toast_notification("wez-timer", "Can't read duration: " .. line, nil, 3000)
    return
  end
  set({ ends_at = os.time() + seconds, label = label ~= "" and label or nil })
end

local function done(window, timer, opts)
  local message = timer.label or "Timer done"
  if opts.on_done then
    opts.on_done(window, message)
  else
    window:toast_notification("wez-timer", message, nil, 5000)
  end
end

local function toggle(window, pane, opts)
  if get() then
    set(nil)
    window:toast_notification("wez-timer", "Timer cancelled", nil, 2000)
    return
  end
  window:perform_action(
    act.PromptInputLine {
      description = "Timer (25m, 90s, 1h30m, optional label after)",
      action = wezterm.action_callback(function(win, _, line)
        if line then start(win, line) end
      end),
    },
    pane
  )
end

-- Remaining time, for a status bar. Empty when no timer runs.
function M.remaining()
  local timer = get()
  if not timer then return "" end
  local left = math.max(timer.ends_at - os.time(), 0)
  local text = format(left)
  if timer.label then text = timer.label .. " " .. text end
  return text
end

function M.component()
  return function()
    local text = M.remaining()
    if text == "" then return "" end
    return wezterm.format({
      { Text = " " .. wezterm.nerdfonts.md_timer_outline .. " " .. text .. " " },
    })
  end
end

function M.apply_to_config(config, user_opts)
  local opts = {}
  for k, v in pairs(defaults) do opts[k] = v end
  for k, v in pairs(user_opts or {}) do opts[k] = v end

  config.keys = config.keys or {}
  table.insert(config.keys, {
    key = opts.key,
    mods = opts.mods,
    action = wezterm.action_callback(function(window, pane)
      toggle(window, pane, opts)
    end),
  })

  -- Expiry is checked on each status update rather than with
  -- wezterm.time.call_after, whose callbacks are lost on reload
  wezterm.on("update-status", function(window)
    local timer = get()
    if timer and os.time() >= timer.ends_at then
      set(nil)
      done(window, timer, opts)
    end
  end)
end

return M

local converter = require("color-converter.converter")
local utils = require("color-converter.utils")
local config = require("config")
local M = {}

---@alias color { type: "hsl" | "rgb" | "hex"; color_string: string; startpos: number; endpos: number }

-- {{{ Some local DRY utilities

--- Converts an HSL color to a RGB color.
--- @param color_line string -- the HSL color string.
--- @return string|nil
local function from_HSL_to_RGB(color_line)
  local hsl = utils.extract_hsl(color_line)
  if not hsl then
    return
  end

  local rgb_colors = converter.HSL_to_RGB(hsl.h, hsl.s, hsl.l, hsl.a)
  local pattern = config.options.rgb_pattern
  if hsl.a then
    pattern = config.options.rgba_pattern
  end

  return utils.replace_tokens_in_pattern(pattern, {
    r = rgb_colors[1],
    g = rgb_colors[2],
    b = rgb_colors[3],
    a = rgb_colors[4],
  })
end

--- Converts an HSL color to a HEX color.
--- @param color_line string -- the HSL color string.
--- @return string|nil
local function from_HSL_to_Hex(color_line)
  local hsl = utils.extract_hsl(color_line)
  if hsl then
    local hex_color = converter.HSL_to_Hex(hsl.h, hsl.s, hsl.l, hsl.a)
    if config.options.lowercase_hex then
      hex_color = hex_color:lower()
    end
    return hex_color
  end
end

--- Converts a RGB color to an HSL color.
--- @param color_line string -- the RGB color string.
--- @return string|nil
local function from_RGB_to_HSL(color_line)
  local rgb = utils.extract_rgb(color_line)
  if not rgb then
    return
  end

  local hsl_colors = converter.RGB_to_HSL(rgb.r, rgb.g, rgb.b, rgb.a)
  local pattern = config.options.hsl_pattern
  if rgb.a then
    pattern = config.options.hsla_pattern
  end

  -- Apply rounding to saturation and lightness values.
  if config.options.round_hsl then
    hsl_colors[2] = utils.round_float(hsl_colors[2], 0)
    hsl_colors[3] = utils.round_float(hsl_colors[3], 0)
  end

  return utils.replace_tokens_in_pattern(pattern, {
    h = hsl_colors[1],
    s = hsl_colors[2],
    l = hsl_colors[3],
    a = hsl_colors[4],
  })
end

--- Converts a RGB color to a HEX color.
--- @param color_line string -- the RGB color string.
--- @return string|nil
local function from_RGB_to_Hex(color_line)
  local rgb = utils.extract_rgb(color_line)
  if rgb then
    local hex_color = converter.RGB_to_Hex(rgb.r, rgb.g, rgb.b, rgb.a)
    if config.options.lowercase_hex then
      hex_color = hex_color:lower()
    end
    return hex_color
  end
end

--- Converts a HEX color to an HSL color.
--- @param color_line string -- the HEX color string.
--- @return string|nil
local function from_Hex_to_HSL(color_line)
  local hsl_color = converter.Hex_to_HSL(color_line)
  local pattern = config.options.hsl_pattern
  if hsl_color[4] then
    pattern = config.options.hsla_pattern
  end

  -- Apply rounding to saturation and lightness values.
  if config.options.round_hsl then
    hsl_color[2] = utils.round_float(hsl_color[2], 0)
    hsl_color[3] = utils.round_float(hsl_color[3], 0)
  end

  return utils.replace_tokens_in_pattern(pattern, {
    h = hsl_color[1],
    s = hsl_color[2],
    l = hsl_color[3],
    a = hsl_color[4],
  })
end

--- Converts a HEX color to an HSL color.
--- @param color_line string -- the HEX color string.
--- @return string|nil
local function from_Hex_to_RGB(color_line)
  local rgb_color = converter.Hex_to_RGB(color_line)
  local pattern = config.options.rgb_pattern
  if rgb_color[4] then
    pattern = config.options.rgba_pattern
  end

  return utils.replace_tokens_in_pattern(pattern, {
    r = rgb_color[1],
    g = rgb_color[2],
    b = rgb_color[3],
    a = rgb_color[4],
  })
end

--- Gets the color under the cursor, if any.
--- @return color|nil
local function get_color_under_cursor()
  local current_line = vim.api.nvim_get_current_line()
  local cursor = vim.api.nvim_win_get_cursor(0)
  local cursor_col = cursor[2]

  for startpos, match, endpos in current_line:gmatch("()(hsla?%([^)]+%))()") do
    if startpos - 1 <= cursor_col and endpos - 2 >= cursor_col then
      return {
        type = "hsl",
        color_string = match,
        startpos = startpos,
        endpos = endpos - 1,
      }
    end
  end
  for startpos, match, endpos in current_line:gmatch("()(rgba?%([^)]+%))()") do
    if startpos - 1 <= cursor_col and endpos - 2 >= cursor_col then
      return {
        type = "rgb",
        color_string = match,
        startpos = startpos,
        endpos = endpos - 1,
      }
    end
  end
  for startpos, match, endpos in current_line:gmatch("()(#%w+)()") do
    if startpos - 1 <= cursor_col and endpos - 2 >= cursor_col then
      return {
        type = "hex",
        color_string = match,
        startpos = startpos,
        endpos = endpos - 1,
      }
    end
  end

  return nil
end

--- Replaces the color under the cursor with a new one.
--- @param color color -- the color to replace.
--- @param replacement_string string -- the new color to replace the old one with.
local function replace_color_under_cursor(color, replacement_string)
  local cursor = vim.api.nvim_win_get_cursor(0)
  vim.api.nvim_buf_set_text(
    0,
    cursor[1] - 1,
    color.startpos - 1,
    cursor[1] - 1,
    color.endpos,
    { replacement_string }
  )
end

-- }}}

M.to_rgb = function(opts)
  opts = opts or {}
  local current_color = get_color_under_cursor()
  if not current_color then
    return nil
  end

  local new_color
  if current_color.type == "hsl" then
    new_color = from_HSL_to_RGB(current_color.color_string)
  elseif current_color.type == "hex" then
    new_color = from_Hex_to_RGB(current_color.color_string)
  end

  -- Replace the old color with the new color, it not in dry run mode.
  if not opts.dry_run and new_color then
    replace_color_under_cursor(current_color, new_color)
  end
  return new_color
end

M.to_hex = function(opts)
  opts = opts or {}
  local current_color = get_color_under_cursor()
  if not current_color then
    return nil
  end

  local new_color
  if current_color.type == "rgb" then
    new_color = from_RGB_to_Hex(current_color.color_string)
  elseif current_color.type == "hsl" then
    new_color = from_HSL_to_Hex(current_color.color_string)
  end

  -- Replace the old color with the new color, it not in dry run mode.
  if not opts.dry_run and new_color then
    replace_color_under_cursor(current_color, new_color)
  end
  return new_color
end

M.to_hsl = function(opts)
  opts = opts or {}
  local current_color = get_color_under_cursor()
  if not current_color then
    return nil
  end

  local new_color
  if current_color.type == "rgb" then
    new_color = from_RGB_to_HSL(current_color.color_string)
  elseif current_color.type == "hex" then
    new_color = from_Hex_to_HSL(current_color.color_string)
  end

  -- Replace the old color with the new color, it not in dry run mode.
  if not opts.dry_run and new_color then
    replace_color_under_cursor(current_color, new_color)
  end

  return new_color
end

-- cycle will cycle the colors, e.g. HEX => RGB => HSL => HEX
M.cycle = function()
  -- NOTE: The cycle order is the following: HEX => RGB => HSL => HEX.

  local current_color = get_color_under_cursor()
  if not current_color then
    return nil
  end

  local new_color
  if current_color.type == "rgb" then
    new_color = from_RGB_to_HSL(current_color.color_string)
  elseif current_color.type == "hex" then
    new_color = from_Hex_to_RGB(current_color.color_string)
  elseif current_color.type == "hsl" then
    new_color = from_HSL_to_Hex(current_color.color_string)
  end

  if new_color then
    replace_color_under_cursor(current_color, new_color)
  end
end

--- Show a select list allowing the user to pick which format to convert to.
M.pick = function()
  local current_color = get_color_under_cursor()
  if not current_color then
    print("No color found under the cursor.")
    return
  end

  local cursor = vim.api.nvim_win_get_cursor(0)
  vim.ui.select({ "hex", "rgb", "hsl" }, {
    prompt = "Convert color to:",
    format_item = function(item)
      local new_color = M["to_" .. item]({ dry_run = true })
      if new_color then
        return item .. " [" .. new_color .. "]"
      end
      return item .. " [current]"
    end,
  }, function(item)
    -- Ensure that the original cursor position is restored.
    vim.api.nvim_win_set_cursor(0, cursor)
    -- Run the function corresponding to the users's choice.
    M["to_" .. item]()
  end)
end

--- Setup function used to support user configuration.
---@param options Config: user defined configuration options.
M.setup = function(options)
  require("config").__setup(options)
end

return M

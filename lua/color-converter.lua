local converter = require("color-converter.converter")
local utils = require("color-converter.utils")
local config = require("config")
local M = {}

-- {{{ Some local DRY utilities

local function from_HSL_to_RGB(color_line, opts)
  local hsl = utils.extract_hsl(color_line)
  if not hsl then
    return
  end

  local rgb_colors = converter.HSL_to_RGB(hsl.h, hsl.s, hsl.l, hsl.a)
  local pattern = config.options.rgb_pattern
  if hsl.a then
    pattern = config.options.rgba_pattern
  end

  local new_color = utils.replace_tokens_in_pattern(pattern, {
    r = rgb_colors[1],
    g = rgb_colors[2],
    b = rgb_colors[3],
    a = rgb_colors[4],
  })
  if not opts.dry_run then
    vim.cmd(string.format("s/%s/%s", hsl.str:gsub("/", "\\/"), new_color))
  end
  return new_color
end

local function from_HSL_to_Hex(color_line, opts)
  local hsl = utils.extract_hsl(color_line)
  if hsl then
    local hex_color = converter.HSL_to_Hex(hsl.h, hsl.s, hsl.l, hsl.a)
    if config.options.lowercase_hex then
      hex_color = hex_color:lower()
    end
    if not opts.dry_run then
      vim.cmd(string.format("s/%s/%s", hsl.str:gsub("/", "\\/"), hex_color))
    end
    return hex_color
  end
end

local function from_RGB_to_HSL(color_line, opts)
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

  local new_color = utils.replace_tokens_in_pattern(pattern, {
    h = hsl_colors[1],
    s = hsl_colors[2],
    l = hsl_colors[3],
    a = hsl_colors[4],
  })
  if not opts.dry_run then
    vim.cmd(string.format("s/%s/%s", rgb.str:gsub("/", "\\/"), new_color))
  end
  return new_color
end

local function from_RGB_to_Hex(color_line, opts)
  local rgb = utils.extract_rgb(color_line)
  if rgb then
    local hex_color = converter.RGB_to_Hex(rgb.r, rgb.g, rgb.b, rgb.a)
    if config.options.lowercase_hex then
      hex_color = hex_color:lower()
    end
    if not opts.dry_run then
      vim.cmd(string.format("s/%s/%s", rgb.str:gsub("/", "\\/"), hex_color))
    end
    return hex_color
  end
end

local function from_Hex_to_HSL(color_line, opts)
  local hex = color_line:gmatch("(#%w+);?")()
  local hsl_color = converter.Hex_to_HSL(hex)
  local pattern = config.options.hsl_pattern
  if hsl_color[4] then
    pattern = config.options.hsla_pattern
  end

  -- Apply rounding to saturation and lightness values.
  if config.options.round_hsl then
    hsl_color[2] = utils.round_float(hsl_color[2], 0)
    hsl_color[3] = utils.round_float(hsl_color[3], 0)
  end

  local new_color = utils.replace_tokens_in_pattern(pattern, {
    h = hsl_color[1],
    s = hsl_color[2],
    l = hsl_color[3],
    a = hsl_color[4],
  })
  if not opts.dry_run then
    vim.cmd(string.format("s/%s/%s", hex, new_color))
  end
  return new_color
end

local function from_Hex_to_RGB(color_line, opts)
  local hex = color_line:gmatch("(#%w+);?")()
  local rgb_color = converter.Hex_to_RGB(hex)
  local pattern = config.options.rgb_pattern
  if rgb_color[4] then
    pattern = config.options.rgba_pattern
  end

  local new_color = utils.replace_tokens_in_pattern(pattern, {
    r = rgb_color[1],
    g = rgb_color[2],
    b = rgb_color[3],
    a = rgb_color[4],
  })
  if not opts.dry_run then
    vim.cmd(string.format("s/%s/%s", hex, new_color))
  end
  return new_color
end

-- }}}

M.to_rgb = function(opts)
  local current_line = vim.api.nvim_get_current_line()

  if current_line:find("hsl") then
    return from_HSL_to_RGB(current_line, opts or {})
  elseif current_line:find("#%w+") then
    return from_Hex_to_RGB(current_line, opts or {})
  end
end

M.to_hex = function(opts)
  local current_line = vim.api.nvim_get_current_line()

  if current_line:find("rgb") then
    return from_RGB_to_Hex(current_line, opts or {})
  elseif current_line:find("hsl") then
    return from_HSL_to_Hex(current_line, opts or {})
  end
end

M.to_hsl = function(opts)
  local current_line = vim.api.nvim_get_current_line()

  if current_line:find("#%w+") then
    return from_Hex_to_HSL(current_line, opts or {})
  elseif current_line:find("rgb") then
    return from_RGB_to_HSL(current_line, opts or {})
  end
end

-- cycle will cycle the colors, e.g. HEX => RGB => HSL => HEX
M.cycle = function()
  -- NOTE: the cycle order is the following:
  --       HEX => RGB => HSL => HEX

  -- Get the current line in the buffer
  local current_line = vim.api.nvim_get_current_line()

  -- Look for the color and its type, e.g. #21252a is an HEX color
  if current_line:find("rgb") then
    from_RGB_to_HSL(current_line, {})
  elseif current_line:find("#%w+") then
    from_Hex_to_RGB(current_line, {})
  elseif current_line:find("hsl") then
    from_HSL_to_Hex(current_line, {})
  end
end

--- Show a select list allowing the user to pick which format to convert to.
M.pick = function()
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

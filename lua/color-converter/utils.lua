local M = {}

M.round_float = function(num, decimal_points)
  local decimal = math.pow(10, decimal_points)
  return math.floor(num * decimal + 0.5) / decimal
end

--- Converts an <alpha-value> to a decimal value.
---
--- An <alpha-value> is defined as either a number between 0 and 1, or a
--- percentage between 0% and 100%.
--- @see https://developer.mozilla.org/en-US/docs/Web/CSS/alpha-value
---
--- @param alpha string -- the alpha-value string
--- @return number|nil -- the alpha value as a number between 0 and 1
local function alpha_value_to_decimal(alpha)
  if alpha == "none" or string.len(alpha) < 1 then
    return nil
  end

  local alpha_num = tonumber(alpha:gsub("%%", ""), 10)

  -- Make sure that alpha is always returned as a percentage.
  if alpha:match("%%") then
    return alpha_num / 100
  end

  return alpha_num
end

--- Extract h, s, l, a values from color string.
---
--- We need to support both the legacy format and the modern format.
---   <legacy-hsl-syntax> = hsl(<hue> , <percentage> , <percentage> , <alpha-value>?)
---   <modern-hsl-syntax> = hsl([<hue>|none] [<percentage>|<number>|none] [<percentage>|<number>|none] [ / [<alpha-value>|none]]?)
--- @see https://developer.mozilla.org/en-US/docs/Web/CSS/color_value/hsl#values
---
--- @param color_string string -- the HSL color string.
--- @return { str: string, h: number, s: number, l: number, a: number|nil }|nil
M.extract_hsl = function(color_string)
  local str, h, s, l, a =
    color_string:gmatch("(hsla?%(([^ /,]+)[, ]+([^ /,]+)[, ]+([^ /,]+)[ /,]*([^ /,]*)%))")()
  if not str then
    return nil
  end

  local result = { str = str }
  result.h = tonumber(h:gsub("deg", ""):gsub("none", 0), 10)
  -- Convert gradians, radians, and turns to degrees.
  if h:match("grad") then
    -- Represents an angle in gradians. One full circle is 400grad.
    result.h = tonumber(h:gsub("grad", ""), 10) / 400 * 360
  elseif h:match("rad") then
    -- Represents an angle in radians. One full circle is 2π radians which
    -- approximates to 6.2832rad. 1rad is 180/π degrees.
    result.h = tonumber(h:gsub("rad", ""), 10) / (2 * math.pi) * 360
  elseif h:match("turn") then
    -- Represents an angle in a number of turns. One full circle is 1turn.
    result.h = tonumber(h:gsub("turn", ""), 10) * 360
  end

  result.s = tonumber(s:gsub("%%", ""):gsub("none", 0), 10)
  result.l = tonumber(l:gsub("%%", ""):gsub("none", 0), 10)
  result.a = alpha_value_to_decimal(a)
  return result
end

--- Extract r, g, b, a values from color string.
---
--- We need to support both the legacy format and the modean format.
---   <legacy-rgb-syntax> = rgb([<percentage>|<number>]{3} , <alpha-value>?)
---   <modern-rgb-syntax> = rgb([<percentage>|<number>|none]{3} [ / [<alpha-value>|none]]?)
--- @see https://developer.mozilla.org/en-US/docs/Web/CSS/color_value/rgb#values
---
--- @param color_string string -- the RGB color string.
--- @return { str: string, r: number, g: number, b: number, a: number|nil }|nil
M.extract_rgb = function(color_string)
  local str, r, g, b, a =
    color_string:gmatch("(rgba?%(([^ /,]+)[, ]+([^ /,]+)[, ]+([^ /,]+)[ /,]*([^ /,]*)%))")()
  if not str then
    return nil
  end

  local result = { str = str }
  -- Convert percentage to value between 0 and 255.
  result.r = tonumber(r:gsub("%%", ""):gsub("none", 0), 10)
  if r:match("%%") then
    result.r = 255 * result.r / 100
  end

  result.g = tonumber(g:gsub("%%", ""):gsub("none", 0), 10)
  -- Convert percentage to value between 0 and 255.
  if g:match("%%") then
    result.g = 255 * result.g / 100
  end

  result.b = tonumber(b:gsub("%%", ""):gsub("none", 0), 10)
  -- Convert percentage to value between 0 and 255.
  if r:match("%%") then
    result.b = 255 * result.b / 100
  end

  result.a = alpha_value_to_decimal(a)
  return result
end

--- Replace tokens in a given RGB/HSL color pattern.
---
--- Example: replace_tokens_in_pattern('rgb([r]% [g]% [b]%)', { r=255, g=0, b=0 })
--- Output : 'rgb(100% 0% 0%)'
---
--- @param pattern string -- the color pattern with tokens.
--- @param tokens table -- a table of tokens keyed by token name.
--- @return string -- the pattern with tokens replaced.
M.replace_tokens_in_pattern = function(pattern, tokens)
  pattern = pattern:gsub("%%", "%%")
  for k, v in pairs(tokens) do
    -- Try to replace percentage placeholders first.
    if pattern:match("%[" .. k .. "%]%%") then
      if k == "a" then
        v = v * 100
      elseif k == "r" or k == "g" or k == "b" then
        v = v / 255 * 100
      end
      pattern = pattern:gsub("%[" .. k .. "%]%%", v .. "%%")
    else
      if pattern:match("%[" .. k .. "%]grad") then
        v = v / 360 * 400
      elseif pattern:match("%[" .. k .. "%]rad") then
        v = v / 360 * (2 * math.pi)
      elseif pattern:match("%[" .. k .. "%]turn") then
        v = v / 360
      end

      if k == "h" and require("config").options.round_hsl then
        -- Some formats such as turn would be useless without at least two decimals.
        v = M.round_float(v, 2);
      end

      pattern = pattern:gsub("%[" .. k .. "%]", v)
    end
  end

  return pattern
end

return M

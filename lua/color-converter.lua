local converter = require("color-converter.converter")
local utils = require("color-converter.utils")
local M = {}

-- {{{ Some local DRY utilities

local function from_HSL_to_RGB(color_line)
	local hsl = utils.extract_hsl(color_line)
	if not hsl then
		return
	end

	local rgb_colors = converter.HSL_to_RGB(hsl.h, hsl.s, hsl.l, hsl.a)
	local pattern = require("config").options.rgb_pattern
	if hsl.a then
		pattern = require("config").options.rgba_pattern
	end

	vim.cmd(string.format(
		"s/%s/%s",
		hsl.str:gsub("/", "\\/"),
		utils.replace_tokens_in_pattern(pattern, {
			r = rgb_colors[1],
			g = rgb_colors[2],
			b = rgb_colors[3],
			a = rgb_colors[4],
		})
	))
end

local function from_HSL_to_Hex(color_line)
	local hsl = utils.extract_hsl(color_line)
	if hsl then
		local hex_color = converter.HSL_to_Hex(hsl.h, hsl.s, hsl.l, hsl.a)
		vim.cmd(string.format("s/%s/%s", hsl.str:gsub("/", "\\/"), hex_color))
	end
end

local function from_RGB_to_HSL(color_line)
	local rgb = utils.extract_rgb(color_line)
	if not rgb then
		return
	end

	local hsl_colors = converter.RGB_to_HSL(rgb.r, rgb.g, rgb.b, rgb.a)
	local pattern = require("config").options.hsl_pattern
	if rgb.a then
		pattern = require("config").options.hsla_pattern
	end

	-- Apply rounding to saturation and lightness values
	vim.cmd(string.format(
		"s/%s/%s",
		rgb.str:gsub("/", "\\/"),
		utils.replace_tokens_in_pattern(pattern, {
			h = utils.round_float(hsl_colors[1], 0),
			s = utils.round_float(hsl_colors[2], 0),
			l = utils.round_float(hsl_colors[3], 0),
			a = hsl_colors[4],
		})
	))
end
local function from_RGB_to_Hex(color_line)
	local rgb = utils.extract_rgb(color_line)
	if rgb then
		local hex_color = converter.RGB_to_Hex(rgb.r, rgb.g, rgb.b, rgb.a)
		vim.cmd(string.format("s/%s/%s", rgb.str:gsub("/", "\\/"), hex_color))
	end
end

local function from_Hex_to_HSL(color_line)
	local hex = color_line:gmatch("(#%w+);?")()
	local hsl_color = converter.Hex_to_HSL(hex)
	local pattern = require("config").options.hsl_pattern
	if hsl_color[4] then
		pattern = require("config").options.hsla_pattern
	end

	vim.cmd(string.format(
		"s/%s/%s",
		hex,
		utils.replace_tokens_in_pattern(pattern, {
			h = hsl_color[1],
			s = hsl_color[2],
			l = hsl_color[3],
			a = hsl_color[4],
		})
	))
end

local function from_Hex_to_RGB(color_line)
	local hex = color_line:gmatch("(#%w+);?")()
	local rgb_color = converter.Hex_to_RGB(hex)
	local pattern = require("config").options.rgb_pattern
	if rgb_color[4] then
		pattern = require("config").options.rgba_pattern
	end

	vim.cmd(string.format(
		"s/%s/%s",
		hex,
		utils.replace_tokens_in_pattern(pattern, {
			r = rgb_color[1],
			g = rgb_color[2],
			b = rgb_color[3],
			a = rgb_color[4],
		})
	))
end

-- }}}

M.to_rgb = function()
	local current_line = vim.api.nvim_get_current_line()

	if current_line:find('hsl') then
		from_HSL_to_RGB(current_line)
	elseif current_line:find('#%w+') then
		from_Hex_to_RGB(current_line)
	end
end

M.to_hex = function()
	local current_line = vim.api.nvim_get_current_line()

	if current_line:find('rgb') then
		from_RGB_to_Hex(current_line)
	elseif current_line:find('hsl') then
		from_HSL_to_Hex(current_line)
	end
end

M.to_hsl = function()
	local current_line = vim.api.nvim_get_current_line()

	if current_line:find('#%w+') then
		from_Hex_to_HSL(current_line)
	elseif current_line:find('rgb') then
		from_RGB_to_HSL(current_line)
	end
end

-- cycle will cycle the colors, e.g. HEX => RGB => HSL => HEX
M.cycle = function()
	-- NOTE: the cycle order is the following:
	--       HEX => RGB => HSL => HEX

	-- Get the current line in the buffer
	local current_line = vim.api.nvim_get_current_line()

	-- Look for the color and its type, e.g. #21252a is an HEX color
	if current_line:find('rgb') then
		from_RGB_to_HSL(current_line)
	elseif current_line:find('#%w+') then
		from_Hex_to_RGB(current_line)
	elseif current_line:find('hsl') then
		from_HSL_to_Hex(current_line)
	end
end

---@param options Config: user defined configuration options.
M.setup = function(options)
	require("config").__setup(options)
end

return M

-- vim: fdm=marker sw=4 ts=4

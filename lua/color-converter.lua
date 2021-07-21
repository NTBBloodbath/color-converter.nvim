local converter = require('color-converter.converter')

local M = {}

-- {{{ Some local DRY utilities

local function from_HSL_to_RGB(color_line)
	local hsl_colors = {}
	local is_hsla = false

	-- Try to detect HSL before HSLA
	local hsl = color_line:gmatch('hsl%(%d+,%s?[.%d]+%%?,%s?[.%d]+%%?%)')()
	if not hsl then
		hsl = color_line:gmatch('hsla%(%d+,%s?[.%d]+%%?,%s?[.%d]+%%?,%s?[.%d]+%)')()
		is_hsla = true
	end

	-- Remove the "hsl(", ");", "%" and leave only the numbers before
	-- splitting the string
	for _, color_part in ipairs(
		vim.split(is_hsla and hsl:gsub('hsla%(', ''):gsub('%);?', ''):gsub('%%', '') or hsl:gsub('hsl%(', ''):gsub('%);?', ''):gsub('%%', ''), ',')
	) do
		hsl_colors[#hsl_colors + 1] = tonumber(color_part)
	end
	local rgb_colors
	if is_hsla then
		rgb_colors = converter.HSL_to_RGB(
			hsl_colors[1],
			hsl_colors[2],
			hsl_colors[3],
			hsl_colors[4]
		)
		vim.cmd(
			string.format(
				's/%s/rgba(%d, %d, %d, %g)',
				hsl,
				rgb_colors[1],
				rgb_colors[2],
				rgb_colors[3],
				rgb_colors[4]
			)
		)
	else
		rgb_colors = converter.HSL_to_RGB(
			hsl_colors[1],
			hsl_colors[2],
			hsl_colors[3]
		)
		vim.cmd(
			string.format(
				's/%s/rgb(%d, %d, %d)',
				hsl,
				rgb_colors[1],
				rgb_colors[2],
				rgb_colors[3]
			)
		)
	end
end

local function from_HSL_to_Hex(color_line)
	local hsl_colors = {}
	local is_hsla = false

	-- Try to detect HSL before HSLA
	local hsl = color_line:gmatch('hsl%(%d+,%s?[.%d]+%%?,%s?[.%d]+%%?%)')()
	if not hsl then
		hsl = color_line:gmatch('hsla%(%d+,%s?[.%d]+%%?,%s?[.%d]+%%?,%s?[.%d]+%)')()
		is_hsla = true
	end

	-- Remove the "hsl(" / "hsla(", ");", "%" and leave only the numbers before
	-- splitting the string
	for _, color_part in ipairs(
		vim.split(
			is_hsla and hsl:gsub('hsla%(', ''):gsub('%);?', ''):gsub('%%', '')
				or hsl:gsub('hsl%(', ''):gsub('%);?', ''):gsub('%%', ''),
			','
		)
	) do
		hsl_colors[#hsl_colors + 1] = tonumber(color_part)
	end
	local hex_color = converter.HSL_to_Hex(
		hsl_colors[1],
		hsl_colors[2],
		hsl_colors[3]
	)
	vim.cmd(string.format('s/%s/%s', hsl, hex_color))
end

local function from_RGB_to_HSL(color_line)
	local rgb_colors = {}
	local is_rgba = false

	-- Try to detect RGB before RGBA
	local rgb = color_line:gmatch('rgb%(%d+%%?,%s?%d+%%?,%s?%d+%%?%)')()
	if not rgb then
		rgb = color_line:gmatch('rgba%(%d+%%?,%s?%d+%%?,%s?%d+%%?,%s?[.%d]+%)')()
		is_rgba = true
	end

	-- Remove the "rgb(" / "rgba(", ");" and leave only the numbers before
	-- splitting the string
	for _, color_part in ipairs(
		vim.split(
			is_rgba and rgb:gsub('rgba%(', ''):gsub('%);?', '')
				or rgb:gsub('rgb%(', ''):gsub('%);?', ''),
			','
		)
	) do
		rgb_colors[#rgb_colors + 1] = tonumber(color_part)
	end
	local hsl_color
	if is_rgba then
		hsl_color = converter.RGB_to_HSL(
			rgb_colors[1],
			rgb_colors[2],
			rgb_colors[3],
			rgb_colors[4]
		)
		vim.cmd(
			string.format(
				's/%s/hsla(%d, %g%%, %g%%, %g)',
				rgb,
				hsl_color[1],
				hsl_color[2],
				hsl_color[3],
				hsl_color[4]
			)
		)
	else
		hsl_color = converter.RGB_to_HSL(
			rgb_colors[1],
			rgb_colors[2],
			rgb_colors[3]
		)
		vim.cmd(
			string.format(
				's/%s/hsl(%d, %g%%, %g%%)',
				rgb,
				hsl_color[1],
				hsl_color[2],
				hsl_color[3]
			)
		)
	end
end

local function from_RGB_to_Hex(color_line)
	local rgb_colors = {}
	local is_rgba = false

	-- Try to detect RGB before RGBA
	local rgb = color_line:gmatch('rgb%(%d+%%?,%s?%d+%%?,%s?%d+%%?%)')()
	if not rgb then
		rgb = color_line:gmatch('rgba%(%d+%%?,%s?%d+%%?,%s?%d+%%?,%s?[.%d]+%)')()
		is_rgba = true
	end
	-- Remove the "rgb(", ");" and leave only the numbers before
	-- splitting the string
	for _, color_part in ipairs(
		vim.split(
			is_rgba and rgb:gsub('rgba%(', ''):gsub('%);?', '')
				or rgb:gsub('rgb%(', ''):gsub('%);?', ''),
			','
		)
	) do
		rgb_colors[#rgb_colors + 1] = tonumber(color_part)
	end
	local hex_color = converter.RGB_to_Hex(
		rgb_colors[1],
		rgb_colors[2],
		rgb_colors[3]
	)
	vim.cmd(string.format('s/%s/%s', rgb, hex_color))
end

local function from_Hex_to_HSL(color_line)
	local hex = color_line:gmatch('#%w+')()
	-- Remove the trailing semicolon, we don't need it
	hex = hex:gsub(';?', '')

	local hsl_color = converter.Hex_to_HSL(hex)
	vim.cmd(
		string.format(
			's/%s/hsl(%d, %g%%, %g%%)',
			hex,
			hsl_color[1],
			hsl_color[2],
			hsl_color[3]
		)
	)
end

local function from_Hex_to_RGB(color_line)
	local hex = color_line:gmatch('#%w+')()
	-- Remove the trailing semicolon, we don't need it
	hex = hex:gsub(';?', '')

	local rgb_color = converter.Hex_to_RGB(hex)
	vim.cmd(
		string.format(
			's/%s/rgb(%d, %d, %d)',
			hex,
			rgb_color[1],
			rgb_color[2],
			rgb_color[3]
		)
	)
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

return M

-- vim: fdm=marker sw=4 ts=4

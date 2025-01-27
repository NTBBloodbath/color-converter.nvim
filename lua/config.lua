---@class ConfigModule
---@field defaults Config: default options.
---@field options Config: config table extending defaults.
local M = {}

M.defaults = {
  hsl_pattern = "hsl([h]deg [s] [l])",
  hsla_pattern = "hsl([h]deg [s] [l] / [a]%)",
  rgb_pattern = "rgb([r] [g] [b])",
  rgba_pattern = "rgb([r] [g] [b] / [a]%)",
}

---@class Config
---@field hsl_pattern string: the hsl pattern used when generating colors.
---@field hsla_pattern string: the hsla pattern used when generating colors.
---@field rgb_pattern string: the rgb pattern used when generating colors.
---@field rgba_pattern string: the rgba pattern used when generating colors.
M.options = {}

---@param options Config: user defined config to override the defaults.
M.__setup = function(options)
  M.options = vim.tbl_deep_extend("force", {}, M.defaults, options or {})
end

return M

local M = {}

M.defaults = {
  hsl_pattern = "hsl(%d, %g%%, %g%%)",
  hsla_pattern = "hsla(%d, %d%%, %d%%, %g)",
  rgb_pattern = "rgb(%d, %d, %d)",
  rgba_pattern = "rgba(%d, %d, %d, %g)",
}

M.options = {}

M.__setup = function(options)
  M.options = vim.tbl_deep_extend("force", {}, M.defaults, options or {})
end

return M

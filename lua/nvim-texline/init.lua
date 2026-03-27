-- File: lua/nvim-texline/init.lua
local core = require("nvim-texline.core")
local lsp = require("nvim-texline.lsp")

-- Default configuration
local default_config = {
	-- Whether to set up the statusline automatically upon calling setup()
	setup_statusline = true,
	-- The pattern used in the statusline for the navigation section.
	-- The placeholder `%s` will be replaced by the output of `navic_truncated()`.
	nav_pattern = "%%{%s}",
	-- Maximum width of the navigation text as a proportion of the total columns.
	nav_max_width_ratio = 0.35,
	-- Maximum number of section depth
	max_comp = 2,
	-- The statusline string template.
	-- Placeholders:
	--   %branch% -> Output of `git_branch()`
	--   %nav%    -> Formatted navigation text (via `nav_pattern`)
	statusline_template = [[%#LineNr#%branch%%<%f%m%h%r%w  %nav%%= %lav% %l,%c%V %P %-3.([%{mode(1)}]%)]],
	-- statusline_template = [[%#LineNr#%branch%%<%f%m%h%r%w  %lav%%= %l,%c%V %P %-3.([%{mode(1)}]%)]],
}

-- Merge user config with defaults
local config = {}

local M = {}

function M.setup(user_config)
	config = vim.tbl_deep_extend("force", default_config, user_config or {})
	if config.setup_statusline then
		M._apply_statusline()
	end
end

-- Expose core functions
M.git_branch = core.git_branch
M.get_location_tex = core.get_location_tex
M.navic_truncated = function()
	return core.navic_truncated(
		config.nav_max_width_ratio or default_config.nav_max_width_ratio,
		config.max_comp or default_config.max_comp
	)
end
M.get_diagnostic_count = lsp.get_diagnostic_count
M.lsp_diagnostics = lsp.lsp_diagnostics

-- Internal function to apply the statusline
function M._apply_statusline()
	-- Create a helper function accessible to the statusline evaluation context
	_G.StatuslineHelper = {
		git_branch = M.git_branch,
		navic_truncated = M.navic_truncated,
		lsp_diagnostics = M.lsp_diagnostics,
	}

	-- Build the final statusline string
	local statusline = config.statusline_template
		:gsub("%%branch%%", "%%{v:lua.StatuslineHelper.git_branch()}")
		:gsub("%%nav%%", "%%{v:lua.StatuslineHelper.navic_truncated()}")
		:gsub("%%lav%%", "%%{v:lua.StatuslineHelper.lsp_diagnostics()}")
	vim.opt.statusline = statusline
end

-- Function to get the current configuration (for inspection)
function M.get_config()
	return vim.deepcopy(config)
end

return M

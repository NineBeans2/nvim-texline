-- File: lua/nvim-texline/init.lua
local navic = require("nvim-texline.navic")
local lsp = require("nvim-texline.lsp")
local gitbranch = require("nvim-gitbranch")

-- Default configuration
local default_config = {
	-- Whether to set up the statusline automatically upon calling setup()
	setup_statusline = true,
	-- The pattern used in the statusline for the navigation section.
	-- The placeholder `%s` will be replaced by the output of `navic_truncated()`.
	-- Maximum width of the navigation text as a proportion of the total columns.
	nav_max_width_ratio = 0.35,
	-- Maximum number of section depth
	max_comp = 2,
	show_lav = true,
	statusline_template_full = [[%#LineNr#%branch%%<%f%m%h%r%w  %nav%%= %lav% %l,%c%V %P %-3.([%{mode(1)}]%)]],
	togglekey = "<leader>td",
}
-- template without diagnostics
default_config.statusline_template_nolav = default_config.statusline_template_full:gsub("%%lav%%", "")

-- with diagnostics by default
default_config.statusline_template = default_config.statusline_template_full
--
local config = {}
local M = {}
function M.setup(user_config)
	-- autocmd is required otherwise the tex file can be detected correctly
	vim.api.nvim_create_autocmd({ "BufNewFile", "BufRead" }, {
		pattern = "*", -- 匹配所有缓冲区
		callback = function()
			local statusline = ""
			-- Merge user config with defaults
			config = vim.tbl_extend("force", default_config, user_config or {})
			-- don't show lsp diagnostics for tex file by default
			if vim.bo.filetype == "tex" then
				config.show_lav = false
				config.statusline_template = config.statusline_template_nolav
			end
			if config.setup_statusline then
				statusline = M.formulate_statusline()
				vim.opt.statusline = statusline
			end
			vim.keymap.set(
				"n",
				config.togglekey,
				M.toggle_diagnostic,
				{ buffer = true, desc = "toggle statusline diagnostics" }
			)
		end,
	})
end

-- Expose git_branch functions
function M.git_branch()
	local branch_name = gitbranch.name()
	if branch_name then
		return branch_name
	end
	return ""
end

-- Expose navic functions
M.navic_truncated = function()
	return navic.navic_truncated(
		config.nav_max_width_ratio or default_config.nav_max_width_ratio,
		config.max_comp or default_config.max_comp
	)
end
M.lsp_diagnostics = lsp.lsp_diagnostics

-- Internal function to apply the statusline
function M.formulate_statusline()
	-- Create a helper function accessible to the statusline evaluation context
	_G.StatuslineHelper = {
		git_branch = M.git_branch,
		navic_truncated = M.navic_truncated,
		lsp_diagnostics = M.lsp_diagnostics,
		showbug = function()
			return config.show_lav
		end,
	}

	-- Build the final statusline string
	local statusline = config.statusline_template
		:gsub("%%branch%%", "%%{v:lua.StatuslineHelper.git_branch()}")
		:gsub("%%nav%%", "%%{v:lua.StatuslineHelper.navic_truncated()}")
		:gsub("%%lav%%", "%%{v:lua.StatuslineHelper.lsp_diagnostics()}")
	-- :gsub(
	-- 	"%%lav%%",
	-- 	"%%{v:lua.StatuslineHelper.showbug()}"
	-- )
	return statusline
end

function M.toggle_diagnostic()
	local statusline = ""
	if config.setup_statusline then
		if config.show_lav then
			config.show_lav = false
			config.statusline_template = config.statusline_template_nolav
			statusline = M.formulate_statusline()
		else
			config.show_lav = true
			config.statusline_template = config.statusline_template_full
			statusline = M.formulate_statusline()
		end
		vim.opt.statusline = statusline
	end
end

-- vim.keymap.set("n", config.togglekey, M.toggle_diagnostic)
-- vim.keymap.set("n", "<leader>td", M.toggle_diagnostic)
-- Function to get the current configuration (for inspection)
-- function M.get_config()
-- 	return vim.deepcopy(config)
-- end
return M

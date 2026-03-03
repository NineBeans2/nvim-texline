-- File: lua/nvim-texline/core.lua
local M = {}

local gitbranch = require("nvim-gitbranch")
local branch_name = gitbranch.name()

-- function M.git_branch()
-- 	return vim.fn.exists("*gitbranch#name") == 1 and vim.fn["gitbranch#name"]() or ""
-- end
--
function M.git_branch()
	if branch_name then
		return branch_name
	end
	return ""
end

function M.get_location_tex(max_comp)
	local navic = require("nvim-navic")
	local old_data = navic.get_data()
	local new_data = {}

	if old_data then
		local num_comp = 0
		for _, comp in ipairs(old_data) do
			if comp.type == "Module" and num_comp < max_comp then
				table.insert(new_data, comp)
				num_comp = num_comp + 1
			end
		end
	end
	return navic.format_data(new_data)
end

function M.navic_truncated(max_width_ratio, max_comp)
	local navic = require("nvim-navic")
	if not navic.is_available() then
		return ""
	end

	local max_width = math.floor(vim.o.columns * max_width_ratio)
	local location = navic.get_location()
	if vim.bo.filetype == "tex" then
		location = M.get_location_tex(max_comp)
	end

	if #location > max_width then
		location = ".. " .. location:sub(-max_width)
	end
	return location
end

return M

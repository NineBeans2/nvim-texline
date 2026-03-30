local M = {}
-- 缓存以提高性能
local cache = {
	client_diagnostics = {},
	update_time = 0,
}

-- 按命名空间分组获取诊断
function M.get_diagnostics_by_namespace()
	local client_info = {}
	local all_diagnostics = {}

	-- 获取所有诊断
	local diagnostics = vim.diagnostic.get(vim.api.nvim_get_current_buf())

	-- 按命名空间分组
	for _, diag in ipairs(diagnostics) do
		local ns_id = diag.namespace
		-- local ns_id = diag.name
		if not client_info[ns_id] then
			local name = diag.source
			client_info[ns_id] = {
				name = name,
				short_name = name:gsub("_ls$", ""):gsub("%.+-", ""):sub(1, 3),
			}
		end

		if not all_diagnostics[ns_id] then
			all_diagnostics[ns_id] = {
				error = 0,
				warn = 0,
				info = 0,
				hint = 0,
			}
		end

		if diag.severity == vim.diagnostic.severity.ERROR then
			all_diagnostics[ns_id].error = all_diagnostics[ns_id].error + 1
		elseif diag.severity == vim.diagnostic.severity.WARN then
			all_diagnostics[ns_id].warn = all_diagnostics[ns_id].warn + 1
		elseif diag.severity == vim.diagnostic.severity.INFO then
			all_diagnostics[ns_id].info = all_diagnostics[ns_id].info + 1
		elseif diag.severity == vim.diagnostic.severity.HINT then
			all_diagnostics[ns_id].hint = all_diagnostics[ns_id].hint + 1
		end
	end

	return client_info, all_diagnostics
end

-- 格式化客户端诊断显示
function M.format_client_diagnostics(win_id, show_all)
	local now = vim.loop.now()
	show_all = show_all or false
	local mode = vim.api.nvim_get_mode().mode
	-- do not update in insert mode
	if mode:match("^[i]") then
		return cache.client_diagnostics[win_id] -- return cache associated to each window to avoid conflict
	else
		-- use cache（1000ms）
		if now - cache.update_time < 1000 and not show_all then
			return cache.client_diagnostics[win_id] -- return cache associated to each window to avoid conflict
		end
	end

	local client_info, diagnostics_by_ns = M.get_diagnostics_by_namespace()
	local formatted_clients = {}

	for ns_id, diag_counts in pairs(diagnostics_by_ns) do
		local info = client_info[ns_id]
		local client_name = info and info.name or ("ns:" .. ns_id)
		-- local client_name = "test"
		local short_name = info and info.short_name or string.sub(tostring(ns_id), 1, 3)

		-- 构建诊断字符串
		local diag_parts = {}
		if diag_counts.error > 0 then
			table.insert(diag_parts, "E" .. diag_counts.error)
		end
		if diag_counts.warn > 0 then
			table.insert(diag_parts, "W" .. diag_counts.warn)
		end
		if diag_counts.info > 0 then
			table.insert(diag_parts, "I" .. diag_counts.info)
		end
		if diag_counts.hint > 0 then
			table.insert(diag_parts, "H" .. diag_counts.hint)
		end

		-- 只有有诊断时才显示，或者show_all为true时显示所有
		if #diag_parts > 0 or show_all then
			local display_name = show_all and short_name or client_name
			local diag_str = #diag_parts > 0 and ":" .. table.concat(diag_parts, ",") or ""
			table.insert(formatted_clients, {
				name = client_name,
				short_name = short_name,
				display = display_name .. diag_str,
				counts = diag_counts,
				diag_parts = diag_parts,
			})
		end
	end

	-- 按客户端名称排序
	table.sort(formatted_clients, function(a, b)
		return a.name < b.name
	end)

	cache.client_diagnostics[win_id] = formatted_clients -- store cache associated to each window to avoid conflict
	cache.update_time = now

	return formatted_clients
end

-- 在状态栏中显示客户端诊断
function M.statusline_format(win_id, show_all)
	local clients = M.format_client_diagnostics(win_id, show_all)
	local parts = {}

	for _, client in ipairs(clients) do
		local diag_parts = client.diag_parts
		if #diag_parts > 0 then
			table.insert(parts, "[" .. client.name .. "]" .. ":" .. table.concat(diag_parts, ","))
		end
	end

	if #parts > 0 then
		return table.concat(parts, " ")
	else
		return "✓" -- 没有诊断
	end
end
function M.lsp_status()
	local clients = vim.lsp.get_clients({ bufnr = 0 })
	local diagnostics = vim.diagnostic.get(0)
	if #clients == 0 then
		return ""
	end

	local status = {}
	-- for _, client in ipairs(clients) do
	-- 	table.insert(status, client.id)
	-- end
	for _, diagnostic in ipairs(diagnostics) do
		table.insert(status, diagnostic.source)
	end

	return "[" .. table.concat(status, ", ") .. "]"
end

function M.lsp_diagnostics()
	local clients = vim.lsp.get_clients({ bufnr = 0 })
	if #clients == 0 then
		return ""
	end
	local win_id = vim.api.nvim_get_current_win()
	local statusline_format = M.statusline_format(win_id)
	if statusline_format == "" then
		return "✓"
	else
		return statusline_format
	end
end

return M

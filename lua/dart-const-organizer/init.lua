local M = {}

local ts_utils = require("nvim-treesitter.ts_utils")

local function find_const_node()
	local node = ts_utils.get_node_at_cursor()
	local search_path = node:type()
	while node:type() ~= 'const_object_expression' and node:type() ~= 'program' do
		node = node:parent()
		search_path = search_path .. ' -> ' .. node:type()
	end
	print(search_path)
	return node:child(0)
end

local function remove_const(err)
	local node = find_const_node()
	local lnum, start_col, _, end_col = node:range()
	local line = vim.api.nvim_buf_get_lines(0, lnum, lnum + 1, false)[1]
	local new_line = (string.sub(line, 0, start_col) .. string.sub(line, end_col + 2))
	vim.api.nvim_buf_set_lines(0, lnum, lnum + 1, false, { new_line })
end


local function callback(args)
	local errors = vim.diagnostic.get(args.buf, { severity = vim.diagnostic.severity.ERROR })
	for _, err in ipairs(errors) do
		print(err.code)
		if err.code == 'const_with_non_const' or
				err.code == 'const_eval_method_invocation' then
			remove_const(err)
		end
	end
end

function M.setup()
	local group = vim.api.nvim_create_augroup('dart_const_organizer', { clear = true })

	vim.api.nvim_create_autocmd('DiagnosticChanged', {
		pattern = '*.dart',
		group = group,
		callback = callback,
	})
end

return M

local M = {}

-- Параметры плагина
M.config = {
	enabled = true, -- Если false, плагин отключён
	notify = true, -- Если false, уведомления отключены
	keymaps = {
		toggle_resize = "<leader>rw",
		toggle_plugin = "<leader>re",
		vertical_split = "<leader>wv",
		horizontal_split = "<leader>wh",
	},
	notification_icon = "\u{2f56}", -- Иконка для уведомлений
}

local function notify(description, level)
	if M.config.notify then
		vim.notify(
			string.format("%s Buffresize %s", M.config.notification_icon, description),
			level or vim.log.levels.INFO
		)
	end
end

local function is_resizeable(buf)
	local buf_name = vim.api.nvim_buf_get_name(buf):match("([^/]+)$")
	return buf_name == "buffresizevert" or buf_name == "buffresizehori"
end

local function resize_buffer_on_focus(win)
	local buf = vim.api.nvim_win_get_buf(win)
	if not is_resizeable(buf) then
		return
	end

	local win_width = vim.api.nvim_win_get_width(win)
	local new_width = (win_width <= math.floor(vim.o.columns * 0.25)) and math.floor(vim.o.columns * 0.7)
		or math.floor(vim.o.columns * 0.25)
	vim.api.nvim_win_set_width(win, new_width)
end

function M.create_split(direction)
	if not M.config.enabled then
		notify("disable", vim.log.levels.WARN)
		return
	end

	local split_cmd = direction == "vertical" and "vsplit" or "split"
	local buf_name = direction == "vertical" and "buffresizevert" or "buffresizehori"

	vim.cmd(split_cmd)
	local buf = vim.api.nvim_get_current_buf()
	vim.api.nvim_buf_set_name(buf, buf_name)

	local win = vim.api.nvim_get_current_win()
	if direction == "vertical" then
		vim.api.nvim_win_set_width(win, math.floor(vim.o.columns * 0.25))
	else
		vim.api.nvim_win_set_height(win, math.floor(vim.o.lines * 0.25))
	end
end

function M.toggle_resize()
	local win = vim.api.nvim_get_current_win()
	resize_buffer_on_focus(win)
end

function M.toggle_plugin()
	M.config.enabled = not M.config.enabled
	local status = M.config.enabled and "enable" or "disable"
	notify(status)
end

function M.setup(user_config)
	M.config = vim.tbl_deep_extend("force", M.config, user_config or {})

	-- Назначение горячих клавиш
	vim.api.nvim_set_keymap(
		"n",
		M.config.keymaps.toggle_resize,
		"<cmd>lua require('buffresize').toggle_resize()<CR>",
		{ noremap = true, silent = true }
	)
	vim.api.nvim_set_keymap(
		"n",
		M.config.keymaps.toggle_plugin,
		"<cmd>lua require('buffresize').toggle_plugin()<CR>",
		{ noremap = true, silent = true }
	)
	vim.api.nvim_set_keymap(
		"n",
		M.config.keymaps.vertical_split,
		"<cmd>lua require('buffresize').create_split('vertical')<CR>",
		{ noremap = true, silent = true }
	)
	vim.api.nvim_set_keymap(
		"n",
		M.config.keymaps.horizontal_split,
		"<cmd>lua require('buffresize').create_split('horizontal')<CR>",
		{ noremap = true, silent = true }
	)

	-- Авто-команда для обработки изменения размера при фокусе
	vim.api.nvim_create_autocmd("WinEnter", {
		callback = function()
			if M.config.enabled then
				local win = vim.api.nvim_get_current_win()
				resize_buffer_on_focus(win)
			end
		end,
	})
end

return M

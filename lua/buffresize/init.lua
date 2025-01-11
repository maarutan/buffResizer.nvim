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
	min_width = 25, -- Минимальная ширина для сужения (% от ширины окна)
	max_width = 70, -- Максимальная ширина для развёртки (% от ширины окна)
}

local tracked_windows = {}
local manual_resized = {}

local function notify(description, level)
	if M.config.notify then
		vim.notify(
			string.format("%s Buffresize %s", M.config.notification_icon, description),
			level or vim.log.levels.INFO
		)
	end
end

local function is_tracked(win)
	return tracked_windows[win] ~= nil
end

local function resize_tracked_window(win, focus)
	if not is_tracked(win) or manual_resized[win] then
		return
	end

	local win_width = vim.api.nvim_win_get_width(win)
	local total_columns = vim.o.columns
	local min_width = math.floor(total_columns * (M.config.min_width / 100))
	local max_width = math.floor(total_columns * (M.config.max_width / 100))

	if focus then
		if win_width <= min_width then
			vim.api.nvim_win_set_width(win, max_width)
		end
	else
		if win_width >= max_width then
			vim.api.nvim_win_set_width(win, min_width)
		end
	end
end

local function handle_manual_resize(win)
	local win_width = vim.api.nvim_win_get_width(win)
	local total_columns = vim.o.columns
	local min_width = math.floor(total_columns * (M.config.min_width / 100))
	local max_width = math.floor(total_columns * (M.config.max_width / 100))

	if win_width > min_width and win_width < max_width then
		manual_resized[win] = true
	else
		manual_resized[win] = nil
	end
end

function M.create_split(direction)
	if not M.config.enabled then
		notify("disable", vim.log.levels.WARN)
		return
	end

	local split_cmd = direction == "vertical" and "vsplit" or "split"
	vim.cmd(split_cmd)

	local win = vim.api.nvim_get_current_win()
	tracked_windows[win] = true
	manual_resized[win] = nil

	local total_columns = vim.o.columns
	local initial_width = math.floor(total_columns * (M.config.min_width / 100))

	if direction == "vertical" then
		vim.api.nvim_win_set_width(win, initial_width)
	else
		vim.api.nvim_win_set_height(win, math.floor(vim.o.lines * 0.25))
	end

	notify("split created", vim.log.levels.INFO)
end

function M.toggle_resize()
	local win = vim.api.nvim_get_current_win()
	resize_tracked_window(win, true)
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
				resize_tracked_window(win, true)
			end
		end,
	})

	-- Авто-команда для сужения окна при уходе фокуса
	vim.api.nvim_create_autocmd("WinLeave", {
		callback = function()
			if M.config.enabled then
				local win = vim.api.nvim_get_current_win()
				resize_tracked_window(win, false)
			end
		end,
	})

	-- Авто-команда для обработки ручного изменения размера
	vim.api.nvim_create_autocmd("WinResized", {
		callback = function()
			if M.config.enabled then
				local win = vim.api.nvim_get_current_win()
				handle_manual_resize(win)
			end
		end,
	})

	-- Удаление окон из трекинга при закрытии
	vim.api.nvim_create_autocmd("WinClosed", {
		callback = function(event)
			local win = tonumber(event.match)
			tracked_windows[win] = nil
			manual_resized[win] = nil
		end,
	})
end

return M

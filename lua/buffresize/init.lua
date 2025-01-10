-- buffresize.lua
-- Модуль для динамического изменения размера окон в Neovim

local M = {}

-- Настройки по умолчанию
M.config = {
	min_width = 0.25, -- Минимальная ширина окна (в долях от общей ширины)
	max_width = 0.7, -- Максимальная ширина окна (в долях от общей ширины)
	resize_speed = 20, -- Скорость анимации (количество шагов)
	key_toggle = "<leader>rw", -- Клавиша для переключения размера окна
	key_enable = "<leader>re", -- Клавиша для включения/выключения плагина

	-- Список игнорируемых filetype.
	-- Добавляйте или редактируйте по необходимости:
	ignore_filetypes = {
		"NvimTree",
		"neo-tree",
		"NeogitStatus",
		"NeogitPopup",
		"NeogitCommitMessage",
		"dap-repl",
		"toggleterm",
		"yazi",
		"telescope",
		"lazy",
		"mason",
	},

	enabled = true, -- Плагин включён по умолчанию
	notify = true, -- Показывать уведомления о действиях
}

-- Хранилище состояний окон (expanded / не expanded)
local window_states = {}

-- Утилита: получить ширину окна
local function get_window_width(win_id)
	return vim.api.nvim_win_get_width(win_id)
end

-- Утилита: установить ширину окна (если оно валидно)
local function set_window_width(win_id, width)
	if vim.api.nvim_win_is_valid(win_id) then
		vim.api.nvim_win_set_width(win_id, width)
	end
end

-- Проверяем, нужно ли игнорировать данное окно
local function should_ignore_window(win_id)
	if not vim.api.nvim_win_is_valid(win_id) then
		return true
	end

	-- Проверка на плавающее окно
	local win_config = vim.api.nvim_win_get_config(win_id)
	if win_config.relative ~= "" then
		return true
	end

	-- Проверка на filetype
	local buf_id = vim.api.nvim_win_get_buf(win_id)
	local filetype = vim.api.nvim_buf_get_option(buf_id, "filetype")

	-- Проверяем в списке игнорируемых
	for _, ft in ipairs(M.config.ignore_filetypes) do
		if filetype == ft then
			return true
		end
	end

	return false
end

-- Функция плавного (пошагового) изменения размера окна
local function smooth_resize(win_id, target_width, speed)
	if not vim.api.nvim_win_is_valid(win_id) then
		return
	end

	local current_width = get_window_width(win_id)
	local step = (target_width - current_width) / speed

	for i = 1, speed do
		vim.defer_fn(function()
			if vim.api.nvim_win_is_valid(win_id) then
				local new_width = math.floor(current_width + step * i)
				set_window_width(win_id, new_width)
			end
		end, i * 10)
	end
end

-- Обёртка над vim.notify, чтобы можно было легко отключить/включить уведомления
local function notify(msg, level)
	if M.config.notify then
		vim.notify(msg, level or vim.log.levels.INFO)
	end
end

-- Основная логика переключения размера текущего окна
local function toggle_window_size()
	if not M.config.enabled then
		notify("Resize plugin is disabled", vim.log.levels.WARN)
		return
	end

	local win_id = vim.api.nvim_get_current_win()

	if should_ignore_window(win_id) then
		notify("Window ignored due to its filetype or config", vim.log.levels.INFO)
		return
	end

	local total_width = vim.o.columns

	if not window_states[win_id] then
		window_states[win_id] = { expanded = false }
	end

	local target_width
	if window_states[win_id].expanded then
		target_width = math.floor(total_width * M.config.min_width)
	else
		target_width = math.floor(total_width * M.config.max_width)
	end

	smooth_resize(win_id, target_width, M.config.resize_speed)

	window_states[win_id].expanded = not window_states[win_id].expanded

	notify("Window size toggled", vim.log.levels.INFO)
end

-- Включение/выключение всего плагина (глобально)
local function toggle_plugin()
	M.config.enabled = not M.config.enabled
	if M.config.enabled then
		notify("Resize plugin enabled", vim.log.levels.INFO)
	else
		notify("Resize plugin disabled", vim.log.levels.WARN)
	end
end

-- Функция для динамического обновления конфигурации
function M.update_config(new_config)
	-- Проверка на соответствие типов перед обновлением
	if
		new_config.min_width
		and (type(new_config.min_width) ~= "number" or new_config.min_width <= 0 or new_config.min_width >= 1)
	then
		notify("Invalid min_width value. It should be a number between 0 and 1.", vim.log.levels.ERROR)
		return
	end

	if
		new_config.max_width
		and (type(new_config.max_width) ~= "number" or new_config.max_width <= 0 or new_config.max_width >= 1)
	then
		notify("Invalid max_width value. It should be a number between 0 and 1.", vim.log.levels.ERROR)
		return
	end

	if new_config.resize_speed and (type(new_config.resize_speed) ~= "number" or new_config.resize_speed <= 0) then
		notify("Invalid resize_speed value. It should be a positive number.", vim.log.levels.ERROR)
		return
	end

	if new_config.ignore_filetypes and type(new_config.ignore_filetypes) ~= "table" then
		notify("Invalid ignore_filetypes value. It should be a table.", vim.log.levels.ERROR)
		return
	end

	M.config = vim.tbl_extend("force", M.config, new_config or {})
	notify("Plugin configuration updated", vim.log.levels.INFO)
end

-- Основная функция настройки плагина
function M.setup(opts)
	M.config = vim.tbl_extend("force", M.config, opts or {})

	vim.api.nvim_set_keymap(
		"n",
		M.config.key_toggle,
		"<cmd>lua require('buffresize').toggle_window_size()<CR>",
		{ noremap = true, silent = true }
	)

	vim.api.nvim_set_keymap(
		"n",
		M.config.key_enable,
		"<cmd>lua require('buffresize').toggle_plugin()<CR>",
		{ noremap = true, silent = true }
	)

	vim.api.nvim_create_autocmd({ "WinEnter", "BufEnter" }, {
		callback = function()
			local win_id = vim.api.nvim_get_current_win()
			if not should_ignore_window(win_id) then
				local total_width = vim.o.columns
				local target_width = math.floor(total_width * M.config.max_width)
				smooth_resize(win_id, target_width, M.config.resize_speed)
			end
		end,
	})
end

M.toggle_window_size = toggle_window_size
M.toggle_plugin = toggle_plugin
M.update_config = M.update_config

return M

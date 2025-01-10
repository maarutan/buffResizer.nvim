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
	ignore_filetypes = {
		"NvimTree",
		"neo-tree",
		"dap-repl",
		"toggleterm",
		"yazi",
		"telescope",
		"lazy",
		"mason",
	}, -- Список игнорируемых filetype
	enabled = true, -- Плагин включён по умолчанию
	notify = true, -- Показывать уведомления о действиях
}

-- Хранилище состояний окон
local window_states = {}

-- Получить ширину окна
local function get_window_width(win_id)
	return vim.api.nvim_win_get_width(win_id)
end

-- Установить ширину окна
local function set_window_width(win_id, width)
	if vim.api.nvim_win_is_valid(win_id) then
		vim.api.nvim_win_set_width(win_id, width)
	end
end

-- Проверяем, нужно ли игнорировать текущее окно
-- (По filetype, по плавающему типу окна и т.д.)
local function should_ignore_window(win_id)
	-- Если окно плавающее, игнорируем
	local win_config = vim.api.nvim_win_get_config(win_id)
	if win_config.relative ~= "" then
		return true
	end

	local buf_id = vim.api.nvim_win_get_buf(win_id)
	local filetype = vim.api.nvim_buf_get_option(buf_id, "filetype")

	for _, ft in ipairs(M.config.ignore_filetypes) do
		if filetype == ft then
			return true
		end
	end

	return false
end

-- Функция плавного (пошагового) изменения размера окна
local function smooth_resize(win_id, target_width, speed)
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

-- Обёртка для уведомлений с учётом настроек
local function notify(msg, level)
	if M.config.notify then
		vim.notify(msg, level or vim.log.levels.INFO)
	end
end

-- Логика переключения размера текущего окна (между min и max)
local function toggle_window_size()
	if not M.config.enabled then
		notify("Resize plugin is disabled", vim.log.levels.WARN)
		return
	end

	local win_id = vim.api.nvim_get_current_win()

	-- Если окно в списке игнорируемых, выходим
	if should_ignore_window(win_id) then
		notify("Window ignored due to its filetype or config", vim.log.levels.INFO)
		return
	end

	local total_width = vim.o.columns
	local win_width = get_window_width(win_id)

	-- Инициализируем состояние окна, если его нет в таблице
	if not window_states[win_id] then
		window_states[win_id] = { expanded = false }
	end

	-- Вычисляем целевую ширину
	local target_width
	if window_states[win_id].expanded then
		target_width = math.floor(total_width * M.config.min_width)
	else
		target_width = math.floor(total_width * M.config.max_width)
	end

	-- Запускаем плавное изменение размера
	smooth_resize(win_id, target_width, M.config.resize_speed)

	-- Обновляем состояние
	window_states[win_id].expanded = not window_states[win_id].expanded
	notify("Window size toggled", vim.log.levels.INFO)
end

-- Функция для изменения размера окна при получении фокуса
local function resize_on_focus()
	if not M.config.enabled then
		return
	end

	local win_id = vim.api.nvim_get_current_win()

	if should_ignore_window(win_id) then
		return
	end

	local total_width = vim.o.columns
	local target_width = math.floor(total_width * M.config.max_width)
	smooth_resize(win_id, target_width, M.config.resize_speed)
end

-- Включение/выключение плагина
local function toggle_plugin()
	M.config.enabled = not M.config.enabled
	if M.config.enabled then
		notify("Resize plugin enabled", vim.log.levels.INFO)
	else
		notify("Resize plugin disabled", vim.log.levels.WARN)
	end
end

-- Функция для динамического обновления конфигурации (если нужно)
function M.update_config(new_config)
	M.config = vim.tbl_extend("force", M.config, new_config or {})
	notify("Plugin configuration updated", vim.log.levels.INFO)
end

-- Основная функция настройки плагина
function M.setup(opts)
	M.config = vim.tbl_extend("force", M.config, opts or {})

	-- Клавиши для переключения размера окна
	vim.api.nvim_set_keymap(
		"n",
		M.config.key_toggle,
		"<cmd>lua require('buffresize').toggle_window_size()<CR>",
		{ noremap = true, silent = true }
	)

	-- Клавиши для включения/выключения плагина
	vim.api.nvim_set_keymap(
		"n",
		M.config.key_enable,
		"<cmd>lua require('buffresize').toggle_plugin()<CR>",
		{ noremap = true, silent = true }
	)

	-- Автокоманда для resize на фокус
	vim.api.nvim_create_autocmd({ "WinEnter", "BufEnter" }, {
		callback = function()
			local win_id = vim.api.nvim_get_current_win()
			if not should_ignore_window(win_id) then
				resize_on_focus()
			end
		end,
	})
end

-- Экспортируем функции
M.toggle_window_size = toggle_window_size
M.toggle_plugin = toggle_plugin
M.update_config = M.update_config

return M

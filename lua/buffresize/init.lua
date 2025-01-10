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
-- 1. Если окно плавающее (relative ~= ""), то игнорируем
-- 2. Если filetype входит в список игнорируемых, то игнорируем
-- 3. При желании можно дополнить проверками на buftype и т.д.
local function should_ignore_window(win_id)
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
		-- Если нужно игнорировать точное совпадение:
		-- if filetype == ft then
		--   return true
		-- end

		-- Если нужно игнорировать и с учётом возможных вариаций (например, "neo-tree")
		-- начинающихся/содержащих что-то, можно так:
		if filetype:lower():match(ft:lower()) then
			return true
		end
	end

	return false
end

-- Функция плавного (пошагового) изменения размера окна
-- Используем vim.defer_fn, чтобы не блокировать основной поток
local function smooth_resize(win_id, target_width, speed)
	local current_width = get_window_width(win_id)
	if not vim.api.nvim_win_is_valid(win_id) then
		return
	end

	local step = (target_width - current_width) / speed

	-- Создаём "анимацию" через defer_fn
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
-- Между M.config.min_width и M.config.max_width
local function toggle_window_size()
	if not M.config.enabled then
		notify("Resize plugin is disabled", vim.log.levels.WARN)
		return
	end

	local win_id = vim.api.nvim_get_current_win()

	-- Игнорируем окно, если оно соответствует критериям ignore
	if should_ignore_window(win_id) then
		notify("Window ignored due to its filetype or config", vim.log.levels.INFO)
		return
	end

	local total_width = vim.o.columns

	-- Инициализируем состояние окна, если ещё нет
	if not window_states[win_id] then
		window_states[win_id] = { expanded = false }
	end

	local target_width
	if window_states[win_id].expanded then
		-- Если окно уже "expanded", переключаем на min_width
		target_width = math.floor(total_width * M.config.min_width)
	else
		-- Если окно не "expanded", переключаем на max_width
		target_width = math.floor(total_width * M.config.max_width)
	end

	-- Плавно меняем размер
	smooth_resize(win_id, target_width, M.config.resize_speed)

	-- Переключаем флаг expanded
	window_states[win_id].expanded = not window_states[win_id].expanded

	notify("Window size toggled", vim.log.levels.INFO)
end

-- Функция для изменения размера окна при получении фокуса
-- (срабатывает на WinEnter/BufEnter)
local function resize_on_focus()
	if not M.config.enabled then
		return
	end

	local win_id = vim.api.nvim_get_current_win()

	-- Игнорируем окно, если попадает под критерии
	if should_ignore_window(win_id) then
		return
	end

	local total_width = vim.o.columns
	local target_width = math.floor(total_width * M.config.max_width)

	smooth_resize(win_id, target_width, M.config.resize_speed)
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
	M.config = vim.tbl_extend("force", M.config, new_config or {})
	notify("Plugin configuration updated", vim.log.levels.INFO)
end

-- Основная функция настройки плагина
function M.setup(opts)
	-- Слияние пользовательских опций с опциями по умолчанию
	M.config = vim.tbl_extend("force", M.config, opts or {})

	-- Клавиша для переключения размера окна
	vim.api.nvim_set_keymap(
		"n",
		M.config.key_toggle,
		"<cmd>lua require('buffresize').toggle_window_size()<CR>",
		{ noremap = true, silent = true }
	)

	-- Клавиша для включения/выключения плагина
	vim.api.nvim_set_keymap(
		"n",
		M.config.key_enable,
		"<cmd>lua require('buffresize').toggle_plugin()<CR>",
		{ noremap = true, silent = true }
	)

	-- Автокоманда: при входе в окно или буфер — проверяем, не нужно ли изменить размер
	vim.api.nvim_create_autocmd({ "WinEnter", "BufEnter" }, {
		callback = function()
			local win_id = vim.api.nvim_get_current_win()
			if not should_ignore_window(win_id) then
				resize_on_focus()
			end
		end,
	})
end

-- Экспортируем нужные функции
M.toggle_window_size = toggle_window_size
M.toggle_plugin = toggle_plugin
M.update_config = M.update_config

return M

local BuffResize = {}

-- Конфигурация
BuffResize.config = {
	enabled = true,
	notify = true,
	keys = {
		toggle_resize = "<leader>rw",
		toggle_plugin = "<leader>re",
	},
	notification_icon = "\u{fb96}", -- 
	notification_enable_msg = "Buffresize enabled",
	notification_disable_msg = "Buffresize disabled",
	expanded_width = 70,
	collapsed_width = 25,

	-- (!!!) Дополнительно (опционально):
	-- Список filetype’ов или buftype’ов, которые хотим игнорировать.
	ignore_filetypes = { "qf", "help" },
	ignore_buftypes = { "terminal" },
}

-- Состояние плагина
BuffResize.state = {
	-- (!!!) Вместо булевских флагов здесь храним исходный размер,
	-- чтобы при повторном вызове вернуть окно к первоначальному состоянию.
	-- Формат: BuffResize.state.resized_buffers[win_id] = original_width
	resized_buffers = {},
}

-- Хелпер для уведомлений
local function notify(msg, level)
	if BuffResize.config.notify then
		vim.notify(msg, level or vim.log.levels.WARN, { icon = BuffResize.config.notification_icon })
	end
end

-- (!!!) Функция для определения, нужно ли игнорировать конкретное окно
local function should_ignore_window(win_id)
	-- Проверяем, не является ли окно плавающим
	local cfg = vim.api.nvim_win_get_config(win_id)
	if cfg.relative ~= "" then
		return true
	end

	local bufnr = vim.api.nvim_win_get_buf(win_id)
	local buftype = vim.bo[bufnr].buftype
	local filetype = vim.bo[bufnr].filetype

	-- Игнорируем, если buftype есть в ignore_buftypes
	for _, btype in ipairs(BuffResize.config.ignore_buftypes or {}) do
		if buftype == btype then
			return true
		end
	end

	-- Игнорируем, если filetype есть в ignore_filetypes
	for _, ftype in ipairs(BuffResize.config.ignore_filetypes or {}) do
		if filetype == ftype then
			return true
		end
	end

	return false
end

-- (!!!) Функция, в которой реализована логика изменения ширины окна
local function resize_window()
	if not BuffResize.config.enabled then
		notify(BuffResize.config.notification_disable_msg, vim.log.levels.WARN)
		return
	end

	local win_id = vim.api.nvim_get_current_win()
	local current_width = vim.api.nvim_win_get_width(win_id)

	-- Проверяем, не нужно ли игнорировать данное окно
	if should_ignore_window(win_id) then
		return
	end

	-- Если окно ещё не "трогали"
	if BuffResize.state.resized_buffers[win_id] == nil then
		-- Сохраняем исходный размер
		BuffResize.state.resized_buffers[win_id] = current_width

		-- (!!!) Можно проверить, не больше ли expanded_width общей ширины экрана
		local total_cols = vim.o.columns
		local target_width = math.min(BuffResize.config.expanded_width, total_cols)

		vim.api.nvim_win_set_width(win_id, target_width)
	else
		-- Окно уже расширено - вернём ему исходный размер
		local original_width = BuffResize.state.resized_buffers[win_id]

		-- Если вдруг original_width <= collapsed_width,
		-- то можно, при желании, выставить строго collapsed_width
		-- Но тут вернём именно original_width:
		vim.api.nvim_win_set_width(win_id, original_width)

		-- Убираем из списка "тронутых" окон
		BuffResize.state.resized_buffers[win_id] = nil
	end
end

-- Сброс состояния — если нужно обнулить все расширенные окна
local function reset_resized_buffers()
	BuffResize.state.resized_buffers = {}
end

-- Тоглим включение/выключение плагина
function BuffResize.toggle_plugin()
	BuffResize.config.enabled = not BuffResize.config.enabled
	local msg = BuffResize.config.enabled and BuffResize.config.notification_enable_msg
		or BuffResize.config.notification_disable_msg

	notify(msg, vim.log.levels.WARN)
end

-- Вызываем resize логику вручную
function BuffResize.toggle_resize()
	resize_window()
end

-- Инициализация плагина
function BuffResize.setup(config)
	-- Сливаем пользовательские настройки с дефолтными
	BuffResize.config = vim.tbl_extend("force", BuffResize.config, config or {})

	-- Устанавливаем горячие клавиши (если указаны)
	if BuffResize.config.keys.toggle_resize then
		vim.api.nvim_set_keymap(
			"n",
			BuffResize.config.keys.toggle_resize,
			":lua require('buffresize').toggle_resize()<CR>",
			{ noremap = true, silent = true }
		)
	end

	if BuffResize.config.keys.toggle_plugin then
		vim.api.nvim_set_keymap(
			"n",
			BuffResize.config.keys.toggle_plugin,
			":lua require('buffresize').toggle_plugin()<CR>",
			{ noremap = true, silent = true }
		)
	end

	-- Автокоманда: при входе в окно — разворачиваем (если нужно)
	vim.api.nvim_create_autocmd("WinEnter", {
		callback = function()
			if BuffResize.config.enabled then
				resize_window()
			end
		end,
	})

	-- Автокоманда: при выходе из окна — сбрасываем состояния (!!!)
	-- Но это значит, что как только вы покинете окно,
	-- оно уже не будет "рассчитано" как "развернутое" при возвращении назад.
	-- Если хотите, чтобы окна оставались расширенными, пока не нажмёте toggle_resize,
	-- можно убрать этот сброс или изменить логику.
	vim.api.nvim_create_autocmd("WinLeave", {
		callback = function()
			reset_resized_buffers()
		end,
	})
end

return BuffResize

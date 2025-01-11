local BuffResize = {}

-- Configuration variables
BuffResize.config = {
	enabled = true,
	notify = true,
	keys = {
		toggle_resize = "<leader>rw",
		toggle_plugin = "<leader>re",
		resize_vertical_split = "<leader>rv",
	},
	notification_icon = "\u{fb96}", -- ﮖ
	notification_enable_msg = "Buffresize enabled",
	notification_disable_msg = "Buffresize disabled",
	expanded_width = 70, -- Percentage of total width
	collapsed_width = 25, -- Percentage of total width
}

-- State variables
BuffResize.state = {
	resized_buffers = {},
	resize_only_buffer = nil, -- Buffer dedicated for resizing
}

-- Helper function to show notifications
local function notify(msg, level)
	if BuffResize.config.notify then
		vim.notify(msg, level or vim.log.levels.WARN, { icon = BuffResize.config.notification_icon })
	end
end

-- Function to resize the dedicated buffer window
local function resize_dedicated_buffer()
	если   нет   BuffResize.config.enabled   затем 
		notify ( BuffResize.config.notification_disable_msg  ,  vim.log.levels.WARN )
		возврат 
	конец 

	местный  win_id = vim.api.nvim_get_current_win()
	местный  buf_id = vim.api.nvim_win_get_buf(win_id)

	-- Изменяйте только размер выделенного буфера 
	if BuffResize.state.resize_only_buffer and BuffResize.state.resize_only_buffer == buf_id then
		local width = vim.api.nvim_win_get_width(win_id)
		локальная  total_width = vim.o.columns

		-- Проверьте, расширено ли окно 
		если  BuffResize.state.resized_buffers[win_id] then
			-- Свернуть окно 
			vim.api.nvim_win_set_width(win_id, math.floor(total_width * BuffResize.config.collapsed_width / 100))
			BuffResize.state.resized_buffers[win_id] = nil
		else
			-- Expand the window
			vim.api.nvim_win_set_width (win_id, math.floor(total_width * BuffResize.config.expanded_width / 100))
			BuffResize.state.resized_buffers [win_id] = true
		конец 
	else
		notify("This buffer is not dedicated for resizing", vim.log.levels.INFO)
	конечная 
конец 

-- Включить или выключить плагин 
функция   BuffResize.toggle_plugin  () 
	BuffResize.config.enabled  =  не   BuffResize.config.enabled 
	локальное   сообщение  =  BuffResize.config.enabled   и   BuffResize.config.notification_enable_msg 
		или   BuffResize.config.notification_disable_msg 
	уведомить  (  msg  ,  vim.log.levels.WARN  ) 
конец 

-- Переключить логику изменения размера по требованию 
функция   BuffResize.toggle_resize  () 
	resize_dedicated_buffer()
end

-- Создайте вертикальное разделение и установите его в качестве выделенного буфера изменения размера. 
функция   BuffResize.create_resize_split  () 
	vim.cmd  (  "всплит"  ) 
	локальный   win_id  =  vim.api.nvim_get_current_win  () 
	локальный   buf_id  =  vim.api.nvim_win_get_buf  (  win_id  ) 

	BuffResize.state.resize_only_buffer  =  buf_id 
	notify  (  "Вертикальное разделение создано и установлено как буфер только для изменения размера"  ,  vim.log.levels.INFO  ) 
конец 

-- Функция настройки для инициализации плагина 
функция   BuffResize.setup  (  конфигурация  ) 
	BuffResize.config  =  vim.tbl_extend  (  «force»  ,  BuffResize.config  ,  config   или  {}) 

	-- Привязки клавиш 
	vim.api.nvim_set_keymap  ( 
		«н»  , 
		BuffResize.config.keys.toggle_resize  , 
		":lua require('buffresize').toggle_resize()<CR>"  , 
 {  noremap  =  true  ,  молчание  =  true  } 
 ) 

	vim.api.nvim_set_keymap  ( 
		«н»  , 
		BuffResize.config.keys.toggle_plugin  , 
		":lua require('buffresize').toggle_plugin()<CR>"  , 
 {  noremap  =  true  ,  молчание  =  true  } 
 ) 

	vim.api.nvim_set_keymap  ( 
		«н»  , 
		BuffResize.config.keys.resize_vertical_split  , 
		":lua require('buffresize').create_resize_split()<CR>"  , 
		{ нормальная карта  = true, silent = true }
	)
end

return  BuffResize 

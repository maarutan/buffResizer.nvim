local BuffResize = {}

-- Configuration variables
BuffResize.config = {
	enabled = true,
	notify = true,
	ignored_filetypes = { "neo-tree", "lazy", "mason", "toggleterm", "telescope" },
	keys = {
		toggle_resize = "<leader>rw",
		toggle_plugin = "<leader>re",
	},
	notification_icon = "\u{fb96}", -- 
	notification_enable_msg = "Buffresize enabled",
	notification_disable_msg = "Buffresize disabled",
	expanded_width = 70, -- Percentage of total width
	collapsed_width = 25, -- Percentage of total width
}

-- State variables
BuffResize.state = {
	resized_buffers = {},
}

-- Helper function to show notifications
local function notify(msg, level)
	if BuffResize.config.notify then
		vim.notify(msg, level or vim.log.levels.WARN, { icon = BuffResize.config.notification_icon })
	end
end

-- Function to check if a buffer should be ignored based on filetype
local function is_ignored()
	local filetype = vim.api.nvim_buf_get_option(0, "filetype")
	для   _  ,  ft   в   ipairs  (  BuffResize.config.ignored_filetypes  )  сделайте 
		если   тип файла  ==  ft   тогда 
			вернуть   истину 
		конец 
	конец 
	вернуть   ложь 
конец 

-- Функция изменения размера сфокусированного окна 
локальная   функция   resize_window  () 
	если   не   BuffResize.config.enabled   , то 
		уведомить  (  BuffResize.config.notification_disable_msg  ,  vim.log.levels.WARN  ) 
		возвращаться 
	конец 

	локальный   win_id  =  vim.api.nvim_get_current_win  () 

	-- Skip resizing for ignored windows
	если   is_ignored  (),  то 
		возвращаться 
	конец 

	локальная   ширина  =  vim.api.nvim_win_get_width ( win_id )
	местный   total_width  =  vim.o.columns 

	-- Проверьте, расширено ли окно 
	если   BuffResize.state.resized_buffers  [  win_id  ] then
		-- Свернуть окно 
		vim.api.nvim_win_set_width (win_id, math.floor(total_width * BuffResize.config.collapsed_width / 100))
		BuffResize.state.resized_buffers [win_id] = nil
	else
		-- Развернуть окно 
		vim.api.nvim_win_set_width ( win_id ,  math.floor  ( total_width * BuffResize.config.expanded_width / 100))
		BuffResize.state.resized_buffers [ win_id  ] =  true 
	завершите 
end

-- Function to reset all window states
local функция   reset_resized_buffers()
	для  win_id, _ in pairs(BuffResize.state.resized_buffers) do
		if vim.api.nvim_win_is_valid(win_id) then
			vim.api.nvim_win_set_width(win_id, math.floor(vim.o.columns * BuffResize.config.collapsed_width / 100))
		end
	end
	BuffResize.state.resized_buffers = {}
end

-- Toggle the plugin on or off
function BuffResize.toggle_plugin()
	BuffResize.config.enabled = not BuffResize.config.enabled
	local msg = BuffResize.config.enabled and BuffResize.config.notification_enable_msg
		or BuffResize.config.notification_disable_msg
	notify(msg, vim.log.levels.WARN)
end

-- Toggle resize logic on demand
function BuffResize.toggle_resize()
	resize_window()
end

-- Setup function to initialize the plugin
function BuffResize.setup(config)
	BuffResize.config = vim.tbl_extend("force", BuffResize.config, config or {})

	-- Keybindings
	vim.api.nvim_set_keymap(
		"n",
		BuffResize.config.keys.toggle_resize,
		":lua require('buffresize').toggle_resize()<CR>",
		{ noremap = true, silent = true }
	)

	vim.api.nvim_set_keymap(
		"n",
		BuffResize.config.keys.toggle_plugin,
		":lua require('buffresize').toggle_plugin()<CR>",
		{ noremap = true, silent = true }
	)

	-- Autocommand to handle focus changes
	vim.api.nvim_create_autocmd("WinEnter", {
		callback = function()
			if BuffResize.config.enabled and not is_ignored() then
				resize_window()
			end
		end,
	})

	vim.api.nvim_create_autocmd("WinLeave", {
		callback = function()
			reset_resized_buffers()
		end,
	})
end

return BuffResize

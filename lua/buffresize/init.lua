-- Module for dynamic window resizing in Neovim
local M = {}

-- Default settings
M.config = {
	min_width = 0.25, -- Minimum window width (as a percentage of total width)
	max_width = 0.7, -- Maximum window width (as a percentage of total width)
	resize_speed = 20, -- Window resize speed (in steps)
	key_toggle = "<leader>rw", -- Key binding to toggle window size
	key_enable = "<leader>re", -- Key binding to enable/disable the plugin
	ignore_filetypes = { "NvimTree", "neo-tree", "dap-repl" }, -- Filetypes to ignore
	enabled = true, -- Whether the plugin is enabled by default
}

-- Table to store window states
local window_states = {}

-- Function to get the window width
local function get_window_width(win_id)
	return vim.api.nvim_win_get_width(win_id)
end

-- Function to set the window width
local function set_window_width(win_id, width)
	vim.api.nvim_win_set_width(win_id, width)
end

-- Check if the window should be ignored
local function should_ignore_window(win_id)
	local buf_id = vim.api.nvim_win_get_buf(win_id)
	local filetype = vim.api.nvim_buf_get_option(buf_id, "filetype")
	for _, ft in ipairs(M.config.ignore_filetypes) do
		if filetype == ft then
			return true
		end
	end
	return false
end

-- Function for smooth window resizing
local function smooth_resize(win_id, target_width, speed)
	local current_width = get_window_width(win_id)
	local step = (target_width - current_width) / speed

	for i = 1, speed do
		vim.defer_fn(function()
			local new_width = math.floor(current_width + step * i)
			set_window_width(win_id, new_width)
		end, i * 10)
	end
end

-- Main logic for toggling window size
local function toggle_window_size()
	if not M.config.enabled then
		return
	end

	local win_id = vim.api.nvim_get_current_win()

	-- Ignore the window if its filetype is in the ignore list
	if should_ignore_window(win_id) then
		return
	end

	local total_width = vim.o.columns
	local win_width = get_window_width(win_id)

	-- Initialize window state
	if not window_states[win_id] then
		window_states[win_id] = { expanded = false }
	end

	-- Determine target size
	local target_width
	if window_states[win_id].expanded then
		target_width = math.floor(total_width * M.config.min_width)
	else
		target_width = math.floor(total_width * M.config.max_width)
	end

	-- Perform smooth resize
	smooth_resize(win_id, target_width, M.config.resize_speed)

	-- Update window state
	window_states[win_id].expanded = not window_states[win_id].expanded
end

-- Function to enable/disable the plugin
local function toggle_plugin()
	M.config.enabled = not M.config.enabled
	if M.config.enabled then
		print("Resize plugin enabled")
	else
		print("Resize plugin disabled")
	end
end

-- Function to dynamically update settings
function M.update_config(new_config)
	M.config = vim.tbl_extend("force", M.config, new_config or {})
	print("Plugin configuration updated dynamically")
end

-- Function to configure the module
function M.setup(opts)
	M.config = vim.tbl_extend("force", M.config, opts or {})

	-- Set key binding for toggling window size
	vim.api.nvim_set_keymap(
		"n",
		M.config.key_toggle,
		"<cmd>lua require'buffresize'.toggle_window_size()<CR>",
		{ noremap = true, silent = true }
	)

	-- Set key binding for enabling/disabling the plugin
	vim.api.nvim_set_keymap(
		"n",
		M.config.key_enable,
		"<cmd>lua require'buffresize'.toggle_plugin()<CR>",
		{ noremap = true, silent = true }
	)
end

-- Export functions
M.toggle_window_size = toggle_window_size
M.toggle_plugin = toggle_plugin
M.update_config = M.update_config

return M

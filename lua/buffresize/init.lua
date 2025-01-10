-- Module for dynamic window resizing in Neovim

local M = {}

-- Default settings
M.config = {
	min_width = 0.25, -- Minimum window width (as a percentage of total width)
	max_width = 0.7, -- Maximum window width (as a percentage of total width)
	key_toggle = "<leader>rw", -- Key binding to toggle window size
	key_enable = "<leader>re", -- Key binding to enable/disable the plugin
	ignore_filetypes = { "NvimTree", "neo-tree", "dap-repl", "telescope", "toggleterm", "yazi" }, -- Filetypes to ignore
	enabled = true, -- Whether the plugin is enabled by default
	notify = false, -- Whether to show notifications
}

-- Table to store window states
local window_states = {}
local last_window = nil -- Track the last active window

-- Function to get the window width
local function get_window_width(win_id)
	return vim.api.nvim_win_get_width(win_id)
end

-- Function to set the window width
local function set_window_width(win_id, width)
	vim.api.nvim_win_set_width(win_id, math.max(1, math.min(vim.o.columns, width)))
end

-- Check if the window should be ignored
local function should_ignore_window(win_id)
	if not vim.api.nvim_win_is_valid(win_id) then
		return true
	end

	local buf_id = vim.api.nvim_win_get_buf(win_id)
	if not vim.api.nvim_buf_is_valid(buf_id) then
		return true
	end

	local filetype = vim.api.nvim_buf_get_option(buf_id, "filetype")
	for _, ft in ipairs(M.config.ignore_filetypes) do
		if filetype == ft then
			return true
		end
	end
	return false
end

-- Notify function based on configuration
local function notify(msg, level)
	if M.config.notify then
		vim.notify(msg, level or vim.log.levels.WARN)
	end
end

-- Resize a window to a target width
local function resize_window(win_id, target_width)
	if vim.api.nvim_win_is_valid(win_id) and not should_ignore_window(win_id) then
		set_window_width(win_id, target_width)
	end
end

-- Auto-resize windows on focus change
local function resize_on_focus()
	if not M.config.enabled then
		return
	end

	local current_window = vim.api.nvim_get_current_win()

	-- Ignore the current window if it should be ignored
	if should_ignore_window(current_window) then
		return
	end

	local total_width = vim.o.columns
	local max_width = math.floor(total_width * M.config.max_width)
	local min_width = math.floor(total_width * M.config.min_width)

	-- Resize the last window to minimum width
	if last_window and last_window ~= current_window then
		resize_window(last_window, min_width)
	end

	-- Resize the current window to maximum width
	resize_window(current_window, max_width)

	-- Update the last active window
	last_window = current_window

	notify("Window resized on focus", vim.log.levels.INFO)
end

-- Function to dynamically update settings
function M.update_config(new_config)
	M.config = vim.tbl_extend("force", M.config, new_config or {})
	notify("Plugin configuration updated dynamically", vim.log.levels.INFO)
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

	-- Auto-resize on focus
	vim.api.nvim_create_autocmd("WinEnter", {
		callback = resize_on_focus,
	})
end

-- Export functions
M.toggle_window_size = function()
	notify("Toggle window size not implemented for focus-aware resizing", vim.log.levels.WARN)
end
M.toggle_plugin = function()
	M.config.enabled = not M.config.enabled
	if M.config.enabled then
		notify("Resize plugin enabled", vim.log.levels.INFO)
	else
		notify("Resize plugin disabled", vim.log.levels.WARN)
	end
end
M.update_config = M.update_config

return M

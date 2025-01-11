-- Module for dynamic window resizing in Neovim

local M = {}

-- Default settings
M.config = {
	min_width = 0.25, -- Minimum window width (as a percentage of total width)
	max_width = 0.7, -- Maximum window width (as a percentage of total width)
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

-- Function for smooth window resizing
local function smooth_resize(win_id, target_width)
	set_window_width(win_id, target_width)
end

-- Check if the window should be ignored globally
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

-- Resize the ignored window (e.g., neo-tree) only if it's alone with the buffer
local function resize_ignored_window()
	local total_windows = #vim.api.nvim_list_wins()

	-- Ensure there's only one buffer and one ignored window
	if total_windows > 2 then
		return
	end

	for _, win_id in ipairs(vim.api.nvim_list_wins()) do
		if should_ignore_window(win_id) then
			return -- Do nothing if the ignored window is present and focused
		end
	end
end

-- Main logic for toggling window size
local function toggle_window_size()
	if not M.config.enabled then
		return
	end

	local win_id = vim.api.nvim_get_current_win()

	-- Ignore resizing logic if the focused window is in ignore_filetypes
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
	smooth_resize(win_id, target_width)

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

return M

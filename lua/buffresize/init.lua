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
	notify = false, -- Whether to show notifications
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

-- Check if any ignored filetype window is adjacent
local function is_ignored_adjacent(win_id)
	local wins = vim.api.nvim_tabpage_list_wins(0)

	for _, id in ipairs(wins) do
		if id ~= win_id then
			local buf_id = vim.api.nvim_win_get_buf(id)
			local filetype = vim.api.nvim_buf_get_option(buf_id, "filetype")

			if vim.tbl_contains(M.config.ignore_filetypes, filetype) then
				local pos = vim.fn.win_screenpos(id)
				local cur_pos = vim.fn.win_screenpos(win_id)

				-- Check if the ignored window is adjacent (left or right)
				if pos[2] < cur_pos[2] or pos[2] > cur_pos[2] + get_window_width(win_id) then
					return true
				end
			end
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

-- Main logic for toggling window size
local function toggle_window_size(win_id)
	if not M.config.enabled then
		notify("Resize plugin is disabled", vim.log.levels.WARN)
		return
	end

	-- Use the current window if no specific ID is passed
	win_id = win_id or vim.api.nvim_get_current_win()

	-- Ignore the window if its filetype is in the ignore list or any ignored window is adjacent
	if should_ignore_window(win_id) or is_ignored_adjacent(win_id) then
		notify("Window ignored due to its filetype or adjacency to ignored filetypes", vim.log.levels.INFO)
		return
	end

	local total_width = vim.o.columns
	local win_width = get_window_width(win_id)

	-- Initialize window state
	if not window_states[win_id] then
		window_states[win_id] = { expanded = false }
	end

	-- Determine target size
	local target_width = window_states[win_id].expanded and math.floor(total_width * M.config.min_width)
		or math.floor(total_width * M.config.max_width)

	-- Set the window width directly
	set_window_width(win_id, target_width)

	-- Update window state
	window_states[win_id].expanded = not window_states[win_id].expanded
	notify("Window size toggled", vim.log.levels.INFO)
end

-- Function to enable/disable the plugin
local function toggle_plugin()
	M.config.enabled = not M.config.enabled
	if M.config.enabled then
		notify("Resize plugin enabled", vim.log.levels.INFO)
	else
		notify("Resize plugin disabled", vim.log.levels.WARN)
	end
end

-- Auto-resize windows on focus
local function resize_on_focus()
	if not M.config.enabled then
		return
	end

	local win_id = vim.api.nvim_get_current_win()

	if should_ignore_window(win_id) or is_ignored_adjacent(win_id) then
		return
	end

	local total_width = vim.o.columns
	local target_width = math.floor(total_width * M.config.max_width)

	set_window_width(win_id, target_width)
	notify("Window resized on focus", vim.log.levels.INFO)
end

-- Prevent interaction with ignored filetypes
local function prevent_ignored_interaction()
	local win_id = vim.api.nvim_get_current_win()

	if should_ignore_window(win_id) or is_ignored_adjacent(win_id) then
		notify("Interaction disabled for ignored filetype or adjacency", vim.log.levels.INFO)
		return true
	end
	return false
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
		{ noremap = true, silent = true, desc = "Toggle window size" }
	)

	-- Set key binding for enabling/disabling the plugin
	vim.api.nvim_set_keymap(
		"n",
		M.config.key_enable,
		"<cmd>lua require'buffresize'.toggle_plugin()<CR>",
		{ noremap = true, silent = true, desc = "Enable/disable resize plugin" }
	)

	-- Auto-resize on focus
	vim.api.nvim_create_autocmd("WinEnter", {
		callback = resize_on_focus,
	})

	-- Prevent interaction with ignored filetypes
	vim.api.nvim_create_autocmd("BufEnter", {
		callback = function()
			if prevent_ignored_interaction() then
				vim.cmd("stopinsert")
			end
		end,
	})
end

-- Export functions
M.toggle_window_size = toggle_window_size
M.toggle_plugin = toggle_plugin
M.update_config = M.update_config

return M

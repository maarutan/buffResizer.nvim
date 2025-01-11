local M = {}

-- Plugin configuration
M.config = {
	enabled = true, -- If false, the plugin is disabled
	notify = true, -- If false, notifications are disabled
	keymaps = {
		toggle_resize = "<leader>rw",
		toggle_plugin = "<leader>re",
		vertical_split = "<leader>wv",
	},
	notification_icon = "🪓", -- Icon for notifications
	min_width = 25, -- Minimum width for collapsing (% of screen width)
	max_width = 70, -- Maximum width for expanding (% of screen width)
	start_width = 50, -- Initial width when creating a split (% of screen width)
}

local tracked_windows = {}
local manual_resized = {}

local function notify(description, level)
	if M.config.notify then
		vim.notify(
			string.format("%s Buffresize %s", M.config.notification_icon, description),
			level or vim.log.levels.INFO
		)
	end
end

local function is_tracked(win)
	return tracked_windows[win] ~= nil
end

local function resize_tracked_window(win, focus)
	if not is_tracked(win) then
		return
	end

	local win_width = vim.api.nvim_win_get_width(win)
	local total_columns = vim.o.columns
	local min_width = math.floor(total_columns * (M.config.min_width / 100))
	local max_width = math.floor(total_columns * (M.config.max_width / 100))

	if manual_resized[win] then
		return
	end -- Skip if manually resized

	if focus then
		if win_width <= min_width then
			vim.api.nvim_win_set_width(win, max_width)
		end
	else
		if win_width >= max_width then
			vim.api.nvim_win_set_width(win, min_width)
		end
	end
end

local function handle_manual_resize(win)
	local win_width = vim.api.nvim_win_get_width(win)
	local total_columns = vim.o.columns
	local min_width = math.floor(total_columns * (M.config.min_width / 100))
	local max_width = math.floor(total_columns * (M.config.max_width / 100))

	if win_width > min_width and win_width < max_width then
		manual_resized[win] = true
	else
		manual_resized[win] = nil
	end
end

function M.create_split()
	if not M.config.enabled then
		notify("disable", vim.log.levels.WARN)
		return
	end

	local split_cmd = "vsplit"
	vim.cmd(split_cmd)

	local win = vim.api.nvim_get_current_win()
	tracked_windows[win] = true
	manual_resized[win] = nil

	local total_columns = vim.o.columns
	local start_width = math.floor(total_columns * (M.config.start_width / 100))

	vim.api.nvim_win_set_width(win, start_width)

	notify("split created", vim.log.levels.INFO)
end

function M.toggle_resize()
	local win = vim.api.nvim_get_current_win()
	resize_tracked_window(win, true)
end

function M.toggle_plugin()
	M.config.enabled = not M.config.enabled
	local status = M.config.enabled and "enable" or "disable"
	notify(status)
end

function M.setup(user_config)
	M.config = vim.tbl_deep_extend("force", M.config, user_config or {})

	-- Keybindings
	vim.api.nvim_set_keymap(
		"n",
		M.config.keymaps.toggle_resize,
		"<cmd>lua require('buffresize').toggle_resize()<CR>",
		{ noremap = true, silent = true, desc = "Toggle resize functionality" }
	)
	vim.api.nvim_set_keymap(
		"n",
		M.config.keymaps.toggle_plugin,
		"<cmd>lua require('buffresize').toggle_plugin()<CR>",
		{ noremap = true, silent = true, desc = "Toggle the buffresize plugin" }
	)
	vim.api.nvim_set_keymap(
		"n",
		M.config.keymaps.vertical_split,
		"<cmd>lua require('buffresize').create_split()<CR>",
		{ noremap = true, silent = true, desc = " Vertical Split" }
	)

	-- Autocommand for resizing on focus
	vim.api.nvim_create_autocmd("WinEnter", {
		callback = function()
			if M.config.enabled then
				local win = vim.api.nvim_get_current_win()
				resize_tracked_window(win, true)
			end
		end,
	})

	-- Autocommand for collapsing on losing focus
	vim.api.nvim_create_autocmd("WinLeave", {
		callback = function()
			if M.config.enabled then
				local win = vim.api.nvim_get_current_win()
				resize_tracked_window(win, false)
			end
		end,
	})

	-- Autocommand for manual resize handling
	vim.api.nvim_create_autocmd("WinResized", {
		callback = function()
			if M.config.enabled then
				local win = vim.api.nvim_get_current_win()
				handle_manual_resize(win)
			end
		end,
	})

	-- Remove windows from tracking on close
	vim.api.nvim_create_autocmd("WinClosed", {
		callback = function(event)
			local win = tonumber(event.match)
			tracked_windows[win] = nil
			manual_resized[win] = nil
		end,
	})
end

return M

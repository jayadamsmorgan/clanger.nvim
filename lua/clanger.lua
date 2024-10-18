local M = {}

local config_file = vim.fn.stdpath("data") .. "/clanger/configurations.json"

-- Utility function to load configurations
local function load_configurations()
	local configurations = {}
	if vim.fn.filereadable(config_file) == 1 then
		local json = vim.fn.readfile(config_file)
		local json_str = table.concat(json, "\n")
		configurations = vim.fn.json_decode(json_str)
	end
	return configurations
end

-- Utility function to save configurations
local function save_configurations(configurations)
	local json_str = vim.fn.json_encode(configurations)
	vim.fn.mkdir(vim.fn.fnamemodify(config_file, ":h"), "p")
	vim.fn.writefile({ json_str }, config_file)
end

-- Function to add or edit configuration for a project
local function AddEditConfiguration()
	local project_dir = vim.fn.getcwd()
	local configurations = load_configurations()

	-- Ensure there is an entry for the project
	configurations[project_dir] = configurations[project_dir] or { configs = {}, active = nil }
	local project_configs = configurations[project_dir].configs

	-- Prompt for configuration name
	local config_name = vim.fn.input("Configuration Name: ")
	if config_name == "" then
		print("Configuration name cannot be empty.")
		return
	end

	-- Check if configuration exists
	local config = project_configs[config_name] or {}

	-- Prompt for named fields
	local fields = { "Field1", "Field2", "Field3" } -- Replace with your actual field names
	for _, field in ipairs(fields) do
		local default = config[field] or ""
		local value = vim.fn.input(field .. " [" .. default .. "]: ")
		if value == "" then
			value = default
		end
		config[field] = value
	end

	-- Save the configuration
	project_configs[config_name] = config

	-- Save all configurations
	save_configurations(configurations)

	print('Configuration "' .. config_name .. '" saved for project "' .. project_dir .. '".')
end

-- Function to select the active configuration for the current project
local function SelectActiveConfiguration()
	local project_dir = vim.fn.getcwd()
	local configurations = load_configurations()

	if not configurations[project_dir] or not next(configurations[project_dir].configs) then
		print("No configurations found for this project.")
		return
	end

	local project_configs = configurations[project_dir].configs

	-- List configuration names
	local config_names = {}
	for name, _ in pairs(project_configs) do
		table.insert(config_names, name)
	end

	-- Show a selection prompt
	local choice = vim.fn.inputlist(vim.tbl_extend("force", { "Select Configuration:" }, config_names))

	if choice < 1 or choice > #config_names then
		print("Invalid selection.")
		return
	end

	local selected_config = config_names[choice]

	-- Set the active configuration
	configurations[project_dir].active = selected_config

	-- Save all configurations
	save_configurations(configurations)

	print('Active configuration for project "' .. project_dir .. '" set to "' .. selected_config .. '".')
end

-- Function to get the active configuration for the current project
local function GetActiveConfiguration()
	local project_dir = vim.fn.getcwd()
	local configurations = load_configurations()

	if configurations[project_dir] and configurations[project_dir].active then
		local active_config_name = configurations[project_dir].active
		local config = configurations[project_dir].configs[active_config_name]
		return config
	else
		return nil
	end
end

local function LoadActiveConfiguration()
	local config = GetActiveConfiguration()
	if config then
		-- Use the configuration as needed
		print("Loaded active configuration")
	else
		print("No active configuration found for this project.")
	end
end

-- Function to display the menu
local function ShowMenu()
	-- Create a new buffer
	local buf = vim.api.nvim_create_buf(false, true)

	-- Write the menu options to the buffer
	local lines = {
		"Clanger Menu",
		"",
		"1. Add/Edit Configuration",
		"2. Select Active Configuration",
	}
	vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)

	-- Get the current editor size
	local width = vim.o.columns
	local height = vim.o.lines

	-- Calculate the position for the popup (centered)
	local win_width = 50
	local win_height = 10
	local row = math.floor((height - win_height) / 2)
	local col = math.floor((width - win_width) / 2)

	-- Create the popup window with the specified size
	local opts = {
		title = "Clanger",
		title_pos = "center",
		style = "minimal",
		relative = "editor",
		width = win_width,
		height = win_height,
		row = row,
		col = col,
		border = "rounded",
	}

	local win = vim.api.nvim_open_win(buf, true, opts)

	-- Make the buffer non-modifiable (read-only)
	vim.api.nvim_buf_set_option(buf, "modifiable", false)
	vim.api.nvim_buf_set_option(buf, "bufhidden", "wipe")

	-- Functions to handle menu options
	local function close_menu()
		vim.api.nvim_win_close(win, true)
	end

	local function option_one()
		close_menu()
		AddEditConfiguration()
	end

	local function option_two()
		close_menu()
		SelectActiveConfiguration()
	end

	-- Set key mappings for '1' and '2' in the buffer
	vim.api.nvim_buf_set_keymap(buf, "n", "q", "", {
		nowait = true,
		noremap = true,
		silent = true,
		callback = close_menu,
	})
	vim.api.nvim_buf_set_keymap(buf, "n", "1", "", {
		nowait = true,
		noremap = true,
		silent = true,
		callback = option_one,
	})
	vim.api.nvim_buf_set_keymap(buf, "n", "2", "", {
		nowait = true,
		noremap = true,
		silent = true,
		callback = option_two,
	})

	-- Disable other interactions in the window
	vim.api.nvim_buf_set_option(buf, "buftype", "nofile")
	vim.api.nvim_buf_set_option(buf, "swapfile", false)
	vim.api.nvim_win_set_option(win, "cursorline", true)
end

-- Public function to setup the plugin
function M.setup(opts)
	-- Optional setup code
end

M.ShowMenu = ShowMenu
M.GetActiveConfiguration = GetActiveConfiguration
M.LoadActiveConfiguration = LoadActiveConfiguration

return M

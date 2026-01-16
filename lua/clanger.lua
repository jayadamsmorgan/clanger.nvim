local M = {}

local config_list_file = vim.fn.stdpath("data") .. "/clanger/configurations.json"
local config_actives_file = vim.fn.stdpath("data") .. "/clanger/active_configs.json"

local menu_buf

local configs_list = {}
local active_list = {}

local function write_configurations()
	local file = io.open(config_list_file, "w")
	if not file then
		return false
	end
	local encoded = vim.fn.json_encode(configs_list)
	file:write(encoded)
	file:close()
	file = io.open(config_actives_file, "w")
	if not file then
		return false
	end
	encoded = vim.fn.json_encode(active_list)
	file:write(encoded)
	file:close()
	return true
end

local function read_configurations()
	vim.fn.mkdir(vim.fn.stdpath("data") .. "/clanger", "p")
	local file = io.open(config_list_file, "r")
	if not file then
		return false
	end

	local content = file:read("*a")
	file:close()

	local config_list_decoded = vim.fn.json_decode(content)
	if not config_list_decoded then
		print("Unable to parse config_list_file.")
		return false
	end

	file = io.open(config_actives_file, "r")
	if file then
		content = file:read("*a")
		file:close()

		local config_actives_decoded = vim.fn.json_decode(content)
		if not config_actives_decoded then
			print("Unable to parse config_actives_file.")
			return false
		end
		active_list = config_actives_decoded
	end

	configs_list = config_list_decoded
	return true
end

local function get_active_config_current_project()
	for i, value in ipairs(active_list) do
		if value.cwd == vim.fn.getcwd() then
			return i, value.config_name
		end
	end
	return 0, nil
end

local function update_configs()
	write_configurations()
	read_configurations()
	local lines = {}

	local _, active_config_name = get_active_config_current_project()
	if active_config_name then
		table.insert(lines, "Current active config: " .. active_config_name)
	else
		table.insert(lines, "No active config for opened project.")
	end

	table.insert(lines, "")
	for i, config in ipairs(configs_list) do
		table.insert(lines, i .. ". " .. config.name)
	end
	vim.api.nvim_set_option_value("modifiable", true, { buf = menu_buf })
	vim.api.nvim_buf_set_lines(menu_buf, 0, -1, false, lines)
	vim.api.nvim_set_option_value("modifiable", false, { buf = menu_buf })
end

local function get_config_under_cursor()
	local cursor_pos = vim.api.nvim_win_get_cursor(0)
	local cursor_row = cursor_pos[1]
	if cursor_row < 3 then
		return cursor_row, nil
	end
	cursor_row = cursor_row - 2
	return cursor_row, configs_list[cursor_row]
end

local function rename_config()
	local cursor_pos, config = get_config_under_cursor()
	if not config then
		return false
	end

	vim.ui.input({ prompt = "Rename to: ", default = config.name }, function(input)
		if input then
			config.name = input
			configs_list[cursor_pos] = config
			update_configs()
		end
	end)
end

local function ShowEditCommand()
	local cursor_row, config = get_config_under_cursor()
	if not config then
		return false
	end

	local buf_name = "ClangdConfig" .. config.name .. "Edit"
	local existing_bufnr = vim.fn.bufnr(buf_name)

	if existing_bufnr ~= -1 then
		vim.api.nvim_buf_delete(existing_bufnr, { force = true })
	end

	local buf = vim.api.nvim_create_buf(false, false)

	vim.api.nvim_buf_set_lines(buf, 0, -1, false, config.clangd_cmd)

	local width = vim.o.columns
	local height = vim.o.lines
	local win_width = math.floor(width / 2)
	local win_height = math.floor(height / 2)
	local row = math.floor((height - win_height) / 2)
	local col = math.floor((width - win_width) / 2)
	local opts = {
		title = config.name .. " clangd command",
		title_pos = "center",
		style = "minimal",
		relative = "editor",
		width = win_width,
		height = win_height,
		row = row,
		col = col,
		border = "rounded",
	}
	vim.api.nvim_set_option_value("buftype", "acwrite", { buf = buf })
	vim.api.nvim_set_option_value("modified", false, { buf = buf })
	vim.api.nvim_buf_set_name(buf, buf_name)

	vim.api.nvim_open_win(buf, true, opts)

	vim.api.nvim_create_autocmd("BufWriteCmd", {
		buffer = buf,
		callback = function()
			local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
			config.clangd_cmd = lines
			configs_list[cursor_row] = config
			update_configs()
			vim.api.nvim_set_option_value("modified", false, { buf = buf })
		end,
	})
end

local function ShowEditConfig()
	local cursor_row, config = get_config_under_cursor()
	if not config then
		return false
	end

	local buf_name = "ClangdCommand" .. config.name .. "Edit"
	local existing_bufnr = vim.fn.bufnr(buf_name)

	if existing_bufnr ~= -1 then
		vim.api.nvim_buf_delete(existing_bufnr, { force = true })
	end

	local buf = vim.api.nvim_create_buf(false, false)

	vim.api.nvim_buf_set_lines(buf, 0, -1, false, config.clangd_config)

	local width = vim.o.columns
	local height = vim.o.lines
	local win_width = math.floor(width / 1.5)
	local win_height = math.floor(height / 1.5)
	local row = math.floor((height - win_height) / 2)
	local col = math.floor((width - win_width) / 2)
	local opts = {
		title = config.name .. " clangd config",
		title_pos = "center",
		style = "minimal",
		relative = "editor",
		width = win_width,
		height = win_height,
		row = row,
		col = col,
		border = "rounded",
	}
	vim.api.nvim_set_option_value("filetype", "yaml", { buf = buf })
	vim.api.nvim_set_option_value("buftype", "acwrite", { buf = buf })
	vim.api.nvim_set_option_value("modified", false, { buf = buf })
	vim.api.nvim_buf_set_name(buf, buf_name)

	vim.api.nvim_open_win(buf, true, opts)

	vim.api.nvim_create_autocmd("BufWriteCmd", {
		buffer = buf,
		callback = function()
			local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
			config.clangd_config = lines
			configs_list[cursor_row] = config
			update_configs()
			vim.api.nvim_set_option_value("modified", false, { buf = buf })
		end,
	})
end

local function add_new_config()
	local clangd_example_config = {
		name = "newConfig",
		clangd_cmd = {
			"clangd",
			"--header-insertion=never",
			"--background-index",
			"--clang-tidy",
			"--limit-references=0",
			"--limit-results=0",
			"--log=error",
			"--offset-encoding=utf-16",
			"--function-arg-placeholders=false",
			"--query-driver=/opt/homebrew/bin/arm-none-eabi-gcc",
		},
		clangd_config = {
			"CompileFlags:",
			"  Add:",
			"    [",
			"      # -std=gnu++11,",
			"      -mlong-calls,",
			"      # -isysroot=somepackages/toolchain-xtensa-esp32s3/xtensa-esp32s3-elf/,",
			"      # -D__XTENSA__,",
			"      # -D_LDBL_EQ_DBL,",
			"      # -DSSIZE_MAX,",
			"      # -pedantic,",
			"      -ferror-limit=0,",
			"    ]",
			"  Remove:",
			"    [",
			"      -fno-tree-switch-conversion,",
			"      -mtext-section-literals,",
			"      -mlongcalls,",
			"      -fstrict-volatile-bitfields,",
			"    ]",
			"Diagnostics:",
			"  Suppress:",
			"    [",
			"      'non_asm_stmt_in_naked_function',",
			"      'pp_including_mainfile_in_preamble',",
			"      'attribute_section_invalid_for_target',",
			"      'block_on_nonlocal',",
			"      # 'ovl_no_viable_member_function_in_call',",
			"      # 'typecheck_nonviable_condition'",
			"    ]",
		},
	}
	table.insert(configs_list, clangd_example_config)
	update_configs()
end

local function delete_config()
	local cursor_row, config = get_config_under_cursor()
	if not config then
		return false
	end
	table.remove(configs_list, cursor_row)
	update_configs()
	-- TODO: remove from active configs
end

local function use_config()
	local _, config = get_config_under_cursor()
	if not config then
		return false
	end

	local i, config_name = get_active_config_current_project()
	if config_name then
		-- remove existing active
		table.remove(active_list, i)
	end

	table.insert(active_list, {
		cwd = vim.fn.getcwd(),
		config_name = config.name,
	})

	update_configs()

	require("clanger").LoadActiveConfiguration()

	return true
end

local function ShowMenu()
	menu_buf = vim.api.nvim_create_buf(false, true)

	read_configurations()

	update_configs()

	-- Get the current editor size
	local width = vim.o.columns
	local height = vim.o.lines

	-- Calculate the position for the popup (centered)
	local win_width = math.floor(width / 2)
	local win_height = math.floor(height / 2)
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

	local win = vim.api.nvim_open_win(menu_buf, true, opts)

	-- Functions to handle menu options
	local function close_menu()
		vim.api.nvim_win_close(win, true)
	end

	vim.api.nvim_buf_set_keymap(menu_buf, "n", "<ESC>", "", {
		nowait = true,
		noremap = true,
		silent = true,
		callback = close_menu,
	})
	vim.api.nvim_buf_set_keymap(menu_buf, "n", "q", "", {
		nowait = true,
		noremap = true,
		silent = true,
		callback = close_menu,
	})
	vim.api.nvim_buf_set_keymap(menu_buf, "n", "a", "", {
		nowait = true,
		noremap = true,
		silent = true,
		callback = add_new_config,
	})
	vim.api.nvim_buf_set_keymap(menu_buf, "n", "e", "", {
		nowait = true,
		noremap = true,
		silent = true,
		callback = ShowEditConfig,
	})
	vim.api.nvim_buf_set_keymap(menu_buf, "n", "c", "", {
		nowait = true,
		noremap = true,
		silent = true,
		callback = ShowEditCommand,
	})
	vim.api.nvim_buf_set_keymap(menu_buf, "n", "d", "", {
		nowait = true,
		noremap = true,
		silent = true,
		callback = delete_config,
	})
	vim.api.nvim_buf_set_keymap(menu_buf, "n", "r", "", {
		nowait = true,
		noremap = true,
		silent = true,
		callback = rename_config,
	})
	vim.api.nvim_buf_set_keymap(menu_buf, "n", "<CR>", "", {
		nowait = true,
		noremap = true,
		silent = true,
		callback = use_config,
	})

	-- Disable other interactions in the window
	vim.api.nvim_set_option_value("bufhidden", "wipe", { buf = menu_buf })
	vim.api.nvim_set_option_value("buftype", "nofile", { buf = menu_buf })
	vim.api.nvim_set_option_value("swapfile", false, { buf = menu_buf })
	vim.api.nvim_set_option_value("cursorline", true, { win = win })
end

-- Public function to setup the plugin
function M.setup(opts)
	if opts then
		if opts.config_list_file then
			config_list_file = opts.config_list_file
		end
	end
end

local function get_clangd_config_path()
	local sysname = vim.loop.os_uname().sysname
	local home = vim.loop.os_homedir()

	if sysname == "windows_nt" then
		local local_app_data = os.getenv("localappdata")
		if local_app_data then
			return local_app_data .. "\\clangd\\"
		else
			return nil
		end
	elseif sysname == "Darwin" then
		if home then
			return home .. "/Library/Preferences/clangd/"
		else
			return nil
		end
	else
		if home then
			return home .. "/.config/clangd/"
		else
			return nil
		end
	end
end

local function LoadActiveConfiguration()
	read_configurations()

	local _, active = get_active_config_current_project()
	if not active then
		return
	end

	local config_found
	for _, config in ipairs(configs_list) do
		if config.name == active then
			config_found = config
			break
		end
	end

	if not config_found then
		print("Cannot find config '" .. active .. "' in config lists...")
		return
	end

	local clangd_config_path = get_clangd_config_path()
	if not clangd_config_path then
		print("Cannot find Clangd config path, unable to set active config...")
		return
	end

	vim.fn.mkdir(clangd_config_path, "p")

	local file = io.open(clangd_config_path .. "config.yaml", "w")
	if not file then
		print("Cannot open clangd config file, unable to set active config...")
		return
	end

	for _, line in ipairs(config_found.clangd_config) do
		file:write(line .. "\n")
	end
	file:close()

	vim.cmd("LspRestart")
end

M.ShowMenu = ShowMenu
M.LoadActiveConfiguration = LoadActiveConfiguration

return M

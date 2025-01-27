-- Functionality for reading and writing persistent plugin history

local log = require("flip.log")
local config = require("flip.config")
local util = require("flip.util")

---The stack of recently open files for this session.
---@type string[]
local open_stack = {}

---@class FlipHistory
local HISTORY = nil

--- Get the path on disk to the expected history file location.
---@return string config_path
local function get_history_path()
    local data_dir = vim.fn.stdpath("data") .. "/flip"

    local ok = vim.fn.mkdir(data_dir, "p")

    if not ok then
        log.error("Unable to create data dir %s", data_dir)
    end

    return vim.fs.joinpath(data_dir, "/history.json")
end

--- Write the given history table as json to the given filepath.
--- @param history_path string Path to the target history json file.
--- @param history FlipHistory State to write.
local function write_history_file(history_path, history)
    local ok, json = pcall(vim.json.encode, history)

    if not ok then
        log.error("Failed to encode table to JSON: " .. vim.inspect(history))
    end

    -- Write the JSON string to a file
    local file = io.open(history_path, "w") -- Open the file in write mode

    if file == nil then
        log.error("Could not open file for writing: %s", history_path)
    end

    file:write(json) -- Write JSON data
    file:close()     -- Close the file
end

--- Load flippy history from the expected history file location.
--- This file location is either:
--- - Inside vim's data path
--- - Manually specified in plugin config.
---
--- If a history file doesn't exists already, one is created.
---
--- Errors are thrown if the expected config file doesn't exist, or if the decoding process fails.
---@return FlipHistory history
local function load_history()
    local history_path = config.opts.history_file or get_history_path()

    -- Create history file if it doesnt exist
    local _, _, err = vim.uv.fs_stat(history_path)

    if err == "ENOENT" then
        write_history_file(history_path, {})
    end

    -- Read config file
    local file = io.open(history_path, "r")

    if file == nil then
        log.error("Couldnt open history file: %s", history_path)
    end

    local content = file:read("*a")
    file:close()

    local ok, res = pcall(vim.json.decode, content)

    if not ok then
        log.error("Failed to decode history object from file %s: %s", history_path, res)
    end

    return res
end

--- Add the given file path to history.
--- @param file_path string
local function add_to_history(file_path)
end

--- Add the given file path to the open stack
local function add_to_stack(file_path)
    log.debug("Adding file to stack: %s", file_path)
    table.insert(open_stack, file_path)
    open_stack = util.deduplicate(open_stack)
end

--- Get the last opened file path
--- @return string|nil last_open
local function get_last_open()
    if #open_stack >= 2 then
        return open_stack[#open_stack - 1]
    else
        return nil
    end
end

local function register_callbacks()
    -- Autocommand to record a new buffer visit in the appropriate structs
    vim.api.nvim_create_autocmd("BufWinEnter", {
        callback = function(e)
            local bufnr = vim.api.nvim_get_current_buf()
            local buf_type = require("flip.compat").get_buf_type(bufnr)

            if buf_type == "" and vim.bo.filetype ~= "" then
                add_to_stack(e.file)
            end
        end
    })
end

-- Exports
return {
    load_history = load_history,
    add_to_history = add_to_history,
    add_to_stack = add_to_stack,
    get_last_open = get_last_open,
    register_callbacks = register_callbacks,

    get_stack = function()
        return open_stack
    end
}

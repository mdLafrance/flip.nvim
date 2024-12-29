--- Configuration options for flip.
--- Apply configuration options with the exported `setup` function.
---@class FlipConfig
FLIP_CONFIG = {
    history_file = "",
    history_key_function = nil,
    debug = true,
}

--- Ensure the current nvim environment contains all necessary dependencies for flip.
--- Errors will be thrown if dependencies are missing.
local function ensure_dependencies()
    local ok, err = pcall(require, "nui.menu")

    if not ok then
        error("Flip missing dependency on nui")
    end
end

local M = {}

M.opts  = FLIP_CONFIG

--- Apply the given configuration options
--- @param opts FlipConfig
M.setup = function(opts)
    local log = require("flip.log")

    log.debug("Setting up with opts: " .. vim.inspect(opts))

    if opts == nil then
        return
    end

    for k, v in pairs(opts) do
        if FLIP_CONFIG[k] == nil then
            log.error("Unknown config option: %s", k)
        elseif type(v) ~= type(FLIP_CONFIG[k]) then
            log.error("Invalid config option %s. Must be of type %s", k, type(FLIP_CONFIG[k]))
        else
            FLIP_CONFIG[k] = v
        end
    end

    ensure_dependencies()
    require("flip.commands").register_commands()
    require("flip.history").register_callbacks()
end

return M
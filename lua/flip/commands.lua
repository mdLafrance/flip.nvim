-- Functionality to define and expose user commands

local log = require("flip.log")
local util = require("flip.util")

local M = {}

local commands = {
    help = function()
        vim.cmd("help flip.nvim")
    end,

    open = require("flip.window").open_history_window,

    back = function()
        local prev = require("flip.history").get_last_open()

        if prev then
            vim.cmd.edit(prev)
        else
            log.notify_warning("No previous files open")
        end
    end,

    to_recent = function()
        if #require("flip.history").get_stack() < 2 then
            log.notify_info("No buffers recently opened")
        else
            require("flip.window").open_recent_buffers_window()
        end
    end,
}

--- Register user commands.
--- Call only once in setup.
M.register_commands = function()
    local function wrap_cmd(fn)
        return function(args)
            fn(unpack(args.fargs))
        end
    end

    for name, cmd in pairs(commands) do
        local cmd_name = "Flip" .. string.gsub(util.capitalize(name), "_(%w)", function(letter)
            return string.upper(letter)
        end)

        log.debug("Registering command: %s", name)

        vim.api.nvim_create_user_command(cmd_name, wrap_cmd(cmd), { nargs = "*" })
    end
end

return M

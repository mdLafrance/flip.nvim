--- Functionality for logging

local opts = require("flip.config").opts

local M = {}

M.debug = function(fmt, ...)
    if opts.debug then
        print(string.format("FLIP DEBUG: %s", string.format(fmt, ...)))
    end
end

M.error = function(fmt, ...)
    error("FLIP: " .. string.format(fmt, ...))
end

M.notify_info = function(fmt, ...)
    if not opts.suppress_notifications then
        vim.notify(string.format(fmt, ...), vim.log.levels.INFO)
    end
end

M.notify_warning = function(fmt, ...)
    if not opts.suppress_notifications then
        vim.notify(string.format(fmt, ...), vim.log.levels.WARN)
    end
end

return M

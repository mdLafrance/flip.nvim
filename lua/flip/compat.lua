-- Compatability utils for common use between versions of neovim or lua

local version = vim.version()

local M = {}

--- Get the buftype of the given buffer.
--- @param bufnr number Buffer id
--- @return string|nil buftype
M.get_buf_type = function(bufnr)
    if version.major == 0 and version.minor >= 10 then
        return vim.api.nvim_get_option_value("buftype", { buf = bufnr }) or ""
    else
        return vim.api.nvim_buf_get_option(bufnr, "buftype") or "" ---@diagnostic disable-line: deprecated
    end
end

--- Set an option on the given buffer
--- @param bufnr number Buffer id
--- @param option string Option to set
--- @param value any
--- @return string|nil buftype
M.set_buf_option = function(bufnr, option, value)
    if version.major == 0 and version.minor >= 10 then
        vim.api.nvim_set_option_value(option, value, { buf = bufnr })
    else
        vim.api.nvim_buf_set_option(bufnr, option, value) ---@diagnostic disable-line: deprecated
    end
end

return M

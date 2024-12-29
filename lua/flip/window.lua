-- Funcionality for opening and managing the flippy history window

local log = require("flip.log")
local history = require("flip.history")

FLIP_WINDOW = nil

STACK_WINDOW_ID = nil
STACK_WINDOW_SHOW_FULL_PATH = false

local function close_stack_window()
    if not STACK_WINDOW_ID then
        return
    end

    local bufnr = vim.api.nvim_win_get_buf(STACK_WINDOW_ID)
    vim.api.nvim_buf_delete(bufnr, { force = true })

    STACK_WINDOW_ID = nil
end

local function get_relative_path(path)
    local cwd = vim.fn.getcwd()
    local relative = vim.fn.fnamemodify(path, ":." .. cwd)

    return relative
end

local function add_line_to_stack_buffer(item, opts)
    -- Index number
    local number_text = " [" .. opts.idx .. "] "

    -- Item name
    local item_text = ""
    if STACK_WINDOW_SHOW_FULL_PATH then
        item_text = get_relative_path(item)
    else
        item_text = vim.fs.basename(item)
    end

    -- Icon
    local item_ext = vim.fn.fnamemodify(item, ":e")
    local icon_text, hlg = require("nvim-web-devicons").get_icon(item, item_ext)
    if not icon_text then
        icon_text = ""
    end

    icon_text = " " .. icon_text .. " "

    -- Fill value
    local fill_len = opts.width - #number_text - #item_text - 3 -- len of icon
    local fill_text = ("."):rep(fill_len, "")

    -- Concat
    local text = number_text .. item_text .. fill_text .. icon_text

    vim.api.nvim_buf_set_lines(opts.bufnr, opts.lineno, opts.lineno, false, { text })

    -- Apply hl groups
    vim.api.nvim_buf_add_highlight(opts.bufnr, -1, "Comment", opts.lineno, 0, #number_text)
    vim.api.nvim_buf_add_highlight(opts.bufnr, -1, "Comment", opts.lineno, #number_text + #item_text, -1)

    if hlg then
        vim.api.nvim_buf_add_highlight(opts.bufnr, -1, hlg, opts.lineno, #number_text + #item_text + #fill_text, -1)
    end

    vim.api.nvim_buf_add_highlight(opts.bufnr, -1, "Bold", opts.lineno, #number_text, #number_text + #item_text)
end

local function open_stack_window()
    if STACK_WINDOW_ID then
        close_stack_window()
    end

    local parent_window = vim.api.nvim_get_current_win()

    local width = 30
    local win_width = vim.api.nvim_win_get_width(parent_window)
    local win_height = vim.api.nvim_win_get_height(parent_window)

    local bufnr = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_option(bufnr, 'buftype', 'nofile')
    vim.api.nvim_buf_set_option(bufnr, 'swapfile', false)

    local buffer_index_mapping = {}
    local stack = history.get_stack()

    local idx = 1

    for i = #stack - 1, 1, -1 do
        local item = stack[i]

        add_line_to_stack_buffer(item, {
            bufnr = bufnr,
            idx = idx,
            lineno = idx - 1,
            width = width
        })

        buffer_index_mapping[idx] = item
        idx = idx + 1
    end

    STACK_WINDOW_ID = vim.api.nvim_open_win(bufnr, true, {
        relative = 'win',
        width = width,
        height = #stack - 1,
        row = 0,
        col = win_width - 1,
        style = "minimal",
        anchor = "NE",
        border = "rounded",
        title = " Flip to recent "
    })

    -- Set enter keymap
    vim.api.nvim_buf_set_keymap(bufnr, "n", "<CR>", '', {
        noremap = true,
        silent = true,
        callback = function()
            local row = vim.api.nvim_win_get_cursor(0)[1]

            if buffer_index_mapping[row] ~= nil then
                vim.api.nvim_set_current_win(parent_window)
                vim.cmd.edit(buffer_index_mapping[row])
                close_stack_window()
            end
        end
    })

    -- Set esc keymap
    vim.api.nvim_buf_set_keymap(bufnr, "n", "<ESC>", '', {
        noremap = true,
        silent = true,
        callback = function()
            close_stack_window()
        end
    })

    -- Set number select keymaps
    for idx, _ in pairs(buffer_index_mapping) do
        vim.api.nvim_buf_set_keymap(bufnr, "n", '' .. idx, '', {
            noremap = true,
            silent = true,
            callback = function()
                vim.api.nvim_set_current_win(parent_window)
                vim.cmd.edit(buffer_index_mapping[idx])
                close_stack_window()
            end
        })
    end

    -- Set buffer local autocommand to close on lose focus
    vim.api.nvim_create_autocmd("BufLeave", {
        buffer = bufnr,
        callback = function()
            close_stack_window()
        end
    })
end

local function open_history_window()
    local Menu = require("nui.menu")
    local event = require("nui.utils.autocmd").event

    local menu = Menu({
        position = "50%",
        relative = "editor",
        size = {
            width = 35,
            height = 10,
        },
        border = {
            style = "rounded",
            text = {
                top = " Flip to recent ",
                top_align = "center",
            },
        },
        win_options = {
        },
    }, {
        lines = {
            Menu.item("Hydrogen (H)"),
            Menu.item("Carbon (C)"),
            Menu.item("Nitrogen (N)"),
            Menu.separator("Noble-Gases", {
                char = "-",
                text_align = "right",
            }),
            Menu.item("Helium (He)"),
            Menu.item("Neon (Ne)"),
            Menu.item("Argon (Ar)"),
        },
        max_width = 20,
        keymap = {
            focus_next = { "j", "<Down>", "<Tab>" },
            focus_prev = { "k", "<Up>", "<S-Tab>" },
            close = { "<Esc>", "<C-c>" },
            submit = { "<CR>", "<Space>" },
        },
        on_close = function()
            print("Menu Closed!")
        end,
        on_submit = function(item)
            print("Menu Submitted: ", item.text)
        end,
    })

    -- mount the component
    menu:mount()

    -- local win = vim.api.nvim_open_win(0, true, {
    --     relative = "win",
    --     row = 5,
    --     col = 5,
    --     width = 100,
    --     height = 20,
    --     style = "minimal",
    --     border = "rounded",
    --     title = "Flip"
    -- })

    -- if win == 0 then
    --     log.error("Unable to open window")
    -- end
end

-- Exports
return {
    open_stack_window = open_stack_window
}

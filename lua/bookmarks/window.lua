local float = require("bookmarks.float")
local api = vim.api

local M = {}
local config = nil

local focus_manager = (function()
    --- @alias WinType string
    --- @alias WinId integer
    local current_type = nil --- @type WinType | nil
    local win_types = {}     --- @type WinType[]
    local wins = {}          --- @type table<WinType, WinId>

    local function toogle()
        local next_type = nil
        for i, type in ipairs(win_types) do
            if type == current_type then
                local next_i = i + 1
                if next_i > #win_types then next_i = 1 end
                next_type = win_types[next_i]
                break
            end
        end

        if next_type == nil then next_type = win_types[1] end

        local next_win = wins[next_type]
        if next_win == nil then
            local msg = string.format("%s window not found", next_type)
            vim.notify(msg, vim.log.levels.INFO, { title = "bookmarks.nvim" })
            return
        end

        current_type = next_type
        api.nvim_set_current_win(next_win)
    end

    return {
        toogle = toogle,
        update_current = function(type) current_type = type end,
        set = function(type, win) wins[type] = win end,
        register = function(type)
            local exist = vim.tbl_contains(win_types, type)
            if not exist then table.insert(win_types, type) end
        end,
    }
end)()


function M.setup()
    config = require("bookmarks.config").get_data()
    vim.cmd(string.format("highlight hl_bookmarks_csl %s", config.hl.cursorline))
    float.setup()
    focus_manager.register("bookmarks")
end

function M.open_add_win(title)
    local ew = api.nvim_get_option("columns")
    local eh = api.nvim_get_option("lines")
    local width, height = 100, 1
    local options = {
        width = width,
        height = height,
        title = title,
        row = math.floor((eh - height) / 2),
        col = math.floor((ew - width) / 2),
        relative = "editor",
        border_highlight = config.hl.border,
    }

    local pairs = float.create_win(options)
    local border_pairs = float.create_border(options)
    api.nvim_set_current_win(pairs.win)
    api.nvim_win_set_option(pairs.win, 'winhighlight', 'Normal:normal')
    api.nvim_buf_set_option(pairs.buf, 'filetype', 'bookmarks_input')
    vim.cmd("startinsert")

    return {
        pairs = pairs,
        border_pairs = border_pairs
    }
end

function M.close_add_win(buf1, buf2)
    vim.cmd(string.format("bwipeout! %d", buf1))
    vim.cmd(string.format("bwipeout! %d", buf2))
end

return M

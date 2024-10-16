local config = nil
local l = require("bookmarks.list")
local m = require("bookmarks.marks")

local M = {}
local api = vim.api

function M.setup()
    config = require("bookmarks.config").get_data()
    if config == nil then
        return
    end

    M.key_bind()
    M.autocmd()
end

function M.key_bind()
    -- check nil
    if config == nil then
        return
    end

    vim.keymap.set("n", config.keymap.jump, function() require("bookmarks.fzflua").picker_func() end,
        { desc = "bookmarks delete", silent = true })

    -- add local bookmarks
    vim.keymap.set("n", config.keymap.add, function() require("bookmarks.list").add_bookmark() end,
        { desc = "bookmarks add", silent = true })

    -- delete bookmarks
    vim.keymap.set("n", config.keymap.delete, function() require("bookmarks.list").delete() end,
        { desc = "bookmarks delete", silent = true })
end

--
function M.autocmd()
    api.nvim_create_autocmd({ "VimLeave" }, {
        callback = l.persistent
    })

    api.nvim_create_autocmd({ "BufWritePost" }, {
        callback = function()
            require("bookmarks.fix").fix_bookmarks()
            local buf = api.nvim_get_current_buf()
            m.set_marks(buf, l.get_buf_bookmark_lines(buf))
        end
    })

    api.nvim_create_autocmd({ "BufWinEnter" }, {
        pattern = config.virt_pattern,
        callback = function()
            local buf = api.nvim_get_current_buf()
            m.set_marks(buf, l.get_buf_bookmark_lines(buf))
        end
    })
end

return M

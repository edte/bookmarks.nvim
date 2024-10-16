local list = require("list")
local window = require("window")
local mark = require("marks")
local data = require("data")

local M = {}

function M.jump()
    local bookmarks = require("data").bookmarks

    local list = {}
    for _, bookmark in pairs(bookmarks) do
        table.insert(list, bookmark.description)
    end


    local fzf = require("fzf-lua")
    fzf.fzf_exec(list, {
        prompt = "Bookmarks> ",
        previewer = function()
            local previewer = require("fzf-lua.previewer.builtin")
            local path = require("fzf-lua.path")

            -- https://github.com/ibhagwan/fzf-lua/wiki/Advanced#neovim-builtin-preview
            -- Can this be any simpler? Do I need a custom previewer?
            local MyPreviewer = previewer.buffer_or_file:extend()

            function MyPreviewer:new(o, op, fzf_win)
                MyPreviewer.super.new(self, o, op, fzf_win)
                setmetatable(self, MyPreviewer)
                return self
            end

            function MyPreviewer:parse_entry(entry_str)
                if entry_str == "" then
                    return {}
                end
                for _, bookmark in pairs(bookmarks) do
                    if entry_str == bookmark.description then
                        local entry = path.entry_to_file(bookmark.filename .. ":" .. bookmark.line, self.opts)
                        return entry or {}
                    end
                end
            end

            return MyPreviewer
        end,
        actions = {
            ["default"] = function(selected)
                local entry = selected[1]
                if not entry then
                    return
                end

                for _, bookmark in pairs(bookmarks) do
                    if entry == bookmark.description then
                        vim.api.nvim_command("edit " .. bookmark.filename)
                        vim.api.nvim_win_set_cursor(0, { bookmark.line, 0 })
                    end
                end
            end,
        },
    })
end

function M.key_bind()
    vim.keymap.set("n", "mo", function() M.jump() end,
        { desc = "bookmarks jump", silent = true })

    -- add local bookmarks
    vim.keymap.set("n", "mm", function() require("list").add_bookmark() end,
        { desc = "bookmarks add", silent = true })

    -- delete bookmarks
    vim.keymap.set("n", "mD", function() require("list").delete() end,
        { desc = "bookmarks delete", silent = true })
end

--
function M.autocmd()
    api.nvim_create_autocmd({ "VimLeave" }, {
        callback = list.persistent
    })

    api.nvim_create_autocmd({ "BufWritePost" }, {
        callback = function()
            local buf = api.nvim_get_current_buf()
            mark.set_marks(buf, list.get_buf_bookmark_lines(buf))
        end
    })

    api.nvim_create_autocmd({ "BufWinEnter" }, {
        callback = function()
            local buf = api.nvim_get_current_buf()
            mark.set_marks(buf, list.get_buf_bookmark_lines(buf))
        end
    })
end

function M.setup()
    vim.cmd("hi link bookmarks_virt_text_hl Comment")
    vim.fn.sign_define("BookmarkSign", { text = "󰃃" })

    M.key_bind()
    M.autocmd()
    list.setup()
    window.setup()
end

return M

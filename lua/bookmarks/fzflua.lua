local M = {}


function M.picker_func()
    local bookmarks = require("bookmarks.data").bookmarks

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

function M.setup()
    local fzf_cmd = require("fzf-lua.cmd")
    local original_candidates = fzf_cmd._candidates
    fzf_cmd._candidates = function(line)
        local results = original_candidates(line)
        table.insert(results, "bookmark")
        return results
    end


    local original_run_command = fzf_cmd.run_command
    fzf_cmd.run_command = function(...)
        local args = { ... }
        local cmd = args[1]

        if cmd == "bookmark" then
            M.picker_func()
        else
            original_run_command(unpack(args))
        end
    end
end

return M

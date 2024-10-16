local w = require("window")
local data = require("data")
local m = require("marks")
local api = vim.api

local M = {
    storage_dir = "", -- default vim.fn.stdpath("data").."/bookmarks",
}

-- Restore bookmarks from disk file.
function M.setup()
    M.storage_dir = vim.fn.stdpath("data") .. "/bookmarks"

    -- vim.notify("load bookmarks data", "info")
    local currentPath = string.gsub(M.get_base_dir(), "/", "_")
    if data.pwd ~= nil and currentPath ~= data.pwd then -- maybe change session
        M.persistent()
        data.bookmarks = {}
        data.loaded_data = false
    end

    -- print(currentPath)

    if data.loaded_data == true then
        return
    end

    if not vim.loop.fs_stat(M.storage_dir) then
        assert(os.execute("mkdir " .. M.storage_dir))
    end

    -- local bookmarks
    local data_filename = string.format("%s%s%s", M.storage_dir, "/", currentPath):gsub("%c", "")
    -- print(data_filename)
    if vim.loop.fs_stat(data_filename) then
        dofile(data_filename)
    end


    data.pwd = currentPath
    data.loaded_data = true -- mark
    data.data_dir = M.storage_dir
    data.data_filename = data_filename
end

function M.add_bookmark()
    local line = vim.fn.line('.')
    local buf = api.nvim_get_current_buf()
    local rows = vim.fn.line("$")

    --  Open the bookmark description input box.
    local title = "Input description:"
    local bufs_pairs = w.open_add_win(title)

    -- Press the esc key to cancel add bookmark.
    vim.keymap.set("n", "<ESC>",
        function() w.close_add_win(bufs_pairs.pairs.buf, bufs_pairs.border_pairs.buf) end,
        { desc = "bookmarks close add win", silent = true, buffer = bufs_pairs.pairs.buf }
    )

    -- Press the enter key to confirm add bookmark.
    vim.keymap.set("i", "<CR>",
        function() M.handle_add(line, bufs_pairs.pairs.buf, bufs_pairs.border_pairs.buf, buf, rows) end,
        { desc = "bookmarks confirm bookmarks", silent = true, noremap = true, buffer = bufs_pairs.pairs.buf }
    )
end

function M.handle_add(line, buf1, buf2, buf, rows)
    -- Get buf's filename.
    local filename = api.nvim_buf_get_name(buf)
    if filename == nil or filename == "" then
        return
    end

    local input_line = vim.fn.line(".")

    -- Get bookmark's description.
    local description = api.nvim_buf_get_lines(buf1, input_line - 1, input_line, false)[1] or ""
    -- print(description)

    -- Close description input box.
    if description == "" then
        w.close_add_win(buf1, buf2)
        m.set_marks(buf, M.get_buf_bookmark_lines(0))
        vim.cmd("stopinsert")
        return
    end

    -- Save bookmark with description.
    -- Save bookmark as lua code.
    -- rows is the file's number..

    local id = string.format("%s:%s", filename, line)
    local now = os.time()

    if data.bookmarks[id] ~= nil then --update description
        if description ~= nil then
            data.bookmarks[id].description = description
            data.bookmarks[id].updated_at = now
        end
    else -- new
        data.bookmarks[id] = {
            filename = filename,
            line = line,
            rows = rows, -- for fix
            description = description or "",
            updated_at = now,
            is_new = true,
        }

        if data.bookmarks_groupby_filename[filename] == nil then
            data.bookmarks_groupby_filename[filename] = { id }
        else
            data.bookmarks_groupby_filename[filename][#data.bookmarks_groupby_filename[filename] + 1] = id
        end
    end

    -- Close description input box.
    w.close_add_win(buf1, buf2)
    m.set_marks(buf, M.get_buf_bookmark_lines(0))
    vim.cmd("stopinsert")
end

function M.get_buf_bookmark_lines(buf)
    local filename = api.nvim_buf_get_name(buf)
    local lines = {}
    local group = data.bookmarks_groupby_filename[filename]

    if group == nil then
        return lines
    end

    local tmp = {}
    for _, each in pairs(group) do
        if data.bookmarks[each] ~= nil and tmp[data.bookmarks[each].line] == nil then
            lines[#lines + 1] = data.bookmarks[each]
            tmp[data.bookmarks[each].line] = true
        end
    end

    return lines
end

-- Delete bookmark.
function M.delete()
    local line = vim.fn.line(".")
    local file_name = api.nvim_buf_get_name(0)
    local buf = api.nvim_get_current_buf()
    for k, v in pairs(data.bookmarks) do
        if v.line == line and file_name == v.filename then
            data.bookmarks[k] = nil
            m.set_marks(buf, M.get_buf_bookmark_lines(0))
            return
        end
    end
end

-- Write bookmarks into disk file for next load.
function M.persistent()
    local local_str = ""
    for id, bookmark in pairs(data.bookmarks) do
        local sub = M.fill_tpl(bookmark)
        if local_str == "" then
            local_str = string.format("%s%s", local_str, sub)
        else
            local_str = string.format("%s\n%s", local_str, sub)
        end
    end

    if data.data_filename == nil then -- lazy load,
        return
    end

    -- 1.local bookmarks
    local local_fd = assert(io.open(data.data_filename, "w"))
    local_fd:write(local_str)
    local_fd:close()
end

function M.fill_tpl(bookmark)
    local tpl = [[
require("list").load{
	_
}]]
    local sub = ""
    for k, v in pairs(bookmark) do
        if k ~= "is_new" then
            if sub ~= "" then
                sub = string.format("%s\n%s", sub, string.rep(" ", 4))
            end
            if type(v) == "number" or type(v) == "boolean" then
                sub = sub .. string.format("%s = %s,", k, v)
            else
                sub = sub .. string.format("%s = \"%s\",", k, v)
            end
        end
    end

    return string.gsub(tpl, "_", sub)
end

-- 获取书签存储根目录
function M.get_base_dir()
    -- git
    local res
    if vim.fn.system([[git rev-parse --show-toplevel 2> /dev/null]]) ~= "" then
        res = vim.fn.system("git rev-parse --show-toplevel")
    end

    if res ~= "" and res ~= nil then
        -- print(res)
        return res
    end

    -- cwd
    res = vim.uv.cwd()
    -- print(res)
    return res
end

-- 这个不能删，dotfile的时候要用
-- Dofile
function M.load(item, is_persistent)
    local id = string.format("%s:%s", item.filename, item.line)
    data.bookmarks[id] = item
    if is_persistent ~= nil and is_persistent == true then
        return
    end

    if data.bookmarks_groupby_filename[item.filename] == nil then
        data.bookmarks_groupby_filename[item.filename] = {}
    end
    data.bookmarks_groupby_filename[item.filename][#data.bookmarks_groupby_filename[item.filename] + 1] = id
end

return M

local md5 = require("bookmarks.md5")
local w = require("bookmarks.window")
local data = require("bookmarks.data")
local m = require("bookmarks.marks")
local api = vim.api
local config

local M = {}

function M.setup()
    config = require "bookmarks.config".get_data()
    M.load_data()
end

function M.add_bookmark()
    local line = vim.fn.line('.')
    local buf = api.nvim_get_current_buf()
    local rows = vim.fn.line("$")
    local is_global = false

    --  Open the bookmark description input box.
    local title = "Input description:"
    if is_global then
        title = "Global Input description:"
    end
    local bufs_pairs = w.open_add_win(title)

    -- Press the esc key to cancel add bookmark.
    vim.keymap.set("n", "<ESC>",
        function() w.close_add_win(bufs_pairs.pairs.buf, bufs_pairs.border_pairs.buf) end,
        { desc = "bookmarks close add win", silent = true, buffer = bufs_pairs.pairs.buf }
    )

    -- Press the enter key to confirm add bookmark.
    vim.keymap.set("i", "<CR>",
        function() M.handle_add(line, bufs_pairs.pairs.buf, bufs_pairs.border_pairs.buf, buf, rows, is_global) end,
        { desc = "bookmarks confirm bookmarks", silent = true, noremap = true, buffer = bufs_pairs.pairs.buf }
    )
end

function M.handle_add(line, buf1, buf2, buf, rows, is_global)
    -- Get buf's filename.
    local filename = api.nvim_buf_get_name(buf)
    if filename == nil or filename == "" then
        return
    end

    local input_line = vim.fn.line(".")
    -- Get bookmark's description.
    local description = api.nvim_buf_get_lines(buf1, input_line - 1, input_line, false)[1] or ""
    if description ~= "" then
        local content = api.nvim_buf_get_lines(buf, line - 1, line, true)[1]
        -- Save bookmark with description.
        M.add(filename, line, md5.sumhexa(content),
            description, rows, is_global)
    end

    -- Close description input box.
    w.close_add_win(buf1, buf2)
    m.set_marks(buf, M.get_buf_bookmark_lines(0))
    vim.cmd("stopinsert")
end

-- Save bookmark as lua code.
-- rows is the file's number..
function M.add(filename, line, line_md5, description, rows, is_global)
    local id = md5.sumhexa(string.format("%s:%s", filename, line))
    local now = os.time()
    local cuts = description:split_b(":")
    local tags = ""
    if #cuts > 1 then
        tags = cuts[1]
        description = string.sub(description, #tags + 2)
    end

    if data.bookmarks[id] ~= nil then --update description
        if description ~= nil then
            data.bookmarks[id].description = description
            data.bookmarks[id].updated_at = now
            data.bookmarks[id].tags = tags
        end
    else -- new
        data.bookmarks[id] = {
            filename = filename,
            id = id,
            tags = tags,
            line = line,
            description = description or "",
            updated_at = now,
            fre = 1,
            rows = rows,         -- for fix
            line_md5 = line_md5, -- for fix
            is_global = is_global,
            is_new = true,
        }

        if data.bookmarks_groupby_filename[filename] == nil then
            data.bookmarks_groupby_filename[filename] = { id }
        else
            data.bookmarks_groupby_filename[filename][#data.bookmarks_groupby_filename[filename] + 1] = id
        end

        if data.bookmarks_groupby_tags["ALL"] == nil then
            data.bookmarks_groupby_tags["ALL"] = {}
        end
        data.bookmarks_groupby_tags["ALL"][#data.bookmarks_groupby_tags["ALL"] + 1] = id

        if tags ~= "" then
            if data.bookmarks_groupby_tags[tags] == nil then
                data.bookmarks_groupby_tags[tags] = { id }
            else
                data.bookmarks_groupby_tags[tags][#data.bookmarks_groupby_tags[tags] + 1] = id
            end
        end
    end
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
            w.regroup_tags(v.tags)
            m.set_marks(buf, M.get_buf_bookmark_lines(0))
            return
        end
    end
end

-- Write bookmarks into disk file for next load.
function M.persistent()
    local local_str = ""
    local global_str = ""
    local global_old_data = {}
    for id, bookmark in pairs(data.bookmarks) do
        local sub = M.fill_tpl(bookmark)
        if bookmark["is_global"] ~= nil and bookmark["is_global"] == true then -- global bookmarks
            if bookmark["is_new"] == true then
                if global_str == "" then
                    global_str = string.format("%s%s", global_str, sub)
                else
                    global_str = string.format("%s\n%s", global_str, sub)
                end
            end
            global_old_data[id] = bookmark
        else
            if local_str == "" then
                local_str = string.format("%s%s", local_str, sub)
            else
                local_str = string.format("%s\n%s", local_str, sub)
            end
        end
    end

    if data.data_filename == nil then -- lazy load,
        return
    end

    -- 1.local bookmarks
    local local_fd = assert(io.open(data.data_filename, "w"))
    local_fd:write(local_str)
    local_fd:close()

    -- 2.global bookmarks
    local global_file_name = config.storage_dir .. config.sep_path .. "bookmarks_global"
    if vim.loop.fs_stat(global_file_name) then
        data.bookmarks = {}
        dofile(global_file_name)
        -- combine
        for id, bookmark in pairs(data.bookmarks) do
            if global_old_data[id] ~= nil then
                global_str = string.format("%s\n%s", global_str, M.fill_tpl(global_old_data[id]))
            elseif data.deleted_ids[id] == nil then
                global_str = string.format("%s\n%s", global_str, M.fill_tpl(bookmark)) -- new
            end
        end
    end

    local global_fd = assert(io.open(global_file_name, "w"))
    global_fd:write(global_str)
    global_fd:close()
end

function M.fill_tpl(bookmark)
    local tpl = [[
require("bookmarks.list").load{
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
                -- issue #37
                if config.sep_path == "\\" and k == "filename" then
                    v = string.gsub(v, "[\\]", "\\\\")
                end
                sub = sub .. string.format("%s = \"%s\",", k, v)
            end
        end
    end

    return string.gsub(tpl, "_", sub)
end

-- 获取书签存储根目录
function M.get_base_dir()
    -- git
    local dot_git_path = vim.fn.finddir(".git", ".;")
    local res = vim.fn.fnamemodify(dot_git_path, ":h")
    if res == "" then
        -- cwd
        return vim.uv.cwd()
    end
    return res
end

-- Restore bookmarks from disk file.
function M.load_data()
    -- vim.notify("load bookmarks data", "info")
    local currentPath = string.gsub(M.get_base_dir(), "/", "_")
    if data.pwd ~= nil and currentPath ~= data.pwd then -- maybe change session
        M.persistent()
        data.bookmarks = {}
        data.loaded_data = false
    end

    if data.loaded_data == true then
        return
    end

    if not vim.loop.fs_stat(config.storage_dir) then
        assert(os.execute("mkdir " .. config.storage_dir))
    end

    -- local bookmarks
    local data_filename = string.format("%s%s%s", config.storage_dir, config.sep_path, currentPath)
    if vim.loop.fs_stat(data_filename) then
        dofile(data_filename)
    end

    -- global bookmarks
    local global_data_filename = config.storage_dir .. config.sep_path .. "bookmarks_global"
    if vim.loop.fs_stat(global_data_filename) then
        dofile(global_data_filename)
    end

    data.pwd = currentPath
    data.loaded_data = true -- mark
    data.data_dir = config.storage_dir
    data.data_filename = data_filename
end

-- 这个不能删，dotfile的时候要用
-- Dofile
function M.load(item, is_persistent)
    data.bookmarks[item.id] = item
    if is_persistent ~= nil and is_persistent == true then
        return
    end

    if data.bookmarks_groupby_filename[item.filename] == nil then
        data.bookmarks_groupby_filename[item.filename] = {}
    end
    data.bookmarks_groupby_filename[item.filename][#data.bookmarks_groupby_filename[item.filename] + 1] = item.id

    if data.bookmarks_groupby_tags["ALL"] == nil then
        data.bookmarks_groupby_tags["ALL"] = {}
    end
    data.bookmarks_groupby_tags["ALL"][#data.bookmarks_groupby_tags["ALL"] + 1] = item.id

    if item.tags ~= nil and item.tags ~= "" then
        if data.bookmarks_groupby_tags[item.tags] == nil then
            data.bookmarks_groupby_tags[item.tags] = {}
        end
        data.bookmarks_groupby_tags[item.tags][#data.bookmarks_groupby_tags[item.tags] + 1] = item.id
    end
end

return M

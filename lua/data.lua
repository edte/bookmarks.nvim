local M = {
    bookmarks = {},                  -- filename description fre id line updated_at line_md5
    bookmarks_groupby_filename = {}, -- group bookmarks by filename
    pwd = nil,
    data_filename = nil,
    loaded_data = false,
    data_dir = nil,
    autocmd = 0,   -- cursormoved autocmd id
    filename = "", -- current bookmarks filename
}

return M

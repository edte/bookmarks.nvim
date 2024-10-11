local M = {
    data = {
        -- Default path: vim.fn.stdpath("data").."/bookmarks,  if not the default directory, should be absolute path",
        storage_dir = "",                                                                   -- default vim.fn.stdpath("data").."/bookmarks",
        keymap = {
            add = "mm",                                                                     -- add bookmarks
            jump = "mo",
            delete = "mD",                                                                  -- delete bookmark at virt text line
        },
        width = 0.8,                                                                        -- bookmarks window width:  (0, 1]
        height = 0.7,                                                                       -- bookmarks window height: (0, 1]
        virt_text = "",                                                                     -- Show virt text at the end of bookmarked lines, if it is empty, use the description of bookmarks instead.
        virt_pattern = { "*.go", "*.lua", "*.sh", "*.php", "*.rs", "*.cpp", "*.h", "*.c" }, -- Show virt text only on matched pattern
        virt_ignore_pattern = {},                                                           -- Ignore virt text on matched pattern
        border_style = "single",                                                            -- border style: "single", "double", "rounded"
        hl = {
            border = "TelescopeBorder",                                                     -- border highlight
            cursorline = "guibg=Gray guifg=White",                                          -- cursorline highlight
        },
        sep_path = "/",
        datetime_format = "%Y-%m-%d %H:%M:%S", -- os.date
    }
}

function M.setup()
    vim.cmd("hi link bookmarks_virt_text_hl Comment")
    M.data.storage_dir = vim.fn.stdpath("data") .. "/bookmarks"
    vim.fn.sign_define("BookmarkSign", { text = "󰃃" })
end

function M.get_data()
    return M.data
end

return M

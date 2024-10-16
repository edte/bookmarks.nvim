local M = {
    data = {
        width = 0.8,                                                                        -- bookmarks window width:  (0, 1]
        height = 0.7,                                                                       -- bookmarks window height: (0, 1]
        virt_text = "",                                                                     -- Show virt text at the end of bookmarked lines, if it is empty, use the description of bookmarks instead.
        hl = {
            border = "TelescopeBorder",                                                     -- border highlight
            cursorline = "guibg=Gray guifg=White",                                          -- cursorline highlight
        },
        datetime_format = "%Y-%m-%d %H:%M:%S",                                              -- os.date
    }
}



return M

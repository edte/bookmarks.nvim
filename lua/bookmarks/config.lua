local M = {
    data = {
        -- Default path: vim.fn.stdpath("data").."/bookmarks,  if not the default directory, should be absolute path",
        storage_dir = "", -- default vim.fn.stdpath("data").."/bookmarks",
        mappings_enabled = true,
        keymap = {
            add = "mm",       -- add bookmarks
            jump = "mo",
            delete = "mD",    -- delete bookmark at virt text line
        },
        width = 0.8,          -- bookmarks window width:  (0, 1]
        height = 0.7,         -- bookmarks window height: (0, 1]
        preview_ratio = 0.45, -- bookmarks preview window ratio (0.1]
        tags_ratio = 0.1,
        fzflua = false,
        virt_text = "", -- Show virt text at the end of bookmarked lines, if it is empty, use the description of bookmarks instead.
        sign_icon = "󰃃", -- if it is not empty, show icon in signColumn.
        virt_pattern = { "*.go", "*.lua", "*.sh", "*.php", "*.rs", "*.cpp", "*.h", "*.c" }, -- Show virt text only on matched pattern
        virt_ignore_pattern = {}, -- Ignore virt text on matched pattern
        border_style = "single", -- border style: "single", "double", "rounded"
        hl = {
            border = "TelescopeBorder", -- border highlight
            cursorline = "guibg=Gray guifg=White", -- cursorline highlight
        },
        sep_path = "/",
        datetime_format = "%Y-%m-%d %H:%M:%S", -- os.date
    }
}

function M.setup()
    vim.cmd("hi link bookmarks_virt_text_hl Comment")
    M.data.storage_dir = vim.fn.stdpath("data") .. "/bookmarks"

    if M.data.sign_icon ~= "" then
        vim.fn.sign_define("BookmarkSign", { text = M.data.sign_icon })
    end
end

function M.get_data()
    return M.data
end

return M

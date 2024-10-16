local M = {
    ns_id = api.nvim_create_namespace("bookmarks_marks"),
    marks = {},

    virt_text = "", -- Show virt text at the end of bookmarked lines, if it is empty, use the description of bookmarks instead.
}

-- Add virtural text for bookmarks.
function M.set_marks(buf, marks)
    local file_name = vim.api.nvim_buf_get_name(buf)
    local text = M.virt_text
    if M.marks[file_name] == nil then
        M.marks[file_name] = {}
    end

    -- clear old ext
    for _, id in ipairs(M.marks[file_name]) do
        api.nvim_buf_del_extmark(buf, M.ns_id, id)
    end

    vim.fn.sign_unplace("BookmarkSign", { buffer = buf })

    -- set new old ext
    for _, mark in ipairs(marks) do
        if mark.line > vim.fn.line("$") then
            goto continue
        end

        local virt_text = text
        if virt_text == "" then
            virt_text = mark.description
        end
        local ext_id = api.nvim_buf_set_extmark(buf, M.ns_id, mark.line - 1, -1, {
            virt_text = { { virt_text, "bookmarks_virt_text_hl" } },
            virt_text_pos = "eol",
            hl_group = "bookmarks_virt_text_hl",
            hl_mode = "combine"
        })
        M.marks[file_name][#M.marks[file_name] + 1] = ext_id

        vim.fn.sign_place(0, "BookmarkSign", "BookmarkSign", buf, {
            lnum = mark.line,
        })
        ::continue::
    end
end

return M

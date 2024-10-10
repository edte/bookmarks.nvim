local config = require("bookmarks.config")
local event = require("bookmarks.event")
local list = require("bookmarks.list")
local window = require("bookmarks.window")

local M = {}

-- List bookmark by fzflua.

--  字符串扩展方法 split_b，用于将字符串按照指定的分隔符 sep 进行分割，并返回一个包含切割结果的表
function string:split_b(sep)
    local cuts = {}
    for v in string.gmatch(self, "[^'" .. sep .. "']+") do
        table.insert(cuts, v)
    end

    return cuts
end

function M.setup()
    config.setup()
    list.setup()
    event.setup()
    window.setup()
end

return M

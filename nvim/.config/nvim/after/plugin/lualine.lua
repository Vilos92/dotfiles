if vim.g.vscode then
  return
end

local media_controls = require("media-controls")
media_controls.status_poll()

require("lualine").setup({
  options = { theme = "auto" },
  sections = {
    lualine_a = { "mode" },
    lualine_b = { "branch", "diff", "diagnostics" },
    lualine_c = {
      media_controls.status_listen,
    },
    lualine_x = {
      "filename",
      "encoding",
      "fileformat",
      "filetype",
    },
    lualine_y = { "progress" },
    lualine_z = { "location" },
  },

  inactive_sections = {
    lualine_a = {},
    lualine_b = {},
    lualine_c = {
      media_controls.listen,
    },
    lualine_x = { "filename", "location" },
    lualine_y = {},
    lualine_z = {},
  },
})

if vim.g.vscode then
  return
end

local media_controls = require("media-controls")
media_controls.status_poll()

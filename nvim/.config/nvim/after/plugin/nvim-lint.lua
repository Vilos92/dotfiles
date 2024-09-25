if vim.g.vscode then
  return
end

local lint = require("lint")

lint.linters_by_ft = {
  javascript = { "eslint_d" },
}

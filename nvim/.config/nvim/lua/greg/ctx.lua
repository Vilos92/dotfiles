local M = {}

---@return string JSON with file, start_line, end_line, text
function M.json()
  local sl = vim.fn.line("'<")
  local el = vim.fn.line("'>")
  local file = vim.fn.expand("%:p")
  local text

  if sl == 0 then
    sl = 1
    el = vim.fn.line("$")
    text = table.concat(vim.api.nvim_buf_get_lines(0, 0, -1, false), "\n")
  else
    text = table.concat(vim.fn.getline(sl, el) --[[@as string[] ]], "\n")
  end

  return vim.json.encode({ file = file, start_line = sl, end_line = el, text = text })
end

_G.NvimCtxJSON = M.json

vim.api.nvim_create_user_command("NvimCtx", function()
  print(M.json())
end, {})

return M

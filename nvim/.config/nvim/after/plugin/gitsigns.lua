if vim.g.vscode then
  return
end

if require("greg.gitsigns").setup() then
  return
end

-- First launch may install gitsigns asynchronously; PackChanged retriggers setup.
vim.api.nvim_create_autocmd("PackChanged", {
  callback = function(ev)
    if ev.data.spec.name ~= "gitsigns.nvim" then
      return
    end
    vim.schedule(function()
      require("greg.gitsigns").setup()
    end)
  end,
})

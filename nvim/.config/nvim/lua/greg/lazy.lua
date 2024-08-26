-- Bootstrap lazy.nvim
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  local lazyrepo = "https://github.com/folke/lazy.nvim.git"
  vim.fn.system({ "git", "clone", "--filter=blob:none", "--branch=stable", lazyrepo, lazypath })
end
vim.opt.rtp:prepend(lazypath)

-- Make sure to setup `mapleader` and `maplocalleader` before
-- loading lazy.nvim so that mappings are correct.
-- This is also a good place to setup other settings (vim.opt)
vim.g.mapleader = " "
vim.g.maplocalleader = "\\"

-- Setup lazy.nvim
require("lazy").setup({
  spec = {
    -- import your plugins
    { import = "greg.plugins" },
  },

  -- automatically check for plugin updates
  checker = {
    enabled = {
      enabled = true,
      concurrency = nil,
      notify = true,
      -- 7 days * 24 hours/minute * 60 minutes/hour * 60 seconds/minute
      frequency = 7 * 24 * 60 * 60,
      check_pinned = false,
    },
  },

  -- colorscheme that will be used when installing plugins.
  install = { colorscheme = { "catppuccin-frappe" } },
})

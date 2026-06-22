-- Neovim 0.12+ built-in plugin manager (:help vim.pack)
if not vim.pack then
  vim.notify("Neovim 0.12+ is required (vim.pack). Install stable: brew install neovim", vim.log.levels.ERROR)
  return
end

local gh = function(repo)
  return "https://github.com/" .. repo
end

-- Track default branches here; resolved commits live in `nvim-pack-lock.json`.
-- Run `vim.pack.update()` (or MiniStarter → Pack Update), review, then `:w` to apply.
vim.api.nvim_create_autocmd("PackChanged", {
  callback = function(ev)
    local name, kind = ev.data.spec.name, ev.data.kind
    if name == "nvim-treesitter" and (kind == "install" or kind == "update") then
      vim.schedule(function()
        pcall(vim.cmd, "TSUpdate")
      end)
    end
    if name == "gitsigns.nvim" and (kind == "install" or kind == "update") then
      vim.schedule(function()
        pcall(require, "greg.gitsigns")
      end)
    end
  end,
})

vim.pack.add({
  -- Shared dependencies first (load order follows spec order after install)
  { src = gh("nvim-lua/plenary.nvim"), version = "master" },
  { src = gh("nvim-tree/nvim-web-devicons"), version = "master" },
  { src = gh("folke/which-key.nvim"), version = "main" },

  { src = gh("nvim-treesitter/nvim-treesitter"), version = "main" },
  { src = gh("OXY2DEV/markview.nvim"), version = "main" },

  { src = gh("williamboman/mason.nvim"), version = "main" },
  { src = gh("williamboman/mason-lspconfig.nvim"), version = "main" },
  { src = gh("neovim/nvim-lspconfig"), version = "master" },
  { src = gh("hrsh7th/nvim-cmp"), version = "main" },
  { src = gh("hrsh7th/cmp-nvim-lsp"), version = "main" },
  { src = gh("L3MON4D3/LuaSnip"), version = "master" },
  { src = gh("VonHeikemen/lsp-zero.nvim"), version = "v4.x" },

  { src = gh("nvimtools/none-ls.nvim"), version = "main" },
  { src = gh("nvimtools/none-ls-extras.nvim"), version = "main" },
  { src = gh("gbprod/none-ls-shellcheck.nvim"), version = "main" },
  { src = gh("stevearc/conform.nvim"), version = "master" },

  { src = gh("mbbill/undotree"), version = "master" },
  { src = gh("numToStr/Comment.nvim"), version = "master" },
  { src = gh("tpope/vim-fugitive"), version = "master" },
  { src = gh("lewis6991/gitsigns.nvim"), version = "main" },

  { src = gh("nvim-lualine/lualine.nvim"), version = "master" },
  { src = gh("echasnovski/mini.starter"), version = "main" },

  { src = gh("stevearc/oil.nvim"), version = "master" },
  -- Nvim 0.12 + nvim-treesitter main: preview uses vim.treesitter.language (older pins call removed parsers.ft_to_lang).
  { src = gh("nvim-telescope/telescope.nvim"), version = "master" },
  { src = gh("ThePrimeagen/harpoon"), version = "master" },

  { src = gh("zaldih/themery.nvim"), version = "main" },
  { src = gh("xiyaowong/nvim-transparent"), version = "main" },

  { src = gh("rose-pine/neovim"), name = "rose-pine", version = "main" },
  { src = gh("catppuccin/nvim"), name = "catppuccin", version = "main" },
  { src = gh("folke/tokyonight.nvim"), name = "tokyonight", version = "main" },
  { src = gh("gbprod/nord.nvim"), version = "main" },
}, { load = true })

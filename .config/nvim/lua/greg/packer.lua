-- This file can be loaded by calling `lua require('plugins')` from your init.vim

-- Only required if you have packer configured as `opt`
vim.cmd [[packadd packer.nvim]]

return require('packer').startup(function(use)
  -- Packer can manage itself
  use 'wbthomason/packer.nvim'

  -- Fuzzy finder
  use {
    'nvim-telescope/telescope.nvim', tag = '0.1.6',
    -- or                         , branch = '0.1.x',
    requires = { {'nvim-lua/plenary.nvim'} }
  }

  -- Theme
  use({
    'rose-pine/neovim',
    as = 'rose-pine',
    config = function()
      vim.cmd('colorscheme rose-pine')
    end
  })

  -- Tree sitter
  use('nvim-treesitter/nvim-treesitter', { run = ':TSUpdate' })
  use('nvim-treesitter/playground')

  -- Undo tree
  use('mbbill/undotree')

  -- Primagen's finder.
  use('theprimeagen/harpoon')

  -- vim-fugitive for additional Git capabilities
  use('tpope/vim-fugitive')

  -- lsp-zero
  use {
    'VonHeikemen/lsp-zero.nvim',
    branch = 'v3.x',
    requires = {
      -- The two plugins below allow neovim to manage the language servers.
      {'williamboman/mason.nvim'},
      {'williamboman/mason-lspconfig.nvim'},
  
      {'neovim/nvim-lspconfig'},
      {'hrsh7th/nvim-cmp'},
      {'hrsh7th/cmp-nvim-lsp'},
      {'L3MON4D3/LuaSnip'},
    }
  }

  -- Nerd tree
  use('nvim-tree/nvim-tree.lua')

  -- Comments
  use {
    'numToStr/Comment.nvim',
    config = function()
      require('Comment').setup()
    end
  }

  -- prettier
  use('neovim/nvim-lspconfig')
  use('jose-elias-alvarez/null-ls.nvim')
  use('MunifTanjim/prettier.nvim')

  -- GitHub copilot
  use('github/copilot.vim')
end)

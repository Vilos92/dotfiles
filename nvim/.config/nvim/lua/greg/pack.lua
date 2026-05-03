-- Neovim 0.12+ built-in plugin manager (:help vim.pack)
if not vim.pack then
  vim.notify("Neovim 0.12+ is required (vim.pack). Install stable: brew install neovim", vim.log.levels.ERROR)
  return
end

local gh = function(repo)
  return "https://github.com/" .. repo
end

-- Pinned revisions (previously lazy-lock.json). Run `vim.pack.update()` to refresh.
vim.api.nvim_create_autocmd("PackChanged", {
  callback = function(ev)
    local name, kind = ev.data.spec.name, ev.data.kind
    if name == "nvim-treesitter" and (kind == "install" or kind == "update") then
      vim.schedule(function()
        pcall(vim.cmd, "TSUpdate")
      end)
    end
  end,
})

vim.pack.add({
  -- Shared dependencies first (load order follows spec order after install)
  { src = gh("nvim-lua/plenary.nvim"), version = "74b06c6c75e4eeb3108ec01852001636d85a932b" },
  { src = gh("nvim-tree/nvim-web-devicons"), version = "4fc505ac7bd7692824a142e96e5f529c133862f8" },

  { src = gh("nvim-treesitter/nvim-treesitter"), version = "cf12346a3414fa1b06af75c79faebe7f76df080a" },
  { src = gh("nvim-treesitter/playground"), version = "ba48c6a62a280eefb7c85725b0915e021a1a0749" },
  { src = gh("OXY2DEV/markview.nvim"), version = "dbf74b6db11c1468d5128a38b26b6d99dc7316e9" },

  { src = gh("williamboman/mason.nvim"), version = "cb8445f8ce85d957416c106b780efd51c6298f89" },
  { src = gh("williamboman/mason-lspconfig.nvim"), version = "0c2823e0418f3d9230ff8b201c976e84de1cb401" },
  { src = gh("neovim/nvim-lspconfig"), version = "31026a13eefb20681124706a79fc1df6bf11ab27" },
  { src = gh("hrsh7th/nvim-cmp"), version = "a1d504892f2bc56c2e79b65c6faded2fd21f3eca" },
  { src = gh("hrsh7th/cmp-nvim-lsp"), version = "cbc7b02bb99fae35cb42f514762b89b5126651ef" },
  { src = gh("L3MON4D3/LuaSnip"), version = "a62e1083a3cfe8b6b206e7d3d33a51091df25357" },
  { src = gh("VonHeikemen/lsp-zero.nvim"), version = "77550f2f6cbf0959ef1583d845661af075f3442b" },

  { src = gh("nvimtools/none-ls.nvim"), version = "241ff8214b4ec051eb51e74a61ff729c0271b429" },
  { src = gh("nvimtools/none-ls-extras.nvim"), version = "70ec8815cdf186223af04cc5a15bc8bdface0ef0" },
  { src = gh("gbprod/none-ls-shellcheck.nvim"), version = "0f84461241e76e376a95fb7391deac82dc3efdbf" },
  { src = gh("stevearc/conform.nvim"), version = "dca1a190aa85f9065979ef35802fb77131911106" },

  { src = gh("mbbill/undotree"), version = "6fa6b57cda8459e1e4b2ca34df702f55242f4e4d" },
  { src = gh("numToStr/Comment.nvim"), version = "e30b7f2008e52442154b66f7c519bfd2f1e32acb" },
  { src = gh("tpope/vim-fugitive"), version = "3b753cf8c6a4dcde6edee8827d464ba9b8c4a6f0" },

  { src = gh("nvim-lualine/lualine.nvim"), version = "131a558e13f9f28b15cd235557150ccb23f89286" },
  { src = gh("echasnovski/mini.starter"), version = "7bdc9decc8b623f245c1e42a64bc41e61d574c5e" },

  { src = gh("stevearc/oil.nvim"), version = "0fcc83805ad11cf714a949c98c605ed717e0b83e" },
  { src = gh("nvim-telescope/telescope.nvim"), version = "6312868392331c9c0f22725041f1ec2bef57c751" },
  { src = gh("ThePrimeagen/harpoon"), version = "1bc17e3e42ea3c46b33c0bbad6a880792692a1b3" },

  { src = gh("zaldih/themery.nvim"), version = "bfa58f4b279d21cb515b28023e1b68ec908584b2" },
  { src = gh("xiyaowong/nvim-transparent"), version = "8ac59883de84e9cd1850ea25cf087031c5ba7d54" },

  { src = gh("rose-pine/neovim"), name = "rose-pine", version = "6a961effd67f6130d36df6d1c05c48c739796dd2" },
  { src = gh("catppuccin/nvim"), name = "catppuccin", version = "426dbebe06b5c69fd846ceb17b42e12f890aedf1" },
  { src = gh("folke/tokyonight.nvim"), name = "tokyonight", version = "cdc07ac78467a233fd62c493de29a17e0cf2b2b6" },
  { src = gh("gbprod/nord.nvim"), version = "87394d4fc35c901bbe38326a78d31ab1ead826b6" },
}, { load = true })

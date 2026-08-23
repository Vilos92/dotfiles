if vim.g.vscode then
  return
end

require("rose-pine")
require("catppuccin")
require("tokyonight")
require("nord").setup({})
-- everforest exposes one `everforest` colorscheme; dark/light is picked via vim.o.background.
require("everforest").setup({ background = "medium" })

local themes = {
  "rose-pine-moon",
  "rose-pine-dawn",
  "catppuccin-latte",
  "catppuccin-frappe",
  "catppuccin-macchiato",
  "catppuccin-mocha",
  "nord",
  "tokyonight-night",
  "tokyonight-storm",
  "tokyonight-day",
  "tokyonight-moon",
  "everforest-dark",
  "everforest-light",
}

-- Both everforest entries load the single `everforest` colorscheme, differing only by background.
local everforest_bg = {
  ["everforest-dark"] = "dark",
  ["everforest-light"] = "light",
}

-- Apply a logical theme name; everforest needs its background set before the colorscheme.
local function set_colorscheme(name)
  local bg = everforest_bg[name]
  if bg then
    vim.o.background = bg
    pcall(vim.cmd, "colorscheme everforest")
  else
    pcall(vim.cmd, "colorscheme " .. name)
  end
end

-- Alacritty uses underscores for tokyonight; everything else matches nvim's name.
local alacritty_map = {
  ["tokyonight-night"] = "tokyonight_night",
  ["tokyonight-storm"] = "tokyonight_storm",
  ["tokyonight-day"] = "tokyonight_day",
  ["tokyonight-moon"] = "tokyonight_moon",
}

local state_file = vim.fn.stdpath("data") .. "/theme.json"

local function apply_alacritty(scheme)
  local name
  if scheme == "everforest" then
    -- The colorscheme name alone is ambiguous; background tells dark from light.
    name = (vim.o.background == "light") and "everforest-light" or "everforest-dark"
  else
    name = alacritty_map[scheme] or scheme
  end
  vim.fn.jobstart({ "alacritty-theme", name }, { detach = true })
end

local function save_theme(scheme)
  local f = io.open(state_file, "w")
  if f then
    f:write(vim.fn.json_encode({ colorscheme = scheme }))
    f:close()
  end
end

local function load_theme()
  local f = io.open(state_file, "r")
  if not f then
    -- Migrate from themery's state file on first run.
    f = io.open(vim.fn.stdpath("data") .. "/themery/state.json", "r")
  end
  if not f then
    return
  end
  local content = f:read("*a")
  f:close()
  local ok, data = pcall(vim.fn.json_decode, content)
  if ok and data and data.colorscheme then
    set_colorscheme(data.colorscheme)
  end
end

local function open_picker()
  local original = vim.g.colors_name
  -- Restoring everforest needs the background too, since it disambiguates the variant.
  local original_bg = vim.o.background

  local function restore()
    if original then
      vim.o.background = original_bg
      pcall(vim.cmd, "colorscheme " .. original)
    end
  end

  local pickers = require("telescope.pickers")
  local finders = require("telescope.finders")
  local conf = require("telescope.config").values
  local actions = require("telescope.actions")
  local action_state = require("telescope.actions.state")

  local function apply_selected()
    local sel = action_state.get_selected_entry()
    if sel then
      set_colorscheme(sel.value)
    end
  end

  pickers
    .new({}, {
      prompt_title = "Theme",
      finder = finders.new_table({ results = themes }),
      sorter = conf.generic_sorter({}),
      attach_mappings = function(prompt_bufnr, map)
        local function nav_next()
          actions.move_selection_next(prompt_bufnr)
          apply_selected()
        end

        local function nav_prev()
          actions.move_selection_previous(prompt_bufnr)
          apply_selected()
        end

        local function confirm()
          local sel = action_state.get_selected_entry()
          actions.close(prompt_bufnr)
          if sel then
            set_colorscheme(sel.value)
            save_theme(sel.value)
          else
            restore()
          end
        end

        local function cancel()
          actions.close(prompt_bufnr)
          restore()
        end

        map("i", "<C-n>", nav_next)
        map("i", "<Down>", nav_next)
        map("n", "j", nav_next)
        map("n", "<Down>", nav_next)
        map("i", "<C-p>", nav_prev)
        map("i", "<Up>", nav_prev)
        map("n", "k", nav_prev)
        map("n", "<Up>", nav_prev)
        map("i", "<CR>", confirm)
        map("n", "<CR>", confirm)
        map("i", "<Esc>", cancel)
        map("n", "<Esc>", cancel)
        map("i", "<C-c>", cancel)
        map("n", "q", cancel)

        return true
      end,
    })
    :find()
end

-- Expose for mini.starter and other callers.
vim.g.theme_picker = open_picker

vim.api.nvim_create_autocmd("ColorScheme", {
  callback = function(ev)
    apply_alacritty(ev.match)
  end,
})

load_theme()

-- Reload when alacritty-theme-select writes theme.json externally.
local watcher = vim.uv.new_fs_event()
if watcher then
  watcher:start(
    state_file,
    {},
    vim.schedule_wrap(function(err)
      if not err then
        load_theme()
      end
    end)
  )
end

vim.keymap.set("n", "<leader>t", open_picker, { desc = "Theme picker" })

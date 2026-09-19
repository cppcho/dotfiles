-- Oil, the snacks explorer sidebar and the fugitive status split all own file
-- navigation, so only one is ever up: each opener tears the other two down.
-- Required from the plugin specs that own the keymaps (`-`, `<C-e>`,
-- `<leader>gs`).

local M = {}

local function close_explorer()
  local explorer = Snacks.picker.get({ source = "explorer" })[1]
  if explorer then
    explorer:close()
  end
end

-- Closing oil drops the window back to the buffer oil replaced, so the window
-- itself survives and the cursor can return to where it started.
local function close_oil()
  local cur = vim.api.nvim_get_current_win()
  for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
    if vim.api.nvim_win_is_valid(win) and vim.bo[vim.api.nvim_win_get_buf(win)].filetype == "oil" then
      vim.api.nvim_set_current_win(win)
      require("oil").close()
    end
  end
  if vim.api.nvim_win_is_valid(cur) then
    vim.api.nvim_set_current_win(cur)
  end
end

local function git_status_win()
  for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
    if vim.bo[vim.api.nvim_win_get_buf(win)].filetype == "fugitive" then
      return win
    end
  end
end

local function close_git_status()
  local win = git_status_win()
  if win then
    pcall(vim.api.nvim_win_close, win, false)
  end
end

---@param dir? string directory to browse; defaults to the current file's
function M.open_oil(dir)
  close_explorer()
  close_git_status()
  require("oil").open(dir)
end

-- Browse the epics the cppcho skills keep in the repo's `.scratch/epics`
-- (one directory per epic, holding its spec and tickets).
function M.open_epics()
  local root = vim.fs.root(0, ".git") or vim.fs.root(vim.fn.getcwd(), ".git") or vim.fn.getcwd()
  local epics = root .. "/.scratch/epics"
  if vim.fn.isdirectory(epics) == 0 then
    vim.notify("No epics in " .. vim.fn.fnamemodify(epics, ":~"), vim.log.levels.WARN)
    return
  end
  M.open_oil(epics)
end

-- Snacks' picker closes an explorer that is already up, so this stays a toggle.
function M.toggle_explorer()
  close_oil()
  close_git_status()
  Snacks.explorer()
end

function M.reveal_in_explorer()
  close_oil()
  close_git_status()
  Snacks.explorer.reveal()
end

function M.toggle_git_status()
  if git_status_win() then
    close_git_status()
    return
  end
  close_oil()
  close_explorer()
  vim.cmd("topleft 12split | 0Git")
end

-- Blow every other window away so the focused file fills the tab. Only acts
-- from a real file window: every pane worth keeping (oil, the explorer, the
-- status split, quickfix, terminals) has a non-empty buftype, so zooming from
-- one of those would close the file you actually wanted to see. The explorer
-- goes through the picker rather than `only`, which would leave the picker
-- alive with no windows.
function M.zoom()
  if vim.bo.buftype ~= "" then
    return
  end
  close_explorer()
  if vim.wo.diff then
    vim.cmd("diffoff!")
  end
  vim.cmd("only")
end

return M

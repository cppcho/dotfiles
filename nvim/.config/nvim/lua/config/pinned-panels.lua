-- Panels keep their window: a file that opens while one is focused is moved to
-- a real editing window instead of taking the panel's place.
--
-- Diffview's file panel is 35 columns wide, so anything that edits a buffer
-- from there (a picker result, a quickfix jump, `:edit`) leaves the file in an
-- unreadable strip with the diff still filling the rest of the tab, and the
-- panel gone. Nothing about the window afterwards says a panel was ever there,
-- so each window records the panel buffer it is showing and the swap is undone
-- once it happens.

local PANEL_FILETYPES = {
  DiffviewFiles = true,
  DiffviewFileHistory = true,
}

-- Where a redirected file goes: the roomiest window holding an ordinary
-- buffer. Floats belong to whatever opened them, diff windows are half of a
-- comparison, and panels are what we are protecting, so none of them qualify.
local function target_window(exclude)
  local best, best_width
  for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
    local buf = vim.api.nvim_win_get_buf(win)
    if
      win ~= exclude
      and vim.api.nvim_win_get_config(win).relative == ""
      and vim.bo[buf].buftype == ""
      and not vim.wo[win].diff
      and not vim.w[win].pinned_panel
    then
      local width = vim.api.nvim_win_get_width(win)
      if not best_width or width > best_width then
        best, best_width = win, width
      end
    end
  end
  return best
end

local function redirect(win, buf, panel)
  local cursor = vim.api.nvim_win_get_cursor(win)
  vim.api.nvim_win_set_buf(win, panel)

  local target = target_window(win)
  if not target then
    -- A diffview tab owns every window in it; a file has nowhere to go here.
    vim.cmd("tabnew")
    target = vim.api.nvim_get_current_win()
  end

  vim.api.nvim_win_set_buf(target, buf)
  vim.api.nvim_set_current_win(target)
  pcall(vim.api.nvim_win_set_cursor, target, cursor)
end

local group = vim.api.nvim_create_augroup("pinned-panels", { clear = true })

-- A panel's filetype can be set either before it is put in a window or after,
-- so both orders have to mark the window.
vim.api.nvim_create_autocmd("FileType", {
  group = group,
  pattern = vim.tbl_keys(PANEL_FILETYPES),
  callback = function(ev)
    local win = vim.api.nvim_get_current_win()
    if vim.api.nvim_win_get_buf(win) == ev.buf then vim.w[win].pinned_panel = ev.buf end
  end,
})

vim.api.nvim_create_autocmd("BufWinEnter", {
  group = group,
  callback = function(ev)
    local win = vim.api.nvim_get_current_win()
    if vim.api.nvim_win_get_buf(win) ~= ev.buf then return end

    if PANEL_FILETYPES[vim.bo[ev.buf].filetype] then
      vim.w[win].pinned_panel = ev.buf
      return
    end

    local panel = vim.w[win].pinned_panel
    -- Only ordinary files are worth moving; help, quickfix and terminals that
    -- ask for this window can have it.
    if not panel or vim.bo[ev.buf].buftype ~= "" then return end
    if not vim.api.nvim_buf_is_valid(panel) then
      vim.w[win].pinned_panel = nil
      return
    end

    -- Deferred: rearranging windows from inside the autocmd that put the buffer
    -- in one is a good way to confuse whatever is mid-jump.
    vim.schedule(function()
      if
        vim.api.nvim_win_is_valid(win)
        and vim.api.nvim_buf_is_valid(panel)
        and vim.api.nvim_win_get_buf(win) == ev.buf
      then
        redirect(win, ev.buf, panel)
      end
    end)
  end,
})

-- Panels keep their window: a file that opens while one is focused is moved to
-- a real editing window instead of taking the panel's place.
--
-- Diffview's file panel is 35 columns wide, so anything that edits a buffer
-- from there (a picker result, a quickfix jump, `:edit`) leaves the file in an
-- unreadable strip with the rest of the layout still around it, and the panel
-- gone. Nothing about the window afterwards says a panel was ever there, so
-- each window records the panel buffer it is showing and the swap is undone
-- once it happens.
--
-- A panel is recognised by what it is rather than by name: a split showing a
-- buffer that is not a file (`nofile`/`nowrite`), which is how plugins build
-- their sidebars and status windows. New plugins are covered without being
-- listed here. Oil (`acwrite`), help, quickfix and terminals are not panels,
-- floats belong to whatever opened them, and diff windows are half of a
-- comparison whose buffers the diff tool swaps itself.

local PANEL_BUFTYPES = { nofile = true, nowrite = true }

-- Non-file buffers whose whole job is to be replaced by the file opened from
-- them.
local REPLACEABLE_FILETYPES = { netrw = true, snacks_dashboard = true }

local function is_normal(win) return vim.api.nvim_win_get_config(win).relative == "" end

local function is_panel(win, buf)
  return PANEL_BUFTYPES[vim.bo[buf].buftype]
    and not REPLACEABLE_FILETYPES[vim.bo[buf].filetype]
    and is_normal(win)
    and not vim.wo[win].diff
end

-- Where a redirected file goes: the roomiest window holding an ordinary
-- buffer.
local function target_window(exclude)
  local best, best_width
  for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
    local buf = vim.api.nvim_win_get_buf(win)
    if
      win ~= exclude
      and is_normal(win)
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
  local target = target_window(win)
  if not target then
    local others = vim.tbl_filter(function(w) return w ~= win and is_normal(w) end, vim.api.nvim_tabpage_list_wins(0))
    -- A panel filling the tab on its own has no better place to send the file.
    if #others == 0 then
      vim.w[win].pinned_panel = nil
      return
    end
    -- The rest of the tab is panels and diff windows (a diffview tab), so the
    -- file gets a tab of its own.
    vim.cmd("tabnew")
    target = vim.api.nvim_get_current_win()
  end

  local cursor = vim.api.nvim_win_get_cursor(win)
  vim.api.nvim_win_set_buf(win, panel)
  vim.api.nvim_win_set_buf(target, buf)
  vim.api.nvim_set_current_win(target)
  pcall(vim.api.nvim_win_set_cursor, target, cursor)
end

-- Decide what the window showing a non-file buffer now is: a panel, or a
-- window that has stopped being one (oil, help, a dashboard took it over).
--
-- Deferred, and only if the buffer is still there: plugins building a layout
-- (diffview among them) fill new windows with a scratch placeholder and swap
-- the real file in straight after, and that placeholder is not a panel.
local function classify(win, buf)
  vim.schedule(function()
    if vim.api.nvim_win_is_valid(win) and vim.api.nvim_win_get_buf(win) == buf then
      vim.w[win].pinned_panel = is_panel(win, buf) and buf or nil
    end
  end)
end

local group = vim.api.nvim_create_augroup("pinned-panels", { clear = true })

vim.api.nvim_create_autocmd("BufWinEnter", {
  group = group,
  callback = function(ev)
    local win = vim.api.nvim_get_current_win()
    if vim.api.nvim_win_get_buf(win) ~= ev.buf then return end

    if vim.bo[ev.buf].buftype ~= "" then
      classify(win, ev.buf)
      return
    end

    local panel = vim.w[win].pinned_panel
    -- An unnamed buffer is usually a plugin about to turn it into its own
    -- scratch buffer, and there is no file to rescue anyway.
    if not panel or panel == ev.buf or vim.api.nvim_buf_get_name(ev.buf) == "" then return end
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
        and not vim.wo[win].diff
      then
        redirect(win, ev.buf, panel)
      end
    end)
  end,
})

-- Plugins often set `buftype` and the filetype after the buffer is already in
-- its window, so the window is classified again once they are known.
vim.api.nvim_create_autocmd("FileType", {
  group = group,
  callback = function(ev)
    local win = vim.api.nvim_get_current_win()
    if vim.api.nvim_win_get_buf(win) == ev.buf and vim.bo[ev.buf].buftype ~= "" then classify(win, ev.buf) end
  end,
})

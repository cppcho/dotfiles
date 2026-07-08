-- Seamless <C-h/j/k/l> between vim splits and multiplexer panes.
--
-- herdr: move between splits ourselves; at an edge hand off to
--        `herdr pane focus`. The herdr side is ~/bin/herdr-navigate, which
--        forwards ctrl+h/j/k/l into vim/fzf panes (the tmux is_vim trick).
-- tmux:  delegate to vim-tmux-navigator's TmuxNavigate* commands, which also
--        handle plain wincmd when outside any multiplexer.

local keys = {
  ["<c-h>"] = { wincmd = "h", dir = "left", tmux = "TmuxNavigateLeft" },
  ["<c-j>"] = { wincmd = "j", dir = "down", tmux = "TmuxNavigateDown" },
  ["<c-k>"] = { wincmd = "k", dir = "up", tmux = "TmuxNavigateUp" },
  ["<c-l>"] = { wincmd = "l", dir = "right", tmux = "TmuxNavigateRight" },
  ["<c-\\>"] = { wincmd = "p", tmux = "TmuxNavigatePrevious" },
}

local function herdr_pane_zoomed()
  local out = vim.system({ "herdr", "pane", "layout", "--pane", vim.env.HERDR_PANE_ID }):wait()
  local ok, decoded = pcall(vim.json.decode, out.stdout or "")
  return ok and decoded.result.layout.zoomed == true
end

local function navigate(lhs)
  local k = keys[lhs]
  -- In an fzf terminal buffer, give the key to fzf (matches the old tnoremap).
  if vim.bo.filetype == "fzf" then
    local raw = vim.api.nvim_replace_termcodes(lhs, true, false, true)
    vim.api.nvim_feedkeys(raw, "n", false)
    return
  end
  if vim.env.HERDR_PANE_ID and vim.env.HERDR_PANE_ID ~= "" then
    local prev = vim.api.nvim_get_current_win()
    vim.cmd("wincmd " .. k.wincmd)
    if vim.api.nvim_get_current_win() ~= prev then
      return
    end
    if not k.dir then
      return -- <c-\>: herdr has no last-pane; stop at vim's previous window
    end
    if herdr_pane_zoomed() then
      return -- ~ tmux_navigator_disable_when_zoomed
    end
    vim.cmd("silent! wall") -- ~ tmux_navigator_save_on_switch = 2
    vim.system({ "herdr", "pane", "focus", "--direction", k.dir, "--pane", vim.env.HERDR_PANE_ID })
  else
    vim.cmd(k.tmux)
  end
end

-- https://github.com/christoomey/vim-tmux-navigator
return {
  "christoomey/vim-tmux-navigator",
  init = function()
    -- We own the key mappings; the plugin only provides TmuxNavigate* commands.
    vim.g.tmux_navigator_no_mappings = 1
    -- Write all buffers before navigating from Vim to tmux pane
    vim.g.tmux_navigator_save_on_switch = 2
    -- Disable tmux navigator when zooming the Vim pane
    vim.g.tmux_navigator_disable_when_zoomed = 1
    -- https://github.com/christoomey/vim-tmux-navigator?tab=readme-ov-file#disable-wrapping
    vim.g.tmux_navigator_no_wrap = 1
  end,
  keys = (function()
    local specs = {}
    for lhs in pairs(keys) do
      specs[#specs + 1] = {
        lhs,
        function()
          navigate(lhs)
        end,
        mode = { "n", "t" },
        silent = true,
      }
    end
    return specs
  end)(),
}

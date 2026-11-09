-- Rex config. Keys follow the Herdr setup (~/.config/herdr/config.toml).
-- The prefix is ctrl+a.
--
-- Layout: one session per repo, one tab per worktree of that repo.
--
-- Rex does not watch this file. Apply changes with `rex config reload`.

-- Prefix: ctrl+a twice sends ctrl+a to the program in the pane.
rex.bind("ctrl+a>ctrl+a", "pane.send_key", { key = "ctrl+a" })

-- Sessions
rex.bind("ctrl+a>w", "session.switch")
rex.bind("ctrl+left", "session.previous")
rex.bind("ctrl+right", "session.next")
rex.bind("ctrl+a>shift+q", "session.close")

-- Tabs
rex.bind("ctrl+a>c", "client.tab.new")
rex.bind("ctrl+[", "client.tab.previous")
rex.bind("ctrl+]", "client.tab.next")
rex.bind("ctrl+a>shift+x", "client.tab.close")
rex.bind("ctrl+a>shift+o", "client.tab.close_others")
for i = 1, 9 do
  rex.bind("ctrl+" .. i, "client.tab.goto", { index = i })
end

-- Panes
rex.bind("ctrl+a>shift+5", "pane.split", { direction = "right" }) -- %
rex.bind("ctrl+a>shift+'", "pane.split", { direction = "down" })  -- "
rex.bind("ctrl+a>x", "pane.close")
rex.bind("ctrl+a>z", "pane.zoom")
rex.bind("ctrl+a>shift+1", "pane.move_to_new_tab") -- !

local terminal = "com.superlogical.terminal"
local home = os.getenv("HOME")

-- Pickers: ~/bin/rex-* scripts run in a floating pane over the current tab.
--
-- The pane starts in the focused pane's directory, so a picker such as
-- rex-worktree-picker knows which repo it is for. It closes when the script
-- exits.
--
-- The script runs through an interactive zsh, so it gets the same environment
-- as a normal terminal. Without ~/.zshrc, the scripts break:
-- - /bin comes before /opt/homebrew/bin on PATH, so `bash` is macOS's bash 3.2,
--   which has no `declare -A`.
-- - TMUX_SESSIONIZER_PATHS is unset, so rex-sessionizer lists only ~/dev. Rex reports the directory as a file:// URL with the host name, such
-- as file://my-mac/Users/me/dev/my%20repo, so it is turned back into a path.
local function focused_dir(block_id)
  if not block_id then
    return ""
  end
  local r = rex.block.call(terminal, "pwd", { block_id = block_id })
  if not r or type(r.pwd) ~= "string" then
    return ""
  end
  local path = r.pwd:gsub("^file://[^/]*", "")
  path = path:gsub("%%(%x%x)", function(hex)
    return string.char(tonumber(hex, 16))
  end)
  return path
end

rex.action({
  name = "float",
  title = "Run in Floating Pane",
  args = { command = "array" },
  run = function(ctx, args)
    local layer, err = rex.session.new_layer({
      session_id = ctx.session_id,
      bounds = { 0.15, 0.15, 0.7, 0.7 },
      focus = true,
      layout = rex.layout.block({
        flavor = "com.superlogical.terminal.shell",
        options = { command = args.command, cwd = focused_dir(ctx.block_id), interactive = true },
      }),
    })
    if err ~= nil then
      error(err, 0)
    end
    -- The new pane's ID, so `rex do float` can read or drive the pane.
    return { block_ids = layer.block_ids }
  end,
})

rex.bind("ctrl+a>f", "float", { command = { home .. "/bin/rex-sessionizer" } })
rex.bind("ctrl+a>g", "float", { command = { home .. "/bin/rex-worktree-picker" } })
rex.bind("ctrl+a>shift+g", "float", { command = { home .. "/bin/rex-gwt" } })

-- Vim-aware pane navigation with ctrl+h/j/k/l.
--
-- The same keys move between nvim splits, so Rex and nvim share them:
-- - When nvim or fzf runs in the focused pane, the function returns false.
--   Rex then sends the key on to the program, and nvim moves between its
--   own splits.
-- - At the edge of its splits, nvim asks Rex to move focus
--   (nvim/.config/nvim/lua/plugins/tmux-navigator.lua).
-- - In any other program, Rex moves focus itself.

-- Process names that get the keys, the same set vim-tmux-navigator uses
-- plus fzf. Examples: nvim, vim, view, gvimdiff, nvim-wrapped, fzf.
local function wants_nav_keys(name)
  if type(name) ~= "string" then
    return false
  end
  name = name:match("[^/]+$") or name
  if name == "fzf" then
    return true
  end
  name = name:gsub("%-wrapped$", ""):gsub("diff$", ""):gsub("^g", ""):gsub("^%.", "")
  return name == "view" or name:match("^l?n?vim?x?$") ~= nil
end

local function navigate(direction)
  return function(ctx, ev)
    if ctx.block_id then
      local p = rex.block.call(terminal, "process", { block_id = ctx.block_id })
      local fg = p and p.foreground
      if fg and (wants_nav_keys(fg.name) or wants_nav_keys(fg.argv0)) then
        return false
      end
    end
    local _, err = rex.session.focus_direction({ session_id = ctx.session_id, direction = direction })
    if err ~= nil then
      rex.log("navigate " .. direction .. ": " .. tostring(err))
    end
    return true
  end
end

rex.bind("ctrl+h", navigate("left"))
rex.bind("ctrl+j", navigate("down"))
rex.bind("ctrl+k", navigate("up"))
rex.bind("ctrl+l", navigate("right"))

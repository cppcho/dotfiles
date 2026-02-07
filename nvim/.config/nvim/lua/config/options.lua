-- Show line numbers
vim.o.number = true

-- Disable mouse mode
vim.o.mouse = ""

-- Don't show the mode, since it's already in the status line
vim.o.showmode = false

-- Sync clipboard between OS and Neovim.
-- Schedule the setting after `UiEnter` because it can increase startup-time.
vim.schedule(function()
  vim.o.clipboard = "unnamedplus"
end)

-- Enable break indent
vim.o.breakindent = true

-- Save undo history
vim.o.undofile = true

-- Case-insensitive searching
vim.o.ignorecase = true

-- Override ignorecase when search pattern contains uppercase letters
vim.o.smartcase = true

-- Always show the sign column to avoid text shifting
vim.o.signcolumn = "yes"

-- Open vertical splits to the right of the current window
vim.o.splitright = true

-- Open horizontal splits above the current window
vim.o.splitbelow = false

-- Disable display of whitespace characters (tabs, trailing spaces, etc.)
vim.o.list = false

-- Show live preview of substitution commands in a split window
vim.o.inccommand = "split"

-- Highlight the line the cursor is on
vim.o.cursorline = true

-- Keep 10 lines visible above and below the cursor when scrolling
vim.o.scrolloff = 8

-- Prompt for confirmation instead of failing on unsaved changes
vim.o.confirm = true

-- Use spaces instead of tabs
vim.o.expandtab = true

-- Number of spaces for each indentation level
vim.o.shiftwidth = 2

-- Number of spaces a tab character displays as
vim.o.tabstop = 2

-- Number of spaces inserted when pressing Tab
vim.o.softtabstop = 2

-- Disable swap file creation
vim.o.swapfile = false

-- Disable backup file before overwriting
vim.o.writebackup = false

-- Automatically save files when switching buffers or running commands
vim.o.autowrite = true

-- Disable line wrapping for long lines
vim.o.wrap = false

-- Allow switching buffers without saving
vim.o.hidden = true

-- Insert one space (not two) after punctuation when joining lines
vim.o.joinspaces = false

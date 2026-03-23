return {
  cmd = { "copilot-language-server", "--stdio" },
  root_markers = { ".git" },
  init_options = {
    copilot = {
      nextEditSuggestions = {
        enabled = true,
      },
    },
  },
}

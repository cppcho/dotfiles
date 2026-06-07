-- Resolve imports from the module cache instead of vendor/ so a stale
-- vendor directory no longer breaks the LSP (no more `go mod vendor` reruns).
-- Actual builds/CI still use vendor mode; this only affects gopls.
return {
  settings = {
    gopls = {
      buildFlags = { "-mod=mod" },
    },
  },
}

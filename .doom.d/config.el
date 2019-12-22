;;; $DOOMDIR/config.el -*- lexical-binding: t; -*-

;; Place your private configuration here! Remember, you do not need to run 'doom
;; refresh' after modifying this file!


;; These are used for a number of things, particularly for GPG configuration,
;; some email clients, file templates and snippets.
(setq user-full-name "Patrick Cho"
      user-mail-address "cppcho.hk@gmail.com")

;; Doom exposes five (optional) variables for controlling fonts in Doom. Here
;; are the three important ones:
;;
;; + `doom-font'
;; + `doom-variable-pitch-font'
;; + `doom-big-font' -- used for `doom-big-font-mode'
;;
;; They all accept either a font-spec, font string ("Input Mono-12"), or xlfd
;; font string. You generally only need these two:
;; test
(setq doom-font (font-spec :family "Fira Code" :size 12))

;; There are two ways to load a theme. Both assume the theme is installed and
;; available. You can either set `doom-theme' or manually load a theme with the
;; `load-theme' function. These are the defaults.
(setq doom-theme 'doom-one)

;; If you want to change the style of line numbers, change this to `relative' or
;; `nil' to disable it:
(setq display-line-numbers-type t)

(setq mac-command-modifier 'super
      mac-option-modifier 'meta)

;; Scroll N lines to screen edge
(setq scroll-margin 4)
;; Scroll back this many lines to being the cursor back on screen
(setq scroll-conservatively scroll-margin)


;; https://github.com/hlissner/doom-emacs/issues/548
(evil-put-command-property 'evil-yank-line :motion 'evil-line)

;; mappings
(map! :leader "SPC" #'execute-extended-command)
(map! :leader "/" #'+default/search-project)
(map! :ne "C-h" #'evil-window-left)
(map! :ne "C-l" #'evil-window-right)
(map! :ne "C-j" #'evil-window-down)
(map! :ne "C-k" #'evil-window-up)
(map! :ne "C-p" #'+ivy/projectile-find-file)
(map! :ge "<mouse-3>" 'clipboard-yank)

;; https://github.com/hlissner/doom-emacs/issues/1839
(after! which-key
  (setq which-key-idle-delay 0.01)
  (which-key-mode +1)
  )


(setq projectile-project-search-path '("~/code/"))

(after! org
  (setq
   org-directory "~/notes/"
   org-capture-templates '(("t" "todo" entry
                            (file+headline "tasks.org" "Inbox")
                            "* TODO %?\n%i\n%a" :prepend t)
                           ("n" "notes" entry
                            (file+headline "notes.org" "Inbox")
                            "* %u %?\n%i\n%a" :prepend t))
   )
  (map! :map org-mode-map
        :n "M-j" #'org-metadown
        :n "M-k" #'org-metaup)
  )

;; Here are some additional functions/macros that could help you configure Doom:
;;
;; - `load!' for loading external *.el files relative to this one
;; - `use-package' for configuring packages
;; - `after!' for running code after a package has loaded
;; - `add-load-path!' for adding directories to the `load-path', where Emacs
;;   looks when you load packages with `require' or `use-package'.
;; - `map!' for binding new keys
;;
;; To get information about any of these functions/macros, move the cursor over
;; the highlighted symbol at press 'K' (non-evil users must press 'C-c g k').
;; This will open documentation for it, including demos of how they are used.
;;
;; You can also try 'gd' (or 'C-c g d') to jump to their definition and see how
;; they are implemented.

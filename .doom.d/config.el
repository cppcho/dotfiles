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

;; https://github.com/hlissner/doom-emacs/issues/1839
(after! which-key
  (setq which-key-idle-delay 0.01)
  (which-key-mode +1)
  )


(setq projectile-project-search-path '("~/code/"))

(after! org
  (setq
   org-directory "~/org/"
   org-default-notes-file "~/org/notes.org"
   org-journal-dir "~/org/journal/"
   org-journal-enable-agenda-integration t
   org-journal-date-format "%Y-%m-%d (%a)"
   org-capture-templates '(("t" "todo" entry
                            (file+headline org-default-notes-file "tasks")
                            "* TODO %?\n%i\n%a" :prepend t))
   org-todo-keywords
   '((sequence
      "TODO(t)"
      "DOING(s)"
      "WAIT(w)"
      "|"
      "DONE(d)"
      "KILL(k)"))
   org-todo-keyword-faces
   '(("TODO" . "light green")
     ("DOING" . "OrangeRed1")
     ("WAIT" . "orange1")
     ("KILL" . "PeachPuff4"))
   )

  (map! :map org-mode-map
        :n "M-j" #'org-metadown
        :n "M-k" #'org-metaup
        :ne "C-j" #'evil-window-down
        :ne "C-k" #'evil-window-up
        :ne "C-h" #'evil-window-left
        :ne "C-l" #'evil-window-right
        :ne "gt" #'org-todo
        :ne "g," #'org-priority
        )
  )

;; mappings
(map! :leader "SPC" #'execute-extended-command)
(map! :leader "/" #'+default/search-project)
(map! :leader "ww" (lambda () (interactive) (find-file "~/org/notes.org")))
(map! :leader "oj" #'org-journal-new-entry)
(map! :leader "oJ" #'org-journal-new-scheduled-entry)
(map! :ne "C-h" #'evil-window-left)
(map! :ne "C-l" #'evil-window-right)
(map! :ne "C-j" #'evil-window-down)
(map! :ne "C-k" #'evil-window-up)
(map! :ne "C-p" #'+ivy/projectile-find-file)
(map! :ne "C-SPC" #'org-capture)
(map! :ge "<mouse-3>" 'clipboard-yank)

(auto-save-visited-mode)

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

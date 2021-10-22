;;; $DOOMDIR/config.el -*- lexical-binding: t; -*-

;; Place your private configuration here! Remember, you do not need to run 'doom
;; sync' after modifying this file!


;; Some functionality uses this to identify you, e.g. GPG configuration, email
;; clients, file templates and snippets.
(setq user-full-name "Patrick Cho"
      user-mail-address "cppcho.hk@gmail.com")

;; Doom exposes five (optional) variables for controlling fonts in Doom. Here
;; are the three important ones:
;;
;; + `doom-font'
;; + `doom-variable-pitch-font'
;; + `doom-big-font' -- used for `doom-big-font-mode'; use this for
;;   presentations or streaming.
;;
;; They all accept either a font-spec, font string ("Input Mono-12"), or xlfd
;; font string. You generally only need these two:
;; (setq doom-font (font-spec :family "monospace" :size 12 :weight 'semi-light)
;;       doom-variable-pitch-font (font-spec :family "sans" :size 13))

;; There are two ways to load a theme. Both assume the theme is installed and
;; available. You can either set `doom-theme' or manually load a theme with the
;; `load-theme' function. This is the default:
(setq doom-theme 'doom-one)

;; This determines the style of line numbers in effect. If set to `nil', line
;; numbers are disabled. For relative line numbers, set this to `relative'.
(setq display-line-numbers-type t)


;; Here are some additional functions/macros that could help you configure Doom:
;;
;; - `load!' for loading external *.el files relative to this one
;; - `use-package!' for configuring packages
;; - `after!' for running code after a package has loaded
;; - `add-load-path!' for adding directories to the `load-path', relative to
;;   this file. Emacs searches the `load-path' when you load packages with
;;   `require' or `use-package'.
;; - `map!' for binding new keys
;;
;; To get information about any of these functions/macros, move the cursor over
;; the highlighted symbol at press 'K' (non-evil users must press 'C-c c k').
;; This will open documentation for it, including demos of how they are used.
;;
;; You can also try 'gd' (or 'C-c c d') to jump to their definition and see how
;; they are implemented.


(setq! evil-want-Y-yank-to-eol nil)
(setq doom-localleader-key ",")
;; (setq scroll-margin 4)
;; (setq scroll-conservatively scroll-margin)

;; https://github.com/hlissner/doom-emacs/issues/1839
(require 'which-key)
(setq which-key-idle-delay 0.01)

(map! :leader "SPC" #'execute-extended-command)
(map! :neg "C-h" #'evil-window-left)
(map! :neg "C-j" #'evil-window-down)
(map! :neg "C-k" #'evil-window-up)
(map! :neg "C-l" #'evil-window-right)

;; org config
;; must be set before org load
(setq org-directory "~/org/")

(after! org

  (setq
   org-default-notes-file "notes.org"
   org-archive-location "::* Archive"

   org-todo-keywords
   '((sequence
      "TODO(t)"  ; A task that needs doing & is ready to do
      "PROJ(p)"  ; A project, which usually contains other tasks
      "STRT(s)"  ; A task that is in progress
      "WAIT(w)"  ; Something external is holding up this task
      "|"
      "DONE(d)"  ; Task successfully completed
      "KILL(k)") ; Task was cancelled, aborted or is no longer applicable
     )

   org-todo-keyword-faces
   '(
     ("STRT" . +org-todo-active)
     ("WAIT" . +org-todo-onhold)
     ("PROJ" . +org-todo-project)
     ("KILL" . +org-todo-cancel)
     )

   org-capture-templates
   '(
     ("t" "todo" entry
      (file+headline org-default-notes-file "Inbox")
      "* TODO %?\n%i" :prepend t)
     )
   )

  )

(define-key key-translation-map (kbd "ESC") (kbd "C-g"))
(map! :leader "k" (lambda () (interactive) (org-capture nil "t")))
(map! :leader "ww" (lambda () (interactive) (find-file "~/org/notes.org")))
(map! :neg "C-f" #'org-agenda)
(map! :map org-mode-map
      :n "ta" (lambda () (interactive) (org-priority ?A))
      :n "tb" (lambda () (interactive) (org-priority ?B))
      :n "tc" (lambda () (interactive) (org-priority ?C))
      :n "tt" (lambda () (interactive) (org-todo "TODO"))
      :n "tp" (lambda () (interactive) (org-todo "PROJ"))
      :n "ts" (lambda () (interactive) (org-todo "STRT"))
      :n "tw" (lambda () (interactive) (org-todo "WAIT"))
      :n "td" (lambda () (interactive) (org-todo "DONE"))
      :n "tk" (lambda () (interactive) (org-todo "KILL"))
      :n "t SPC" (lambda () (interactive) (org-priority 'remove))
      :n "tr" #'+org/refile-to-current-file
      :n "C-c TAB" #'org-force-cycle-archived
      )

(setq org-log-done 'time)
(setq undo-no-redo t)

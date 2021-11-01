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

   org-capture-templates
   '(
     ("t" "todo" entry
      (file+headline org-default-notes-file "Inbox")
      "* TODO %?\n%i" :prepend t)
     )

   org-priority-faces
   '((?A . error)
     (?B . warning)
     (?C . font-lock-doc-face)
     )

   org-agenda-custom-commands
   '(("w" "Work"
      ((agenda "" ((org-agenda-span 7)))
       (tags-todo "+work+TODO={TODO\\|STRT}")
       (tags-todo "+work+TODO={PROJ}")
       (tags-todo "+work+TODO={WAIT}")
       (tags-todo "+inbox"))
      ((org-agenda-hide-tags-regexp "inbox\\|work")
       (org-agenda-start-on-weekday 1)
       (org-agenda-sorting-strategy '(priority-down))
       (org-agenda-tags-column 0))
      )
     ("p" "Personal"
      ((agenda "" ((org-agenda-span 7)))
       (tags-todo "+personal+TODO={TODO\\|STRT}")
       (tags-todo "+personal+TODO={PROJ}")
       (tags-todo "+personal+TODO={WAIT}")
       (tags-todo "+inbox"))
      ((org-agenda-hide-tags-regexp "inbox\\|personal")
       (org-agenda-start-on-weekday 1)
       (org-agenda-sorting-strategy '(priority-down))
       (org-agenda-tags-column 0))
      )
     ("d" "Completed"
      ((todo "DONE|KILL"))
      ((org-agenda-hide-tags-regexp "ARCHIVE")
       (org-agenda-archives-mode 'trees)
       ;; (org-agenda-sorting-strategy '(tsia-up))
       (org-agenda-tags-column 0))
      ))
   )

  (map! :map org-mode-map
        :n "ga" (lambda () (interactive) (org-priority ?A))
        :n "gb" (lambda () (interactive) (org-priority ?B))
        :n "gc" (lambda () (interactive) (org-priority ?C))
        :n "tt" (lambda () (interactive) (org-todo "TODO"))
        :n "tp" (lambda () (interactive) (org-todo "PROJ"))
        :n "ts" (lambda () (interactive) (org-todo "STRT"))
        :n "tw" (lambda () (interactive) (org-todo "WAIT"))
        :n "td" (lambda () (interactive) (org-todo "DONE"))
        :n "tk" (lambda () (interactive) (org-todo "KILL"))
        :n "t SPC" (lambda () (interactive) (org-priority 'remove))
        :n "gr" #'+org/refile-to-current-file
        :n "C-c TAB" #'org-force-cycle-archived
        )
  (map! :leader "ww" (lambda () (interactive) (find-file "~/org/notes.org")))
  (map! :leader "k" (lambda () (interactive) (org-capture nil "t")))
  (map! :n "C-SPC" (lambda () (interactive) (org-capture nil "t")))
  (map! :n "C-f" #'org-agenda)
  )

(define-key key-translation-map (kbd "ESC") (kbd "C-g"))
(map! :leader "SPC" #'execute-extended-command)
(map! :n "C-h" #'evil-window-left)
(map! :n "C-j" #'evil-window-down)
(map! :n "C-k" #'evil-window-up)
(map! :n "C-l" #'evil-window-right)

(run-with-idle-timer 30 t #'save-some-buffers t)


(map! :after evil-org-agenda
      :map evil-org-agenda-mode-map
      :m "C-SPC" (lambda () (interactive) (org-capture nil "t"))
      :m "C-h" #'evil-window-left
      :m "C-j" #'evil-window-down
      :m "C-k" #'evil-window-up
      :m "C-l" #'evil-window-right
      ;; "ga" (lambda () (interactive) (org-priority ?A))
      ;; "gb" (lambda () (interactive) (org-priority ?B))
      ;; "gc" (lambda () (interactive) (org-priority ?C))
      ;; "gr" #'+org/refile-to-current-file
      )

(setq org-log-done 'time)
(setq undo-no-redo t)

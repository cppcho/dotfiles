;;; $DOOMDIR/config.el -*- lexical-binding: t; -*-

;; Place your private configuration here! Remember, you do not need to run 'doom
;; sync' after modifying this file!


;; Some functionality uses this to identify you, e.g. GPG configuration, email
;; clients, file templates and snippets.
(setq user-full-name "Patrick Cho"
      user-mail-address "cppcho.hk@gmail.com")

;; Doom exposes five (optional) variables for controlling fonts in Doom:
;;
;; - `doom-font' -- the primary font to use
;; - `doom-variable-pitch-font' -- a non-monospace font (where applicable)
;; - `doom-big-font' -- used for `doom-big-font-mode'; use this for
;;   presentations or streaming.
;; - `doom-unicode-font' -- for unicode glyphs
;; - `doom-serif-font' -- for the `fixed-pitch-serif' face
;;
;; See 'C-h v doom-font' for documentation and more examples of what they
;; accept. For example:
;;
;;(setq doom-font (font-spec :family "Fira Code" :size 12 :weight 'semi-light)
;;      doom-variable-pitch-font (font-spec :family "Fira Sans" :size 13))
;;
;; If you or Emacs can't find your font, use 'M-x describe-font' to look them
;; up, `M-x eval-region' to execute elisp code, and 'M-x doom/reload-font' to
;; refresh your font settings. If Emacs still can't find your font, it likely
;; wasn't installed correctly. Font issues are rarely Doom issues!

;; There are two ways to load a theme. Both assume the theme is installed and
;; available. You can either set `doom-theme' or manually load a theme with the
;; `load-theme' function. This is the default:
(setq doom-theme 'doom-one)

;; This determines the style of line numbers in effect. If set to `nil', line
;; numbers are disabled. For relative line numbers, set this to `relative'.
(setq display-line-numbers-type t)

;; If you use `org' and don't want your org files in the default location below,
;; change `org-directory'. It must be set before org loads!
(setq org-directory "~/org/")


;; Whenever you reconfigure a package, make sure to wrap your config in an
;; `after!' block, otherwise Doom's defaults may override your settings. E.g.
;;
;;   (after! PACKAGE
;;     (setq x y))
;;
;; The exceptions to this rule:
;;
;;   - Setting file/directory variables (like `org-directory')
;;   - Setting variables which explicitly tell you to set them before their
;;     package is loaded (see 'C-h v VARIABLE' to look up their documentation).
;;   - Setting doom variables (which start with 'doom-' or '+').
;;
;; Here are some additional functions/macros that will help you configure Doom.
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
;; Alternatively, use `C-h o' to look up a symbol (functions, variables, faces,
;; etc).
;;
;; You can also try 'gd' (or 'C-c c d') to jump to their definition and see how
;; they are implemented.


(setq! evil-want-Y-yank-to-eol nil)
(setq doom-localleader-key ",")

;; https://github.com/hlissner/doom-emacs/issues/1839
(require 'which-key)
(setq which-key-idle-delay 0.01)

(after! org

  (setq
   org-default-notes-file "personal.org"

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

   org-priority-faces
   '((?A . (:foreground "orange red"))
     (?B . (:foreground "light salmon"))
     (?C . (:foreground "light slate gray")))

   org-deadline-warning-days 1
   org-agenda-show-future-repeats nil
   org-agenda-todo-ignore-scheduled 'future
   org-agenda-tags-todo-honor-ignore-options t

   org-agenda-custom-commands
   '(("0" "Work"
      ((agenda "" ((org-agenda-span 10)))
       (tags-todo "+TODO={STRT}")
       (tags-todo "+TODO={TODO}")
       (tags-todo "+TODO={WAIT}")
       )
      ((org-agenda-hide-tags-regexp "work")
       (org-agenda-tag-filter-preset '("+work"))
       (org-agenda-sorting-strategy '(priority-down)))
      )
     ("9" "Personal"
      ((agenda "" ((org-agenda-span 10)))
       (tags-todo "+TODO={STRT}")
       (tags-todo "+TODO={TODO}")
       (tags-todo "+TODO={WAIT}")
       )
      ((org-agenda-hide-tags-regexp "personal")
       (org-agenda-tag-filter-preset '("+personal"))
       (org-agenda-sorting-strategy '(priority-down)))
      ))

   org-capture-templates
   '(("0" "Work todo"
      entry (file+headline "~/org/work.org" "Inbox") "* TODO %?" :prepend t)
     ("9" "Personal todo"
      entry (file+headline "~/org/personal.org" "Inbox") "* TODO %?" :prepend t))
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
        :n "gk" (lambda () (interactive) (org-priority 'remove))
        :nv "gr" #'+org/refile-to-current-file
        :n "C-c TAB" #'org-force-cycle-archived
        )
  )

(define-key key-translation-map (kbd "ESC") (kbd "C-g"))
(map! :leader "SPC" #'execute-extended-command)
(map! :n "C-f" #'org-agenda)
(map! :n "C-h" #'evil-window-left)
(map! :n "C-j" #'evil-window-down)
(map! :n "C-k" #'evil-window-up)
(map! :n "C-l" #'evil-window-right)
(map! :n "C-0" (lambda () (interactive) (find-file "~/org/work.org")))
(map! :n "C-9" (lambda () (interactive) (find-file "~/org/personal.org")))
(map! :n "C-c 9" (lambda () (interactive) (org-capture nil "9")))
(map! :n "C-c C-9" (lambda () (interactive) (org-capture nil "9")))
(map! :n "C-c 0" (lambda () (interactive) (org-capture nil "0")))
(map! :n "C-c C-0" (lambda () (interactive) (org-capture nil "0")))
(map! :n "SPC 9" (lambda () (interactive) (org-agenda nil "9")))
(map! :n "SPC 0" (lambda () (interactive) (org-agenda nil "0")))
(map! :n "u" #'undo-fu-only-undo)
(map! :n "\C-r" #'undo-fu-only-redo)

(run-with-idle-timer 10 t #'save-some-buffers t)

(map! :after evil-org-agenda
      :map evil-org-agenda-mode-map
      :m "C-c 9" (lambda () (interactive) (org-capture nil "9"))
      :m "C-c C-9" (lambda () (interactive) (org-capture nil "9"))
      :m "C-c 0" (lambda () (interactive) (org-capture nil "0"))
      :m "C-c C-0" (lambda () (interactive) (org-capture nil "0"))
      :m "SPC 9" (lambda () (interactive) (org-agenda nil "9"))
      :m "SPC 0" (lambda () (interactive) (org-agenda nil "0"))
      :m "C-h" #'evil-window-left
      :m "C-j" #'evil-window-down
      :m "C-k" #'evil-window-up
      :m "C-l" #'evil-window-right
      :m "C-f" #'org-agenda
      :m "C-0" (lambda () (interactive) (find-file "~/org/work.org"))
      :m "C-9" (lambda () (interactive) (find-file "~/org/personal.org"))
      :m "ga" (lambda () (interactive) (org-agenda-priority ?A))
      :m "gb" (lambda () (interactive) (org-agenda-priority ?B))
      :m "gc" (lambda () (interactive) (org-agenda-priority ?C))
      :m "gr" #'org-agenda-refile
      )

(setq org-log-done 'time)
(setq undo-no-redo t)
(setq confirm-kill-emacs nil)
(setq undo-fu-ignore-keyboard-quit t)
(setq org-archive-location "::* Archive")

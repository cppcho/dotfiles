;; Reference:
;; https://github.com/ideasman42/emacs-for-vimmers/blob/master/.emacs.d/init.el

;; disable gui elements
(tool-bar-mode -1)
(menu-bar-mode -1)
(scroll-bar-mode -1)

;; disable startup message
(defun display-startup-echo-area-message () (message ""))

;; disable "Symbolic link to Git-controlled source file" warnings
(setq vc-follow-symlinks t)

;; window title: buffer name + modified status
;; https://www.gnu.org/software/emacs/manual/html_node/elisp/Frame-Titles.html
(setq-default frame-title-format "%b %& emacs")

;; use UTF-8 everywhere
(prefer-coding-system 'utf-8)
(set-default-coding-systems 'utf-8)
(set-terminal-coding-system 'utf-8)
(set-keyboard-coding-system 'utf-8)
(setq default-buffer-file-coding-system 'utf-8)

;; use text mode prompt instead of dialog box
;; https://www.gnu.org/software/emacs/manual/html_node/emacs/Dialog-Boxes.html
(setq use-dialog-box nil)

;; use y or n in text mode prompt
(defalias 'yes-or-no-p 'y-or-n-p)

;; save minibuffer histories
;; https://www.emacswiki.org/emacs/SaveHist
(savehist-mode 1)
(setq savehist-additional-variables '(register-alist))

;; don't backup anything
(setq backup-inhibited t)
(setq auto-save-default nil)

;; Show empty lines. Why?
;; .. without this you can't tell if there are blank lines at the end of the file.
(setq-default indicate-empty-lines t)

;; keep cursors and highlights in current window only
(setq cursor-in-non-selected-windows nil)
(setq highlight-nonselected-windows nil)

;; disable bidirectional text support for slightly performance improvement
;; https://www.gnu.org/software/emacs/manual/html_node/elisp/Bidirectional-Display.html
(setq bidi-display-reordering nil)

;; no startup screen
(setq inhibit-startup-screen t)

;; don't show buffer list on startup
(setq inhibit-startup-buffer-menu t)

;; hide cursor while typing
(setq make-pointer-invisible t)

;; fully redraw the display before it processes queued input events, for slight performance increase
(setq redisplay-dont-pause t)

;; Scroll N lines to screen edge
(setq scroll-margin 3)
;; Scroll back this many lines to being the cursor back on screen
(setq scroll-conservatively scroll-margin)

;; keyboard scroll one line at a time
(setq scroll-step 1)
;; mouse scroll N lines
(setq mouse-wheel-scroll-amount '(6 ((shift) . 1)))
;; don't accelerate scrolling
(setq mouse-wheel-progressive-speed nil)
;; don't use timer when scrolling
(setq mouse-wheel-inhibit-click-time nil)

;; preserve line/column (nicer page up/down)
(setq scroll-preserve-screen-position t)
;; Move the cursor to top/bottom even if the screen is viewing top/bottom (for page up/down). Why?
;; .. so pressing page/up down can move the cursor & the view to start/end of the buffer.
(setq scroll-error-top-bottom t)

;; Center after going to the next compiler error. Why?
;; .. don't get stuck at screen edges.
(setq next-error-recenter (quote (4)))

;; Always redraw immediately when scrolling. Why?
;; .. more responsive and doesn't hang.
(setq fast-but-imprecise-scrolling nil)
(setq jit-lock-defer-time 0)

;; cutting & pasting use the system clipboard
(setq select-enable-clipboard t)

;; treat clipboard input as UTF-8 string first; compound text next, etc.
(setq x-select-request-type '(UTF8_STRING COMPOUND_TEXT TEXT STRING))

;; paste at text-cursor instead of mouse-cursor location (middle mouse to paste)
(setq mouse-yank-at-point t)

;; don't group undo steps
(fset 'undo-auto-amalgamate 'ignore)

;; Increase undo limits. Why?
;; Being able to go very far back in history can be useful at times.
;; Limit of 64mb.
(setq undo-limit 6710886400)
;; Strong limit of 1.5x (96mb)
(setq undo-strong-limit 100663296)
;; Outer limit of 10x (960mb).
;; Note that the default is x100), but this seems too high.
(setq undo-outer-limit 1006632960)

;; indentation
(setq default-tab-width 4)
(setq tab-width 4)
(setq default-fill-column 80)
(setq fill-column 80)
(setq-default evil-indent-convert-tabs nil)
(setq-default indent-tabs-mode nil)
(setq-default tab-width 4)
(setq-default evil-shift-round nil)

;; show line number
(global-display-line-numbers-mode 1)

;; show line number and column number at point
(setq column-number-mode t)

;; show matching paratheses
;; https://www.gnu.org/software/emacs/manual/html_node/emacs/Matching.html
(show-paren-mode 1)
(setq blink-matching-paren nil)
(setq show-paren-delay 0.2)
(setq show-paren-highlight-openparen t)
(setq show-paren-when-point-inside-paren t)

;; disable word wrap
(set-default 'truncate-lines t)

;; ----------------------------------------------------------------------------
;; Packages
;; ----------------------------------------------------------------------------

;; https://melpa.org/#/getting-started
(require 'package)
(let* ((no-ssl (and (memq system-type '(windows-nt ms-dos))
                    (not (gnutls-available-p))))
       (proto (if no-ssl "http" "https")))
  (when no-ssl
    (warn "\
Your version of Emacs does not support SSL connections,
which is unsafe because it allows man-in-the-middle attacks.
There are two things you can do about this warning:
1. Install an Emacs version that does support SSL and be safe.
2. Remove this warning from your init file so you won't see it again."))
  ;; Comment/uncomment these two lines to enable/disable MELPA and MELPA Stable as desired
  (add-to-list 'package-archives (cons "melpa" (concat proto "://melpa.org/packages/")) t)
  ;;(add-to-list 'package-archives (cons "melpa-stable" (concat proto "://stable.melpa.org/packages/")) t)
  (when (< emacs-major-version 24)
    ;; For important compatibility libraries like cl-lib
    (add-to-list 'package-archives (cons "gnu" (concat proto "://elpa.gnu.org/packages/")))))
(package-initialize)

;; auto-install use-package
;; https://github.com/jwiegley/use-package
(unless (package-installed-p 'use-package)
  (package-refresh-contents)
  (package-install 'use-package))

;; This is only needed once, near the top of the file
(eval-when-compile (require 'use-package))

;; download automatically
(setq use-package-always-ensure t)
;; defer loading packages by default
(setq use-package-always-defer t)

;; theme
;; https://github.com/cpaulik/emacs-material-theme/
(use-package material-theme
             :demand t
             :config (load-theme 'material t))

;; evil leader key support
;; https://github.com/cofi/evil-leader
(use-package evil-leader
             :demand t
             :config
             (global-evil-leader-mode)
             (evil-leader/set-leader "<SPC>")

             (evil-leader/set-key "<SPC>" 'execute-extended-command)
             (evil-leader/set-key "rc" (lambda() (interactive)(find-file "~/.emacs.d/init.el")))
             (evil-leader/set-key "rr" 'eval-buffer)

             (evil-leader/set-key "ww" (lambda() (interactive)(find-file "~/Documents/org/index.org")))

             (evil-leader/set-key "h?" 'help-for-help)
             (evil-leader/set-key "hP" 'describe-package)
             (evil-leader/set-key "hb" 'describe-bindings)
             (evil-leader/set-key "hf" 'describe-function)
             (evil-leader/set-key "hk" 'describe-key)
             (evil-leader/set-key "ho" 'describe-symbol)
             (evil-leader/set-key "hv" 'describe-variable)
             (evil-leader/set-key "hw" 'where-is)

             (evil-leader/set-key "<escape>" 'keyboard-escape-quit)

             ;; TODO:
             ;; Interactive file name search.
             (evil-leader/set-key "k" 'find-file-in-project)
             ;; Interactive file content search (git).
             (evil-leader/set-key "f" 'counsel-git-grep)
             ;; Interactive current-file search.
             (evil-leader/set-key "ss" 'swiper)
             ;; Interactive open-buffer switch.
             (evil-leader/set-key ";" 'counsel-switch-buffer))


;; Main Vim emulation package. Why?
;; .. without this, you won't have Vim key bindings or modes.
(use-package evil
  :after (evil-leader)
  :demand t
  :config
  ;; unbind tab
  ;; https://emacs.stackexchange.com/questions/23909/tab-always-indent-even-in-evil-normal-mode
  ;;(setq evil-want-C-i-jump nil)

  ;; Initialize.
  (evil-mode)

  ;;(define-key evil-insert-state-map (kbd "TAB") 'tab-to-tab-stop)
  ;; For some reasons evils own search isn't default.
  (setq evil-search-module 'evil-search))

;; https://github.com/emacs-evil/evil-surround
(use-package evil-surround
             :demand t
             :config
             ;; Initialize.
             (global-evil-surround-mode 1))

;; https://github.com/justbur/emacs-which-key
(use-package which-key
             :demand t
             :config
             ;; Initialize.
             ;; make sure which-key doesn't show normally but refreshes quickly after it is
             ;; triggered.
             (setq which-key-idle-delay 0.05)
             (setq which-key-idle-secondary-delay 0.05)
             (which-key-mode))

;; Ivy completion. Why?
;; .. makes compleating various prompts for input much more friendly & interactive.
(use-package ivy
  :demand t
  :config
  (ivy-mode)

  ;; Always show half the window height. Why?
  ;; Useful when searching through large lists of content.
  (setq ivy-height-alist `((t . ,(lambda (caller) (/ (frame-height) 2)))))
  (setq ivy-display-style 'fancy)

  ;; Vim style keys in ivy (holding Ctrl).
  (define-key ivy-minibuffer-map (kbd "C-j") 'next-line)
  (define-key ivy-minibuffer-map (kbd "C-k") 'previous-line)
  (define-key ivy-switch-buffer-map (kbd "C-k") 'previous-line)
  (define-key ivy-switch-buffer-map (kbd "C-d") 'ivy-switch-buffer-kill)

  (define-key ivy-minibuffer-map (kbd "C-h") 'minibuffer-keyboard-quit)
  (define-key ivy-minibuffer-map (kbd "C-l") 'ivy-done)

  ;; open and next
  (define-key ivy-minibuffer-map (kbd "C-M-j") 'ivy-next-line-and-call)
  (define-key ivy-minibuffer-map (kbd "C-M-k") 'ivy-previous-line-and-call)

  (define-key ivy-minibuffer-map (kbd "<C-return>") 'ivy-done)

  ;; so we can switch away
  (define-key ivy-minibuffer-map (kbd "C-w") 'evil-window-map))

;; Use for auto-complete. Why?
;; .. saves typing.
(use-package company
  :commands (company-complete-common company-dabbrev)
  :config
  (global-company-mode)

  ;; Increase maximum number of items to show in auto-completion. Why?
  ;; Seeing more at once gives you a better overview of you'r options.
  (setq company-tooltip-limit 40)

  ;; Don't make abbreviations lowercase or ignore case. Why?
  ;; Many languages are case sensitive, so changing case isn't helpful.
  (setq company-dabbrev-downcase nil)
  (setq company-dabbrev-ignore-case nil)

  ;; Keymap: hold Ctrl for Vim motion. Why?
  ;; .. we're already holding Ctrl, allow navigation at the same time.
  (define-key company-active-map (kbd "C-j") 'company-select-next-or-abort)
  (define-key company-active-map (kbd "C-k") 'company-select-previous-or-abort)
  (define-key company-active-map (kbd "C-l") 'company-complete-selection)
  (define-key company-active-map (kbd "C-h") 'company-abort)
  (define-key company-active-map (kbd "<C-return>") 'company-complete-selection)

  (define-key company-search-map (kbd "C-j") 'company-select-next)
  (define-key company-search-map (kbd "C-k") 'company-select-previous))

;; https://github.com/abo-abo/swiper
(use-package swiper
  :commands (swiper)
  :config

  ;; go to the start of the match instead of the end
  (setq swiper-goto-start-of-match t))

;; Use counsel for project wide searches. Why?
;; .. interactive project wide search is incredibly useful.
(use-package counsel
  :commands (counsel-git-grep counsel-switch-buffer))

;; https://github.com/technomancy/find-file-in-project
(use-package find-file-in-project
  :commands (find-file-in-project))

;; https://github.com/syohex/emacs-git-gutter
;; Use git-gutter. Why?
;; .. shows lines you have modified from the last commit.
(use-package git-gutter
  :demand t
  :config (global-git-gutter-mode t))

(use-package org
  :demand t
  :config

  )

;; ----------------------------------------------------------------------------
;; Key Bindings
;; ----------------------------------------------------------------------------

;; https://stackoverflow.com/questions/648817/how-to-bind-esc-to-keyboard-escape-quit-in-emacs
(global-set-key (kbd "<escape>") 'keyboard-escape-quit)

;; ----------------------------------------------------------------------------
;; Mode Settings
;; ----------------------------------------------------------------------------

(add-hook 'org-mode-hook
  (lambda ()
    (setq-local fill-column 120)
    (setq-local tab-width 2)

    (setq-local evil-shift-width 2)
    (setq-local indent-tabs-mode nil)

    (setq-local ffip-patterns '("*.org"))))

(add-hook 'emacs-lisp-mode-hook
  (lambda ()
    (setq-local fill-column 120)
    (setq-local tab-width 2)
    (setq-local evil-shift-width 2)
    (setq-local indent-tabs-mode nil)

    (setq-local ffip-patterns '("*.el"))

    ;; don't delimit on dashes or underscores
    ;; .. makes seaching for variable names inconvenient
    (modify-syntax-entry ?- "w")
    (modify-syntax-entry ?_ "w")))


;; ----------------------------------------------------------------------------
;; Custom Variables
;; ----------------------------------------------------------------------------

;; Store custom variables in an external file
;; .. it means this file can be kept in version control without noise from custom variables.

(setq custom-file "~/.emacs.d/custom.el")
(load custom-file 'noerror)

(setq initial-buffer-choice "~/Documents/org/index.org")
(global-set-key (kbd "C-s") (lambda () (interactive) (save-buffer)))

(setq org-directory "~/Documents/org/index.org")
(setq org-journal-dir (concat org-directory "/journal/"))
(setq org-agenda-files (list org-directory org-journal-dir))
(setq org-default-notes-file (concat org-directory "/index.org"))
(setq org-journal-file-format "%Y-%m-%d")
(setq org-journal-date-format "%Y-%m-%d (%A)")
(setq org-journal-find-file 'find-file) ;; open journal in the current window
(setq org-adapt-indentation nil) ;; no indent for org mode content
(setq org-journal-hide-entries-p nil) ;; do not hide journal entry when creating a new one
(setq org-agenda-window-setup 'only-window) 
(setq org-capture-templates
      '(("t" "Task" entry (file+headline org-default-notes-file "Inbox") "* TODO %?\n%T\n")
        ("n" "Note" entry (file+headline org-default-notes-file "Inbox") "* NOTE %?\n%T\n")))

(define-key evil-normal-state-map (kbd "C-t")
  (lambda () (interactive) (org-capture nil "t")))
(define-key evil-normal-state-map (kbd "C-n")
  (lambda () (interactive) (org-capture nil "n")))

(add-hook 'org-insert-heading-hook 'evil-insert-state)
(add-hook 'org-capture-mode-hook 'evil-insert-state)
(add-hook 'org-journal-mode-hook 'evil-insert-state)
(add-hook 'org-journal-after-entry-create-hook 'evil-insert-state)

;; do no open a new window when following an org link
(setq org-link-frame-setup '((vm . vm-visit-folder)
                             (vm-imap . vm-visit-imap-folder)
                             (gnus . gnus)
                             (file . find-file)
                             (wl . wl)))

(defun cppcho/org-mode-hook ()
  "Set all org-level headers to same font size"
  (dolist (face '(org-level-1
                  org-level-2
                  org-level-3
                  org-level-4
                  org-level-5
                  org-level-6
                  org-level-7
                  org-level-8))
    (set-face-attribute face nil :weight 'semi-bold :height 1.0)))
(add-hook 'org-mode-hook 'cppcho/org-mode-hook)

(define-key evil-normal-state-map (kbd "j") 'evil-next-visual-line)
(define-key evil-normal-state-map (kbd "k") 'evil-previous-visual-line)

(evil-define-key 'normal org-journal-mode-map
  (kbd "<C-left>") 'org-journal-open-previous-entry
  (kbd "<C-right>") 'org-journal-open-next-entry)

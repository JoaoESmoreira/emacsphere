(add-to-list 'load-path "~/.emacs.d/scripts/")

(require 'buffer-move)   ;; Buffer-move for better window management
(require 'manual)

(defvar elpaca-installer-version 0.10)
  (defvar elpaca-directory (expand-file-name "elpaca/" user-emacs-directory))
  (defvar elpaca-builds-directory (expand-file-name "builds/" elpaca-directory))
  (defvar elpaca-repos-directory (expand-file-name "repos/" elpaca-directory))
  (defvar elpaca-order '(elpaca :repo "https://github.com/progfolio/elpaca.git"
                                :ref nil :depth 1 :inherit ignore
                                :files (:defaults "elpaca-test.el" (:exclude "extensions"))
                                :build (:not elpaca--activate-package)))
  (let* ((repo  (expand-file-name "elpaca/" elpaca-repos-directory))
         (build (expand-file-name "elpaca/" elpaca-builds-directory))
         (order (cdr elpaca-order))
         (default-directory repo))
    (add-to-list 'load-path (if (file-exists-p build) build repo))
    (unless (file-exists-p repo)
      (make-directory repo t)
      (when (<= emacs-major-version 28) (require 'subr-x))
      (condition-case-unless-debug err
          (if-let* ((buffer (pop-to-buffer-same-window "*elpaca-bootstrap*"))
                    ((zerop (apply #'call-process `("git" nil ,buffer t "clone"
                                                    ,@(when-let* ((depth (plist-get order :depth)))
                                                        (list (format "--depth=%d" depth) "--no-single-branch"))
                                                    ,(plist-get order :repo) ,repo))))
                    ((zerop (call-process "git" nil buffer t "checkout"
                                          (or (plist-get order :ref) "--"))))
                    (emacs (concat invocation-directory invocation-name))
                    ((zerop (call-process emacs nil buffer nil "-Q" "-L" "." "--batch"
                                          "--eval" "(byte-recompile-directory \".\" 0 'force)")))
                    ((require 'elpaca))
                    ((elpaca-generate-autoloads "elpaca" repo)))
              (progn (message "%s" (buffer-string)) (kill-buffer buffer))
            (error "%s" (with-current-buffer buffer (buffer-string))))
        ((error) (warn "%s" err) (delete-directory repo 'recursive))))
    (unless (require 'elpaca-autoloads nil t)
      (require 'elpaca)
      (elpaca-generate-autoloads "elpaca" repo)
      (load "./elpaca-autoloads")))
  (add-hook 'after-init-hook #'elpaca-process-queues)
  (elpaca `(,@elpaca-order))
;; Install a package via the elpaca macro
;; See the "recipes" section of the manual for more details.

;; (elpaca example-package)

;; Install use-package support
(elpaca elpaca-use-package
  ;; Enable use-package :ensure support for Elpaca.
	(elpaca-use-package-mode))

;;When installing a package used in the init file itself,
;;e.g. a package which adds a use-package key word,
;;use the :wait recipe keyword to block until that package is installed/configured.
;;For example:
;;(use-package general :ensure (:wait t) :demand t)

;; Expands to: (elpaca evil (use-package evil :demand t))
;; (use-package evil :ensure t :demand t)


;;Turns off elpaca-use-package-mode current declaration
;;Note this will cause evaluate the declaration immediately. It is not deferred.
;;Useful for configuring built-in emacs features.
(use-package emacs :ensure nil :config (setq ring-bell-function #'ignore))

(use-package evil
:ensure t
:init
    (setq evil-want-integration t)
    (setq evil-want-keybinding nil)
    (setq evil-vsplit-window-right t)
    (setq evil-split-window-below t)
    (setq evil-want-C-u-scroll t)
    :config
        (evil-mode 1))

(use-package evil-collection
    :ensure t
    :after evil
    :config
        ;; (setq evil-collection-mode-list '(dashboard dired ibuffer))
        (add-to-list 'evil-collection-mode-list 'help) ;; evilify help mode
        (evil-collection-init))

(use-package evil-tutor
    :ensure t)

;; Using RETURN to follow links in Org/Evil 
;; Unmap keys in 'evil-maps if not done, (setq org-return-follows-link t) will not work
(with-eval-after-load 'evil-maps
  (define-key evil-motion-state-map (kbd "SPC") nil)
  (define-key evil-motion-state-map (kbd "RET") nil)
  (define-key evil-motion-state-map (kbd "TAB") nil))

;; Setting RETURN key in org-mode to follow links
(setq org-return-follows-link  t)

(use-package evil-nerd-commenter
    :ensure t
    :defer t)

;; elfeed binds configuration
(with-eval-after-load 'elfeed
  (evil-define-key 'normal elfeed-search-mode-map
    (kbd "o") 'elfeed-search-browse-url   ;; Open the news on browser
    ;; (kbd "RET") 'elfeed-search-show-entry ;; Open the news on browser Emacs
    (kbd "g") 'elfeed-update              ;; Update the feeds
    ;; (kbd "q") 'quit-window)               ;; Quit of Elfeed
    )
  )

(setq make-backup-files nil) ;; stop create backup files
(setq backup-directory-alist '((".*" . "~/.Trash")))

(setq set-fill-column 120)
(setq fill-column 120)

(defun volatile-kill-buffer ()
   "Kill current buffer unconditionally."
   (interactive)
   (let ((buffer-modified-p nil))
     (kill-buffer (current-buffer))))

(use-package general
  :ensure t
  :config
  (general-evil-setup)
  (general-create-definer jm/leader-keys
    :states '(normal insert visual emacs)
    :keymaps 'override
    :prefix "SPC"
    :global-prefix "M-SPC") ;; leader key in insert mode
  
  ;; emacsphere help
  (jm/leader-keys
    "h" '(manual-emacsphere t :wk "Emacsphere help"))

  ;; agenda
  (jm/leader-keys
    "a" '(:ignore t :wk "Org-agenda")
    "a a" '(org-agenda :wk "Open org agenda menu")
    "a f" '((lambda () (interactive) (find-file "~/Documents/OrgFiles/Tasks.org")) :wk "Find tasks file")
    "a p" '(org-priority :wk "Insert a priority")
    "a s" '(org-schedule :wk "Insert a schedule")
    "a t" '(org-todo :wk "Change the state: (TODO/DONE/...)")
  )

  ;; org
  (jm/leader-keys
    "o" '(:ignore t :wk "Org-...")
    "o n"   '(:ignore t :wk "Org-notes")
    "o n f" '(org-roam-node-find :wk "Create a note")
    "o n i" '(org-roam-node-insert :wk "Create a link")
    "o n l" '(org-roam-buffer-toggle :wk "Create a note")
    "o n c" '(org-id-get-create :wk "Create a node id")

    "o h"   '(:ignore t :wk "Highlight")
    ;; "o h a" '(unhighlight-all-in-buffer :wk "Un highlight a regexp")
    "o h h" '(highlight-regexp :wk "Highlight a regexp")
    "o h u" '(unhighlight-regexp :wk "Un highlight a regexp")

    "o t"   '(:ignore t :wk "Org-timer")
    "o t c" '(org-time-stamp :wk "Stamp current time")
    "o t p" '(org-timer-pause-or-continue :wk "Pause/Continue the timer")
    "o t q" '(org-timer-stop :wk "Stop timer")
    "o t s" '(org-timer-start :wk "Start timer")
    "o t t" '(org-timer-set-timer :wk "Set decreasing timer"))

  ;; eval
  (jm/leader-keys
    "e" '(:ignore t :wk "Evaluate")    
    "e b" '(eval-buffer :wk "Evaluate elisp in buffer")
    "e d" '(eval-defun :wk "Evaluate defun containing or after point")
    "e e" '(eval-expression :wk "Evaluate and elisp expression")
    "e l" '(eval-last-sexp :wk "Evaluate elisp expression before point")
    "e r" '(eval-region :wk "Evaluate elisp in region"))

  ;; buffers
  (jm/leader-keys
    "b" '(:ignore t :wk "Buffer")
    "b b" '(switch-to-buffer :wk "Switch buffer")
    ;; "b c" '(kill-this-buffer :wk "Close this buffer")
    "b c" '(volatile-kill-buffer :wk "Close this buffer")
    "b i" '(ibuffer :wk "Ibuffer")
    "b k" '(kill-buffer :wk "Close a buffer")
    "b n" '(next-buffer :wk "Next buffer")
    "b p" '(previous-buffer :wk "Previous buffer")
    "b r" '(revert-buffer :wk "Reload buffer")
    "b s" '(save-buffer :wk "Save buffer"))

  (jm/leader-keys
    "w" '(:ignore t :wk "Windows")
    ;; Window splits
    "w c" '(evil-window-delete :wk "Close window")
    "w n" '(evil-window-new :wk "New window")
    "w s" '(evil-window-split :wk "Horizontal split window")
    "w v" '(evil-window-vsplit :wk "Vertical split window")
    "w o" '(delete-other-windows :wk "Delete other windows")
    ;; Window motions
    "w h" '(evil-window-left :wk "Goto window left")
    "w j" '(evil-window-down :wk "Goto window down")
    "w k" '(evil-window-up :wk "Goto window up")
    "w l" '(evil-window-right :wk "Goto window right")
    "w w" '(evil-window-next :wk "Goto next window")
    ;; Move Windows
    "w H" '(buf-move-left :wk "Buffer move left")
    "w J" '(buf-move-down :wk "Buffer move down")
    "w K" '(buf-move-up :wk "Buffer move up")
    "w L" '(buf-move-right :wk "Buffer move right")
    "w t" '(term :wk "Open terminal"))

  ;; files
  (jm/leader-keys
    "f" '(:ignore t :wk "Files")
    "f c" '((lambda () (interactive) (find-file "~/.emacs.d/config.org")) :wk "Find config file")
    "f d" '(dashboard-open :wk "Open dashboard buffer")
    "f e" '(elfeed :wk "Open elfeed news")
    "f f" '(find-file :wk "Find files")
    "f m" '(mu4e :wk "Open mail")
    "f r" '((lambda () 
	        (interactive)
                (load-file "~/.emacs.d/init.el")
                (ignore (elpaca-process-queues)))
              :wk "Reload emacs config")
    "f u" '(sudo-edit-find-file :wk "Sudo find file")
    "f U" '(sudo-edit :wk "Sudo edit file")
    "f y" '(copy-file :wk "Copy a file")
    "TAB TAB" '(evilnc-comment-or-uncomment-lines :wk "Comment line"))

  ;; bookmarks and registers
  (jm/leader-keys
    "r" '(:ignore t :wk "Bookmarks")
    "r j" '(bookmark-jump :wk "Jump to the bookmark <name>")
    "r d" '(bookmark-delete :wk "Delete the bookmark <name>")
    "r l" '(bookmark-bmenu-list :wk "List the the bookmarks")
    "r n" '(bookmark-set :wk "Set a new bookmark")
    "r N" '(bookmark-set-no-overwrite :wk "Set a new bookmark without overwrite an existing bookmark")
    "r s" '(bookmark-save :wk "Save all the current bookmark values"))

  ;; magit
  (jm/leader-keys
    "m" '(:ignore t :wk "Magit")
    "m g" '(magit-status :which-key "Magit status"))

  ;; python
  (jm/leader-keys
    "p" '(:ignore t :wk "Python dev")
    "p b" '(python-shell-send-buffer :wk "Run python buffer")
    "p e" '(pyenv-mode-set :wk "Python environment set")
    "p f" '(python-shell-send-file :wk "Run python file")
    "p l" '(python-shell-send-region :wk "Run python region/lines")
    "p r" '(run-python :wk "Run python interpreter")
    "p c" '(compile :wk "Compile"))

  ;; vterm
  (jm/leader-keys
    "v" '(:ignore t :wk "vterm")
    "v o" '(vterm :wk "Open vterm")
    "v t" '(vterm-toggle :wk "Toggle vterm")
    "v T" '(vterm-toggle-show :wk "Toggle vterm show"))
)

(global-set-key (kbd "C-<left>") 'shrink-window-horizontally)
(global-set-key (kbd "C-<right>") 'enlarge-window-horizontally)
(global-set-key (kbd "C-<down>") 'shrink-window)
(global-set-key (kbd "C-<up>") 'enlarge-window)

(use-package which-key
    :ensure t
    :init
        (which-key-mode 1)
    :diminish
    :config
    (setq which-key-side-window-location 'bottom
        which-key-sort-order #'which-key-key-order-alpha
        which-key-sort-uppercase-first nil
        which-key-add-column-padding 1
        which-key-max-display-columns nil
        which-key-min-display-lines 6
        which-key-side-window-slot -10
        which-key-side-window-max-height 0.25
        which-key-idle-delay 0.2
        which-key-max-description-length 35
        which-key-allow-imprecise-window-fit nil
        which-key-separator " → " ))

(use-package counsel
  :after ivy
  :ensure t
  :config (counsel-mode))

(use-package ivy
  :ensure t
  :bind
    (("C-c C-r" . ivy-resume)
     ("C-x B" . ivy-switch-buffer-other-window))
  :custom
    (setq ivy-use-virtual-buffers t)
    (setq ivy-count-format "(%d/%d) ")
    (setq enable-recursive-minibuffers t)
  :config
    (ivy-mode))

(use-package ivy-rich
  :after ivy
  :ensure t
  :init (ivy-rich-mode 1)
  :custom
    (ivy-virtual-abbreviate 'full
     ivy-rich-switch-buffer-align-virtual-buffer t
     ivy-rich-path-style 'abbrev)
  :config
    (ivy-set-display-transformer 'ivy-switch-buffer
                                 'ivy-rich-switch-buffer-transformer))

(use-package org
    :hook
	(org-mode . (lambda ()
		    (org-indent-mode)
                    (global-display-line-numbers-mode nil)
		    (setq display-line-numbers nil)))
    :defer t
    :config
	(setq org-edit-src-content-indentation 0))

(setq org-agenda-files 
        '("~/Documents/OrgFiles/Tasks.org"))

(setq org-agenda-span 31) ;; mostra 7 dias
(setq org-agenda-start-day "-7d") ;; começa 3 dias antes de hoje

(setq org-agenda-todo-ignore-done t)
(setq org-agenda-custom-commands
      '(("A" "View all details"
         ((tags-todo "PRIORITY=\"A\"-DONE"
                     ((org-agenda-overriding-header "High-priority tasks:")))
          (tags-todo "PRIORITY=\"B\"-DONE"
                     ((org-agenda-overriding-header "Medium-priority tasks:")))
          (tags-todo "PRIORITY=\"C\"-DONE"
                     ((org-agenda-overriding-header "Low-priority tasks:")))
          (tags-todo "reminder-DONE"
                     ((org-agenda-overriding-header "Tasks marked with reminders:")))
          (agenda "")
          (alltodo "")))))

(use-package org-fancy-priorities
    :ensure t
    :defer t
    :hook (org-mode . org-fancy-priorities-mode)
    :config
        (setq org-fancy-priorities-list '("🔴" "🟡" "🟢")))

(setq org-todo-keywords
    '((sequence
        "TODO(t)"
        "WAIT(w)"
        "CANCELLED(c)"
        "IN-PROGRESS(p)"
	"|"
        "DONE(d)"
)))

(setq org-todo-keyword-faces
      '(("TODO"      . (:foreground "orange red" :weight bold))
        ("WAIT"      . (:foreground "goldenrod" :weight bold))
        ("DONE"      . (:foreground "forest green" :weight bold))
        ("CANCELLED" . (:foreground "gray50" :weight bold :strike-through t))
        ("IN-PROGRESS" . (:foreground "dodger blue" :weight bold))
))

(add-hook 'org-agenda-mode-hook
          (lambda ()
	    (evil-mode 1)
            (evil-normalize-keymaps)
            (evil-local-mode 1)))

(use-package org-roam
    :ensure t
    :custom
        (org-roam-directory "~/Documents/OrgFiles/org_notes")
        (org-roam-completion-everywhere t)
    :config
        (org-roam-setup))

(use-package org-bullets
    :ensure t
    :defer t
    :hook (org-mode . org-bullets-mode))

(use-package toc-org
    :ensure t
    :defer t
    :hook (org-mode . toc-org-enable))

(use-package simple-httpd
    :ensure t
    :defer t)
(use-package htmlize
    :ensure t
    :after org
    :defer t
    :config
        (setq org-html-htmlize-output-type 'inline-css))
(add-hook 'org-mode-hook #'htmlize-buffer)

(delete-selection-mode 1)    ;; You can select text and delete it by typing.
(electric-indent-mode -1)    ;; Turn off the weird indenting that Emacs does by default.
(electric-pair-mode 1)       ;; Turns on automatic parens pairing
;; The following prevents <> from auto-pairing when electric-pair-mode is on.
;; Otherwise, org-tempo is broken when you try to <s TAB...
;; (add-hook 'org-mode-hook (lambda ()
;;            (setq-local electric-pair-inhibit-predicate
;;                    `(lambda (c)
;;                   (if (char-equal c ?<) t (,electric-pair-inhibit-predicate c))))))
(global-auto-revert-mode t)  ;; Automatically show changes if the file has changed
(scroll-bar-mode -1)         ;; Disable visible scrollbar
(tool-bar-mode -1)           ;; Disable the toolbar
(tooltip-mode -1)            ;; Disable tooltips
(menu-bar-mode -1)           ;; Disable the menu bar
(set-fringe-mode 10)         ;; Give some breathing room

(setq visible-bell t)  ;; Set up the visible bell

(column-number-mode 1)
(global-display-line-numbers-mode 1) ;; Display line numbers
(setq display-line-numbers-type 'relative) ;; Add relative number

(global-visual-line-mode t)  ;; Enable truncated lines

;; scroll one line at a time (less "jumpy" than defaults)
(setq mouse-wheel-scroll-amount '(3 ((shift) . 3))) ;; rolar 3 linhas por vez
(setq mouse-wheel-progressive-speed nil) ;; sem aceleração
(setq mouse-wheel-follow-mouse 't) ;; rolar a janela sob o mouse
(setq scroll-step 1) ;; rolar uma linha de cada vez no teclado


(pixel-scroll-precision-mode t)
(setq redisplay-skip-fontification-on-input t) 

;; init the emacs with full screen
(add-to-list 'default-frame-alist '(fullscreen . maximized))

;; close Messages buffer when starting emacs
(add-hook 'emacs-startup-hook
          (lambda ()
            (when (get-buffer "*Messages*")
              (kill-buffer "*Messages*"))))

;; display a vertical line
(setq-default display-fill-column-indicator-column 130)
(add-hook 'prog-mode-hook #'display-fill-column-indicator-mode)

(use-package dashboard
    :ensure t 
    :hook
	(dashboard-mode . (lambda ()
                    (global-display-line-numbers-mode nil)
		    (setq display-line-numbers nil)))
    :init
        (setq initial-buffer-choice 'dashboard-open)
        (setq dashboard-set-heading-icons t)
        (setq dashboard-set-file-icons t)
        (setq dashboard-banner-logo-title "(Emacs)phere Is More Than A Text Editor!")
        (setq dashboard-startup-banner "~/.emacs.d/images/logo2.txt")
        ;; (setq dashboard-startup-banner 'logo) ;; use standard emacs logo as banner
        ;; (setq dashboard-startup-banner "~/.emacs/images/emacsphere-dash.png")  ;; use custom image as banner
        (setq dashboard-center-content nil)
        (setq dashboard-items '((recents . 5)
                                (agenda . 5 )
                                (bookmarks . 5)))
                                ;; (projects . 3)
                                ;; (registers . 3)))
    :custom
        (dashboard-modify-heading-icons '((recents . "file-text")
                                        (bookmarks . "book")))
    :config
        (dashboard-setup-startup-hook))

(set-face-attribute 'default nil
  :font "FiraCode Nerd Font"
  :height 90
  :weight 'medium)
(set-face-attribute 'variable-pitch nil
  :font "FiraCode Nerd Font"
  :height 100
  :weight 'medium)
(set-face-attribute 'fixed-pitch nil
  :font "FiraCode Nerd Font"
  :height 90
  :weight 'medium)
(set-face-attribute 'mode-line-active nil
  :font "FiraCode Nerd Font"
  :height 100
  :weight 'medium)
(set-face-attribute 'mode-line nil
  :font "FiraCode Nerd Font"
  :height 100
  :weight 'medium)
(set-face-attribute 'font-lock-comment-face nil
  :slant 'italic)
(set-face-attribute 'font-lock-keyword-face nil
  :slant 'italic)
(add-to-list 'default-frame-alist '(font . "FiraCode Nerd Font-9"))
(setq-default line-spacing 0.12)

(use-package all-the-icons
  :ensure t
  :config (display-graphic-p))
    
(use-package all-the-icons-dired
  :ensure t
  :hook (dired-mode . (lambda () (all-the-icons-dired-mode t))))

(use-package all-the-icons-ivy-rich
  :ensure t
  :init (all-the-icons-ivy-rich-mode 1))

(use-package transient
  :ensure t
  :defer t)

(use-package magit
    :ensure t
    :defer t
    :after evil-collection)

(use-package vterm
    :ensure t
    :defer t
    :config
        (setq shell-file-name "/bin/sh"
            vterm-max-scrollback 5000))

(use-package vterm-toggle
    :ensure t
    :defer t
    :after vterm
    :config
    ;; When running programs in Vterm and in 'normal' mode, make sure that ESC
    ;; kills the program as it would in most standard terminal programs.
    (evil-define-key 'normal vterm-mode-map (kbd "<escape>") 'vterm--self-insert)
    (setq vterm-toggle-fullscreen-p nil)
    (setq vterm-toggle-scope 'project)
    (add-to-list 'display-buffer-alist
               '((lambda (buffer-or-name _)
                     (let ((buffer (get-buffer buffer-or-name)))
                       (with-current-buffer buffer
                         (or (equal major-mode 'vterm-mode)
                             (string-prefix-p vterm-buffer-name (buffer-name buffer))))))
                  (display-buffer-reuse-window display-buffer-at-bottom)
                  ;;(display-buffer-reuse-window display-buffer-in-direction)
                  ;;display-buffer-in-direction/direction/dedicated is added in emacs27
                  ;;(direction . bottom)
                  ;;(dedicated . t) ;dedicated is supported in emacs27
                  (reusable-frames . visible)
                  (window-height . 0.4))))

(use-package hl-todo
  :ensure t
  :defer t
  :hook ((org-mode . hl-todo-mode)
         (prog-mode . hl-todo-mode))
  :config
  (setq hl-todo-highlight-punctuation ":"
        hl-todo-keyword-faces
        `(("TODO"       warning bold)
          ("FIXME"      error bold)
          ("HACK"       font-lock-constant-face bold)
          ("REVIEW"     font-lock-keyword-face bold)
          ("NOTE"       success bold)
          ("DONE"       . "#00ff00")
          ("DEPRECATED" font-lock-doc-face bold)
          ("todo"       warning bold)
          ("fixme"      error bold)
          ("hack"       font-lock-constant-face bold)
          ("review"     font-lock-keyword-face bold)
          ("note"       success bold)
          ("done"       . "#00ff00")
          ("deprecated" font-lock-doc-face bold)
          ("Todo"       warning bold)
          ("Fixme"      error bold)
          ("Hack"       font-lock-constant-face bold)
          ("Review"     font-lock-keyword-face bold)
          ("Note"       success bold)
          ("Done"       . "#00ff00")
          ("Deprecated" font-lock-doc-face bold))))

(use-package sudo-edit
    :ensure t
    :defer t)

(use-package pyenv-mode
    :ensure t
    :init
        (setenv "WORKON_HOME" "~/.pyenv/versions/")
    :config
        (pyenv-mode))

(use-package elfeed
    :ensure t
    :defer t
    :config
    (setq elfeed-feeds
            (quote
            ;; Linux & Open Source
            (("https://lwn.net/headlines/newrss" news linux)
            ("https://www.omgubuntu.co.uk/feed" news linux ubuntu)
            ("https://www.phoronix.com/rss.php" news linux benchmarks)
            ("https://www.linuxjournal.com/node/feed" news linux)
            ("https://www.kernel.org/feeds/kdist.xml" news linux kernel)

            ;; Computer Science & Programming
            ("https://technews.acm.org/feeds/todaysnews.xml" news cs)
            ;; ("https://news.ycombinator.com/rss" news tech programming)
            ("http://feeds.arstechnica.com/arstechnica/index" news tech)
            ("https://codeforces.com/rss" programming competitive-programming)

            ;; Science & Technology
            ("https://www.nature.com/feeds/news_rss.rdf" news science)
            ("https://www.science.org/rss/news_current.xml" news science)
            ("https://www.technologyreview.com/feed/" news tech ai)
            ("https://www.quantamagazine.org/feed/" news science math cs)

            ;; Artificial Intelligence & Machine Learning
            ("https://www.deepmind.com/blog/rss.xml" ai research)
            ("https://openai.com/blog/rss/" ai research)
            ("https://ai.googleblog.com/feeds/posts/default" ai research google)
            ("https://towardsdatascience.com/feed" ai ml data-science)

            ;; Optimization & Algorithms
            ("http://www.optimization-online.org/rss/" optimization research)
            ("https://orinanobworld.blogspot.com/feeds/posts/default" optimization operations-research)
            ("https://www.mathopt.org/news.rss" optimization math)

	    ;; Redit Commutities
            ("https://www.reddit.com/r/booksuggestions/.rss" booksuggestion reddit)
	    ("https://www.reddit.com/r/emacs/.rss" emacs reddit)
         ))))
  
(use-package elfeed-goodies
    :ensure t
    :defer t
    :after elfeed
    :config
        (elfeed-goodies/setup)
        (setq elfeed-goodies/entry-pane-size 0.5))

(use-package pdf-tools
    :ensure t
    :defer t
    :commands (pdf-loader-install)
    :mode "\\.pdf\\'"
    :bind (:map pdf-view-mode-map
                ("j" . pdf-view-next-line-or-next-page)
                ("k" . pdf-view-previous-line-or-previous-page)
                ("C-=" . pdf-view-enlarge)
                ("C--" . pdf-view-shrink))
    :init (pdf-loader-install)
    :config (add-to-list 'revert-without-query ".pdf"))

(add-hook 'pdf-view-mode-hook (lambda ()
                              (setq pdf-view-display-size 'fit-page) ;; Ajusta o tamanho da página ao buffer
                              (setq pdf-view-use-scaling t)          ;; Habilita escalonamento para melhor qualidade
                              (setq pdf-view-use-imagemagick nil)    ;; Desativa o uso do ImageMagick (se estiver habilitado)
                              (setq pdf-view-resolution 200)         ;; Define resolução em DPI (300 é uma boa qualidade)
                              (setq pdf-cache-prefetch-delay 0.5)    ;; Prefetch de páginas vizinhas
                              (setq pdf-cache-prefetch-pages 5)      ;; Número de páginas para pré-carregar
                              (setq display-line-numbers nil)
                              (setq-local redisplay-dont-pause t)
                              (hl-line-mode -1)
                              (blink-cursor-mode -1)
                              (display-line-numbers-mode -1)))

(use-package request
    :ensure t
    :defer t)

(use-package mu4e
  :ensure nil
  :load-path "/usr/share/emacs/site-lisp/mu4e/"
  :config
  (setq mu4e-change-filenames-when-moving t
        mu4e-update-interval (* 3 60)
        mu4e-get-mail-command "mbsync -a"
        mu4e-maildir "~/Mail"
        message-send-mail-function 'smtpmail-send-it
        auth-sources '("~/.authinfo.gpg"))
        ;; mu4e-compose-context-policy 'ask
        ;; mu4e-context-policy 'pick-first

  ;; sort emails by date
  (setq mu4e-headers-sort-field :date)
  (setq mu4e-headers-sort-direction 'descending)

  ;; Shortcuts
  (setq mu4e-maildir-shortcuts
        '(("/gmail/INBOX"             . ?g)
          ("/gmail/Sent"              . ?G)
          ("/gmail/Trash"             . ?x)
          ("/gmail/Drafts"            . ?d)
          ("/dei/INBOX"               . ?i)
          ("/dei/mail/sent-mail"      . ?s)
          ("/dei/mail/Trash"          . ?t)
          ("/dei/mail/Drafts"         . ?D)))

  ;; Context for multiple accounts
  (setq mu4e-contexts
        `( ,(make-mu4e-context
             :name "Gmail"
             :enter-func (lambda () (mu4e-message "Loading Gmail..."))
             :match-func (lambda (msg)
                           (when msg
                             (string-prefix-p "/gmail" (mu4e-message-field msg :maildir))))
             :vars '((user-mail-address . "jesmoreira2010@gmail.com")
                     (user-full-name . "João ES Moreira")
                     (mu4e-sent-folder   . "/gmail/Sent")
                     (mu4e-drafts-folder . "/gmail/Drafts")
                     (mu4e-trash-folder  . "/gmail/Trash")
                     (mu4e-refile-folder . "/gmail/Archive")
                     (smtpmail-smtp-server . "smtp.gmail.com")
                     (smtpmail-smtp-service . 465)
                     (smtpmail-stream-type . ssl)))

           ,(make-mu4e-context
             :name "DEI"
             :enter-func (lambda () (mu4e-message "Loading DEI..."))
             :match-func (lambda (msg)
                           (when msg
                             (string-prefix-p "/dei" (mu4e-message-field msg :maildir))))
             :vars '((user-mail-address . "joaomoreira@student.dei.uc.pt")
                     (user-full-name . "joao moreira")
                     (mu4e-sent-folder   . "/dei/mail/sent-mail")
                     (mu4e-drafts-folder . "/dei/mail/Drafts")
                     (mu4e-trash-folder  . "/dei/mail/Trash")
                     (mu4e-refile-folder . "/dei/mail/Archive")
                     (smtpmail-smtp-server . "smtp.dei.uc.pt")
                     (smtpmail-smtp-service . 465)
                     (smtpmail-stream-type . ssl)))))
)

(use-package mu4e-alert
  :ensure t
  :after mu4e
  :config
    (mu4e-alert-enable-notifications)
    (mu4e-alert-enable-mode-line-display)
    (add-hook 'after-init-hook #'mu4e-alert-enable)) ;; for all folder in mu4e

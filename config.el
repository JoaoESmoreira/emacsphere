(add-to-list 'load-path "~/.emacs.d/scripts/")

(require 'buffer-move)   ;; Buffer-move for better window management

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
  
  ;; buffers
  (jm/leader-keys
    "b" '(:ignore t :wk "Buffer")
    "b b" '(switch-to-buffer :wk "Switch buffer")
    ;; "b c" '(kill-this-buffer :wk "Close this buffer")
    "b c" '(volatile-kill-buffer :wk "Close this buffer")
    "b k" '(kill-buffer :wk "Close a buffer")
    "b i" '(ibuffer :wk "Ibuffer")
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
    ;; "f d" '(dashboard-open :wk "Open dashboard buffer")
    "f f" '(find-file :wk "Find files")
    "TAB TAB" '(evilnc-comment-or-uncomment-lines :wk "Comment line"))

  ;; magit
  (jm/leader-keys
    "m" '(:ignore t :wk "Magit")
    "m g" '(magit-status :which-key "Magit status"))
)

(use-package org-bullets
    :ensure t
    :hook (org-mode . org-bullets-mode))

(use-package org
    :hook
	(org-mode . (lambda ()
		    (org-indent-mode)
                    (global-display-line-numbers-mode nil)
		    (setq display-line-numbers nil)))
    :config
	(setq org-edit-src-content-indentation 0))

(use-package toc-org
    :ensure t
    :hook (org-mode . toc-org-enable))

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

(use-package transient
  :ensure t)

(use-package magit
    :ensure t
    :after evil-collection)

(setq make-backup-files nil) ;; stop create backup files
(setq backup-directory-alist '((".*" . "~/.Trash")))

;;; $DOOMDIR/config.el -*- lexical-binding: t; -*-

;; Place your private configuration here! Remember, you do not need to run 'doom
;; sync' after modifying this file!


;; Some functionality uses this to identify you, e.g. GPG configuration, email
;; clients, file templates and snippets.
(setq user-full-name "Flávio L. C. de Moura"
      user-mail-address "flavio@flaviomoura.info")

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

(defun update-org-modified-property ()
  "If a file contains a '#+LAST_MODIFIED' property update it to contain
  the current date/time"
  (interactive)
  (save-excursion
    (widen)
    (goto-char (point-min))
    (when (re-search-forward "^#\\+LAST_MODIFIED:" (point-max) t)
      (progn
        (kill-line)
        (insert (format-time-string " %d/%m/%Y %H:%M:%S") )))))

(defun org-mode-before-save-hook ()
  (when (eq major-mode 'org-mode)
    (update-org-modified-property)))

(add-hook 'before-save-hook #'org-mode-before-save-hook)

(defvar org-roam-capture-immediate-template
  '("d" "default" plain
    #'org-roam-capture--get-point
    "%?"
    :file-name "%<%Y%m%d%H%M%S>-${slug}"
    :head "#+title: ${title}\n#+created: %u\n#+last_modified: %U\n\n"
    :immediate-finish t
    :unnarrowed t)
  "Capture template to use for immediate captures in Org-roam.")

(defun org-roam-insert-immediate (arg &rest args)
  "Find an Org-roam file, and insert a relative org link to it at point.
This variant inserts the link immediately by using the template
defined in `org-roam-capture-immediate-template'.  See
`org-roam-insert' for details."
  (interactive "P")
  (let ((org-roam-capture-templates (list org-roam-capture-immediate-template))
        (args (push arg args)))
    (apply #'org-roam-insert args)))

;; If you use `org' and don't want your org files in the default location below,
;; change `org-directory'. It must be set before org loads!
(setq org-directory "~/idrive/org")
(setq org-roam-directory "~/idrive/org")

(after! org-roam
  (setq org-roam-graph-viewer "/usr/bin/open")
  (setq org-roam-capture-templates
        '(("d" "default" plain (function org-roam--capture-get-point)
           "%?"
           :file-name "${slug}"
           :head "#+TITLE: ${title} \n#+CREATED: %U\n#+LAST_MODIFIED: %U\n#+ROAM_ALIAS: \n\n- tags :: "
           :unnarrowed t))))

(use-package org-roam-bibtex
  :after org-roam
  :hook (org-roam-mode . org-roam-bibtex-mode)
  :bind (:map org-mode-map
         (("C-c n a" . orb-note-actions)))
  :config
  (setq org-roam-bibtex-preformat-keywords
        '("=key=" "title" "url" "file" "author-or-editor" "keywords"))
  (setq orb-templates
        '(("r" "ref" plain (function org-roam-capture--get-point)
           ""
           :file-name "${slug}"
           :head "#+TITLE: ${title} \n#+CREATED: %U\n#+LAST_MODIFIED: %U\n#+ROAM_KEY: ${ref}\n#+ROAM_ALIAS: \n\n- tags ::

\n* ${title}\n  :PROPERTIES:\n  :Custom_ID: ${=key=}\n  :URL: ${url}\n  :AUTHOR: ${author-or-editor}\n  :NOTER_DOCUMENT: %(orb-process-file-field \"${=key=}\")\n  :NOTER_PAGE: \n  :END:\n\n"

           :unnarrowed t))))

(use-package org-journal
  :bind
  ("C-c n j" . org-journal-new-entry)
  :custom
  (org-journal-dir "~/idrive/org")
  (org-journal-date-prefix "#+TITLE: ")
  (org-journal-file-format "%Y-%m-%d.org")
  (org-journal-date-format "%A, %d %B %Y"))
(setq org-journal-enable-agenda-integration t)

(use-package org-ref
  :after org
  :config
  (setq
   org-ref-completion-library 'org-ref-ivy-cite
   org-ref-get-pdf-filename-function 'org-ref-get-pdf-filename-helm-bibtex
   org-ref-default-bibliography '("~/idrive/org/zotLib.bib")
   org-ref-pdf-directory "~/idrive/org/"
   org-ref-note-title-format "* TODO %y - %t\n :PROPERTIES:\n  :Custom_ID: %k\n  :NOTER_DOCUMENT: %F\n :ROAM_KEY: cite:%k\n  :AUTHOR: %9a\n  :JOURNAL: %j\n  :YEAR: %y\n  :VOLUME: %v\n  :PAGES: %p\n  :DOI: %D\n  :URL: %U\n :END:\n\n"
   org-ref-notes-function 'orb-edit-notes
   bibtex-completion-library-path "~/idrive/org/"
   bibtex-completion-bibliography "~/idrive/org/zotLib.bib"
   bibtex-completion-pdf-field "file"
   bibtex-completion-notes-template-multiple-files
   (concat
    "#+TITLE: ${title}\n"
    "#+ROAM_KEY: cite:${=key=}\n"
    "* TODO Notes\n"
    ":PROPERTIES:\n"
    ":Custom_ID: ${=key=}\n"
    ":NOTER_DOCUMENT: %(orb-process-file-field \"${=key=}\")\n"
    ":AUTHOR: ${author-abbrev}\n"
    ":JOURNAL: ${journaltitle}\n"
    ":DATE: ${date}\n"
    ":YEAR: ${year}\n"
    ":DOI: ${doi}\n"
    ":URL: ${url}\n"
    ":END:\n\n"
    )
   ))

(use-package org-noter
  :after (:any org pdf-view)
  :config
  (setq
   ;; The WM can handle splits
   ;;org-noter-notes-window-location 'other-frame
   ;; Please stop opening frames
   org-noter-always-create-frame nil
   ;; I want to see the whole file
   org-noter-hide-other nil
   ))


(after! pdf-view
  ;; open pdfs scaled to fit page
  (setq-default pdf-view-display-size 'fit-width)
  (add-hook! 'pdf-view-mode-hook (evil-colemak-basics-mode -1))
  ;; automatically annotate highlights
  (setq pdf-annot-activate-created-annotations t
        pdf-view-resize-factor 1.1)
   ;; faster motion
 (map!
   :map pdf-view-mode-map
   :n "g g"          #'pdf-view-first-page
   :n "G"            #'pdf-view-last-page
   :n "N"            #'pdf-view-next-page-command
   :n "E"            #'pdf-view-previous-page-command
   :n "e"            #'evil-collection-pdf-view-previous-line-or-previous-page
   :n "n"            #'evil-collection-pdf-view-next-line-or-next-page
   :localleader
   (:prefix "o"
    (:prefix "n"
     :desc "Insert" "i" 'org-noter-insert-note
     ))
 ))
;;(use-package org-roam-server
;;  :ensure nil
;;  :load-path "~/idrive/org/org-roam-server")
;; This determines the style of line numbers in effect. If set to `nil', line
;; numbers are disabled. For relative line numbers, set this to `relative'.
(setq display-line-numbers-type t)

(setq bbdb-file "~/idrive/bbdb")

(after! org (setq org-latex-default-packages-alist '(("AUTO" "inputenc" t)
                                                     ("english,francais,portuguese" "babel" t)
                                                     ("" "lmodern" nil)
                                                     ("T1" "fontenc" t)
                                                     ("" "natbib" t)
                                                     ("" "graphicx" t)
                                                     ("" "xcolor" t)
                                                     ("normalem" "ulem" t)
                                                     ("" "textcomp" t)
                                                     ("" "marvosym" t)
                                                     ("" "wasysym" t)
                                                     ("" "amssymb")
                                                     ("" "amsmath" t)
                                                     ("" "amsthm" t)
                                                     ("" "qtree" t)
                                                     ("" "bussproofs" t)
                                                     ("" "proof" t)
                                                     ("" "cancel" t)
                                                     ("" "url" t)
                                                     ("" "pdflscape" t)
                                                     ("" "fontawesome" t)
                                                     ("" "tikz" t))))

(eval-after-load "preview"
  '(add-to-list 'preview-default-preamble "\\PreviewEnvironment{tikzpicture}" t))
(setq org-latex-create-formula-image-program 'imagemagick)


(use-package pdf-view
  :hook (pdf-tools-enabled . pdf-view-midnight-minor-mode)
  :hook (pdf-tools-enabled . hide-mode-line-mode)
  :config
  (setq pdf-view-midnight-colors '("#ABB2BF" . "#282C35")))
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

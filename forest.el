;;; forest-mode.el --- Mode for Jon Sterling's Forester  -*- lexical-binding: t; -*-

;; Copyright (C) 2023 Alex Nelson

;; Author: Alex Nelson <pqnelson@gmail.com>
;; Keywords: forester

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <https://www.gnu.org/licenses/>.

;;; Commentary: I have the bare essentials implements, but no syntax
;;; highlighting. 

;; 

;;; Code:

(defvar forest-mode-hook nil)

(defvar forest-mode-namespace-default "xxx")

(defvar forest-tree-dir "~/math/trees"
  "The directory for the trees in the forest")

(setq forest-tree-dir "~/math/trees")

(defun get-forest-tree-dir-path ()
  (file-relative-name (expand-file-name forest-tree-dir)
                      default-directory))

(defvar forest-author-name "alex-nelson")

;; TODO: prepopulate this somehow?
(defvar forest-tree-namespaces-coll '())

;; variables for debugging
(defvar v1 nil)
(defvar r1 nil)

(defvar forest-recently-created-tree "")

(defun forest-mode-complete-namespaces ()
  forest-tree-namespaces-coll)

(defun forest-mode-create-tree ()
  (interactive)
  ;; OCaml's Eio library freaks out if you try to reference a
  ;; subdirectory somewhere else, so we need to change directories to
  ;; get to the forest
  (cd forest-tree-dir)
  (cd "..")
  (let ((choice (completing-read (format "Tree namespace [%s]: "
                                         forest-mode-namespace-default)
                                 (forest-mode-complete-namespaces)
                                 nil nil nil nil
                                 forest-mode-namespace-default)))
    (setq forest-mode-namespace-default choice)
    ;; Remember new namespaces for later
    (unless (member choice forest-tree-namespaces-coll)
      (push choice forest-tree-namespaces-coll))
    ;; debugging, save the commands
    (setq v1 (format "opam exec -- forester new --dest=%s --prefix=%s"
                     (get-forest-tree-dir-path) ;; (expand-file-name forest-tree-dir)
                     choice))
    (setq r1 (shell-command-to-string
              (format "opam exec -- forester new --dest=%s --prefix=%s"
                      (get-forest-tree-dir-path)
                      ;; forest-tree-dir
                      choice)))
    ;; open the newly created tree, and prepopulate it with info
    (let ((file-name (car (last (split-string r1)))))
      (setq forest-recently-created-tree
            (if (string-suffix-p ".tree" file-name)
                (substring file-name 0 -5)
              file-name))
      (if (string-suffix-p ".tree" file-name)
          (find-file file-name)
          (find-file (format "%s.tree" file-name))))
    (insert "\\title{}\n")
    (insert (format "\\author{%s}\n" forest-author-name))
    (insert "\\import{notation}\n")
    (end-of-buffer)
    (cd forest-tree-dir)
    (cd forest-tree-dir)))

(defun forest-mode-create-definition ()
  (interactive)
  (forest-mode-create-tree)
  (insert "\\taxon{definition}\n"))

(defun forest-mode-create-theorem ()
  (interactive)
  (forest-mode-create-tree)
  (insert "\\taxon{theorem}\n"))

(defun forest-mode-create-remark ()
  (interactive)
  (forest-mode-create-tree)
  (insert "\\taxon{remark}\n"))

(defun forest-mode-create-proof ()
  (interactive)
  (forest-mode-create-tree)
  (insert "\\taxon{proof}\n"))

(defun forest-mode-create-person ()
  (interactive)
  (let ((choice (completing-read "Person-name:"
                                 nil
                                 nil nil nil nil
                                 forest-mode-namespace-default)))
    (find-file (format "%s/people/%s.tree"
                       (get-forest-tree-dir-path)
                       choice))
    (insert "\\title{}\n")
    (insert "\\taxon{person}\n")
    (insert "\\meta{institution}{}\n")
    (insert "\\meta{position}{}\n")
    (insert "\\meta{external}{}\n")))

(defun forest-mode-create-ref ()
  (interactive)
  (let ((choice (completing-read "Reference file name:"
                                 nil
                                 nil nil nil nil
                                 forest-mode-namespace-default)))
    (find-file (format "%s/refs/%s.tree"
                       (get-forest-tree-dir-path)
                       choice))
    (insert "\\title{}\n")
    (insert "\\taxon{reference}\n")
    (insert "\\author{}\n")
    (insert "\\meta{bibitex}{\\startverb%\n\n\\stopverb}\n")
    (insert "\\meta{external}{}\n")))


(defvar br1 "")
(defvar forest-mode-root-tree "xxx-0001")
(defvar c1 "")
(defvar forest-mode-dir-before-compiling default-directory)

(defun forest-mode-build-project ()
  (interactive)
  ;; OCaml's Eio library freaks out if you try to reference a
  ;; subdirectory somewhere else, so we need to change directories to
  ;; get to the forest
  (let ((before-moving-dir default-directory)
        (command "opam exec -- foretser build"))
    (setq forest-mode-dir-before-compiling default-directory)
    (cd forest-tree-dir)
    (cd "..") ;; forester freaks out if we're not in the parent dir to the trees
    (setq c1 (format command
                     forest-mode-root-tree
                     (get-forest-tree-dir-path)))
    (setq br1 (shell-command-to-string
               (format command
                       forest-mode-root-tree
                       (get-forest-tree-dir-path))))
    (cd forest-mode-dir-before-compiling)))

;; TODO: add a "new remark", "new proof" command?

(defun forest-mode-transclude-latest-tree ()
  (interactive)
  (insert "\\transclude{" forest-recently-created-tree "}\n"))

;; C-c t
(defvar forest-mode-map
  (let ((map (make-keymap)))
    (define-key map "\C-l" #'forest-mode-transclude-latest-tree)
    (define-key map "\C-cn" #'forest-mode-create-tree) ;; C-c n
    (define-key map "\C-cc" #'forest-mode-build-project) ;; C-c c
    (define-key map "\C-ct" #'forest-mode-create-theorem)
    (define-key map "\C-cd" #'forest-mode-create-definition)
    (define-key map "\C-cr" #'forest-mode-create-remark)
    (define-key map "\C-cp" #'forest-mode-create-person)
    (define-key map "\C-cb" #'forest-mode-create-ref)
    map))

(add-to-list 'auto-mode-alist '("\\.tree" . forest-mode))

(defun local-tree-wrap ()
  (turn-off-auto-fill)
  (visual-line-mode))

(defun forest-mode ()
  "Major mode for Jon Sterling's Forester"
  (interactive)
  (kill-all-local-variables)
  ;;(set-syntax-table forest-mode-syntax-table)
  (use-local-map forest-mode-map)
  (setq major-mode 'forest-mode)
  (setq mode-name 'forest)
  (local-tree-wrap)
  (run-hooks 'forest-mode-hook))

(provide 'forest-mode)
;;; forest-mode.el ends here

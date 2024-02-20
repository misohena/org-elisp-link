;;; org-elisp-link.el --- Org link for elisp elements  -*- lexical-binding: t; -*-

;; Copyright (C) 2024  AKIYAMA Kouhei

;; Author: AKIYAMA Kouhei <misohena@gmail.com>
;; Keywords: lisp, outlines

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

;;; Commentary:

;; This Emacs Lisp implements org-mode link types for the definition
;; location of each Emacs Lisp element.

;; For example, you will be able to write links like the following in org-mode.
;; - [[elisp-function:dired]]
;; - [[elisp-variable:dired-warning-face]]
;; - [[elisp-face:dired-face]]
;; - [[elisp-library:dired]]

;; You can add the following properties to `org-link-parameters' for
;; those link types:
;; - :follow
;; - :export
;; - :store
;; - :activate-func
;; - :complete
;; - :completion-table  (non-standard)
;; - :capf-path  (non-standard)
;; - :capf-desc  (non-standard)

;;; Code:

(require 'seq)
(require 'cl-lib)
(require 'ol)
(require 'find-func)
(require 'help-fns)
(require 'elisp-mode)
(require 'package)

(eval-when-compile
  (require 'ox))

(declare-function org-export-derived-backend-p "ox" (backend &rest backends))
(declare-function org-export-get-backend "ox" (name))
(declare-function org-export-backend-options "ox")
(declare-function org-html-encode-plain-text "ox-html" (text))

(defgroup org-elisp-link nil
  "Org link for emacs lisp elements."
  :tag "Org Link for Emacs Lisp Element"
  :prefix "org-elisp-link-"
  :group 'org-link)

;;;; Link Type

(defconst org-elisp-link-element-types
  '(library function variable face)
  "List of element types in Emacs Lisp.")

;; If you want to change link types, do the following before calling
;; `org-elisp-link-initialize':
;; (with-eval-after-load "org-elisp-link"
;;   (setq org-elisp-link-type-function "elisp-fun"))
(defconst org-elisp-link-type-library "elisp-library") ;; or elisp-lib?
(defconst org-elisp-link-type-function "elisp-function") ;; or elisp-fun?
(defconst org-elisp-link-type-variable "elisp-variable") ;; or elisp-var?
(defconst org-elisp-link-type-face "elisp-face")

(defun org-elisp-link-type-name (element-type)
  "Return default link type name corresponding to the specified ELEMENT-TYPE.

Note that there can be multiple link type names for one element type.
(function => elisp-function, elisp-fun, elfun, etc.)"
  (symbol-value (intern (format "org-elisp-link-type-%s" element-type))))

;;;; Register Org Link Type

;;;###autoload
(defun org-elisp-link-initialize ()
  "Register link types to org-mode."
  (interactive)
  ;; You can also place the following code directly in init.el. That
  ;; can delay loading somewhat.
  ;;
  ;; The code below is just an example. You can register only the
  ;; parts you need or specify another function.
  (when (fboundp 'org-link-set-parameters) ;; Org 9.0? or later
    ;; (autoload 'org-elisp-link-follow-library "org-elisp-link")
    ;; (autoload 'org-elisp-link-follow-function "org-elisp-link")
    ;; (autoload 'org-elisp-link-follow-variable "org-elisp-link")
    ;; (autoload 'org-elisp-link-follow-face "org-elisp-link")
    ;; (autoload 'org-elisp-link-export-library "org-elisp-link")
    ;; (autoload 'org-elisp-link-export-function "org-elisp-link")
    ;; (autoload 'org-elisp-link-export-variable "org-elisp-link")
    ;; (autoload 'org-elisp-link-export-face "org-elisp-link")
    ;; (autoload 'org-elisp-link-store "org-elisp-link")
    ;; (autoload 'org-elisp-link-store-definitions "org-elisp-link")
    ;; (autoload 'org-elisp-link-store-library "org-elisp-link")
    ;; (autoload 'org-elisp-link-activate-hide-except-symbol "org-elisp-link")
    ;; (autoload 'org-elisp-link-read-library-name "org-elisp-link")
    ;; (autoload 'org-elisp-link-read-function-name "org-elisp-link")
    ;; (autoload 'org-elisp-link-read-variable-name "org-elisp-link")
    ;; (autoload 'org-elisp-link-read-face-name "org-elisp-link")
    ;; (autoload 'org-elisp-link-completion-table-library "org-elisp-link")
    ;; (autoload 'org-elisp-link-completion-table-function "org-elisp-link")
    ;; (autoload 'org-elisp-link-completion-table-variable "org-elisp-link")
    ;; (autoload 'org-elisp-link-completion-table-face "org-elisp-link")
    ;; (autoload 'org-elisp-link-capf-path-library "org-elisp-link")
    ;; (autoload 'org-elisp-link-capf-path-function "org-elisp-link")
    ;; (autoload 'org-elisp-link-capf-path-variable "org-elisp-link")
    ;; (autoload 'org-elisp-link-capf-path-face "org-elisp-link")
    ;; (autoload 'org-elisp-link-capf-desc-library "org-elisp-link")
    ;; (autoload 'org-elisp-link-capf-desc-function "org-elisp-link")
    ;; (autoload 'org-elisp-link-capf-desc-variable "org-elisp-link")
    ;; (autoload 'org-elisp-link-capf-desc-face "org-elisp-link")

    (org-link-set-parameters
     org-elisp-link-type-library
     :follow #'org-elisp-link-follow-library
     :export #'org-elisp-link-export-library
     ;; for all elements
     :store #'org-elisp-link-store
     ;; for library only
     ;;:store #'org-elisp-link-store-library
     :activate-func #'org-elisp-link-activate-hide-except-symbol
     :complete #'org-elisp-link-read-library-name
     :completion-table #'org-elisp-link-completion-table-library
     :capf-path #'org-elisp-link-capf-path-library
     :capf-desc #'org-elisp-link-capf-desc-library)

    (org-link-set-parameters
     org-elisp-link-type-function
     :follow #'org-elisp-link-follow-function
     :export #'org-elisp-link-export-function
     ;; for function, variable, face
     ;;:store #'org-elisp-link-store-definitions
     :activate-func #'org-elisp-link-activate-hide-except-symbol
     :complete #'org-elisp-link-read-function-name
     :completion-table #'org-elisp-link-completion-table-function
     :capf-path #'org-elisp-link-capf-path-function
     :capf-desc #'org-elisp-link-capf-desc-function)

    (org-link-set-parameters
     org-elisp-link-type-variable
     :follow #'org-elisp-link-follow-variable
     :export #'org-elisp-link-export-variable
     :activate-func #'org-elisp-link-activate-hide-except-symbol
     :complete #'org-elisp-link-read-variable-name
     :completion-table #'org-elisp-link-completion-table-variable
     :capf-path #'org-elisp-link-capf-path-variable
     :capf-desc #'org-elisp-link-capf-desc-variable)

    (org-link-set-parameters
     org-elisp-link-type-face
     :follow #'org-elisp-link-follow-face
     :export #'org-elisp-link-export-face
     :activate-func #'org-elisp-link-activate-hide-except-symbol
     :complete #'org-elisp-link-read-face-name
     :completion-table #'org-elisp-link-completion-table-face
     :capf-path #'org-elisp-link-capf-path-face
     :capf-desc #'org-elisp-link-capf-desc-face)))


;;;; Path

;; Path Syntax:
;; "symbol-name;option-1=value1;option_2=value2"
;; path ::= <symbol-name> <option-list>
;; <symbol-name> ::= ("\" . | [^;])+
;; <option-list> ::= <option>*
;; <option> ::= ";" <ws> <option-key> <ws> "=" <option-value>
;; <option-key> ::= [^=]+
;; <option-value> ::= [^;]+

(defun org-elisp-link-path-to-symbol-name-end (path)
  "Return the end position of the symbol name part in PATH."
  (if (string-match "\\`\\(\\(?:\\\\.\\|[^;]\\)+\\)" path) ;; \. => . (for `c-forward-to-nth-EOF-\;-or-}'
      (match-end 1)
    ;; Error?
    0))

(defun org-elisp-link-path-to-symbol-name (path)
  "Return the part of PATH without option specifications."
  ;; Replace \. => .
  (replace-regexp-in-string
   "\\\\\\(.\\)" "\\1"
   ;; Strip options in PATH.
   (substring path 0 (org-elisp-link-path-to-symbol-name-end path)) t))

(defun org-elisp-link-path-to-symbol (path)
  "Return the part of PATH without option specifications."
  (intern (org-elisp-link-path-to-symbol-name path)))

(defun org-elisp-link-path-to-options (path)
  "Return the option specification part of PATH."
  (let ((pos (length (org-elisp-link-path-to-symbol-name path)))
        options)
    (while (eq pos
               (string-match "; *\\([0-9a-zA-Z-_]+\\) *=\\([^;]+\\)" path pos))
      (push (cons (intern (concat ":" (downcase (match-string 1 path))));;ignore case
                  (match-string 2 path))
            options)
      (setq pos (match-end 0)))
    options))


;;;; Finder

;; Locate Emacs Lisp elements.

(defun org-elisp-link-find-library-file-line (symbol options)
  "Library name SYMBOL and OPTIONS => (abs-file . line-number)"
  (cons
   (find-library-name (symbol-name symbol))
   ;; Option: line=<integer>
   ;; Example:
   ;; [[elisp-library:dired;line=6][link to line 6 of dired.el]]
   (let ((line (alist-get :line options)))
     (when line
       (string-to-number line)))))

(defun org-elisp-link-find-function-noselect (symbol options)
  "Function name SYMBOL and OPTIONS => (buffer . point)"
  (org-elisp-link-find-element-noselect symbol options 'function))

(defun org-elisp-link-find-variable-noselect (symbol options)
  "Variable name SYMBOL and OPTIONS => (buffer . point)"
  (org-elisp-link-find-element-noselect symbol options 'variable))

(defun org-elisp-link-find-face-noselect (symbol options)
  "Face name SYMBOL and OPTIONS => (buffer . point)"
  (org-elisp-link-find-element-noselect symbol options 'face))

(defun org-elisp-link-find-element-noselect (symbol options element-type)
  "Elisp element SYMBOL, ELEMENT-TYPE and OPTIONS => (buffer . point)"
  (let* (;; Option: library=<string>
         ;; Example:
         ;; [[elisp-function:tetris-start-game;library=tetris]]
         (library (alist-get :library options))
         (type (pcase element-type
                 ('function nil)
                 ('variable 'defvar)
                 ('face 'defface)))
         (buffer-point
          (cond
           ((eq element-type 'library)
            (cons
             (find-file-noselect (find-library-name (symbol-name symbol)))
             nil))
           ((and library (eq element-type 'function))
            (find-function-search-for-symbol symbol type library))
           (t
            (find-definition-noselect symbol type library))))
         (buffer (car buffer-point))
         (point (cdr buffer-point)))
    ;; Option: line
    ;; Example:
    ;; [[elisp-function:dired;line=+5]]
    (let ((line (alist-get :line options)))
      (when (and line (not (string-empty-p line)))
        (when buffer
          (with-current-buffer buffer
            (if (memq (elt line 0) '(?+ ?-))
                ;; Relative
                (progn
                  (goto-char (or point (point-min)))
                  (forward-line (string-to-number line)))
              ;; Absolute
              (widen)
              (goto-char (point-min))
              (forward-line (1- (string-to-number line))))
            (setq buffer-point (cons buffer (point)))))))
    buffer-point))

(defun org-elisp-link-find-element (symbol options element-type)
  "Open the position specified by SYMBOL, ELEMENT-TYPE, OPTIONS."
  ;; Almost same as `find-function-do-it'.
  (let* ((old-point (point))
         (old-buffers (buffer-list))
         (buffer-point (save-excursion
                         (org-elisp-link-find-element-noselect symbol options
                                                               element-type)))
         (buffer (car buffer-point))
         (point (cdr buffer-point)))
    (when buffer-point
      (when (memq buffer old-buffers)
        (push-mark old-point))
      (switch-to-buffer buffer)
      (when point (goto-char point))
      (recenter find-function-recenter-line)
      (run-hooks 'find-function-after-hook))))

(defun org-elisp-link-element-file-line (symbol finder options)
  "Return the definition location of SYMBOL on the local file system.

The location of the SYMBOL is determined by FINDER.

FINDER is a function that takes SYMBOL as an argument and returns
one of the following:

- path-string
- (path-string . line-number-or-nil)
- (buffer . point-or-nil)

This function returns (full-path-of-file . line-number-or-nil)."
  (ignore-errors
    (let ((loc (funcall finder symbol options)))
      (cond
       ;; string
       ((stringp loc)
        (cons (expand-file-name loc) nil))
       ;; (string . line-number-or-nil)
       ((and (consp loc) (stringp (car loc)))
        (cons (expand-file-name (car loc)) (cdr loc)))
       ;; (buffer . point-or-nil)
       ((and (consp loc) (bufferp (car loc)))
        ;; TODO: Restore the state of buffers and points. However,
        ;; leaving it open is more efficient when converting
        ;; continuously.
        (let ((buffer (car loc))
              (point (cdr loc))) ;; point or nil
          (with-current-buffer buffer
            (cons (expand-file-name (buffer-file-name)) ;;abs-file
                  (and point
                       (line-number-at-pos point t)))))) ;;line
       (t nil)))))


;;;; Follow Link

;;;###autoload
(defun org-elisp-link-follow-library (path)
  (org-elisp-link-follow path 'library))

;;;###autoload
(defun org-elisp-link-follow-function (path)
  (org-elisp-link-follow path 'function))

;;;###autoload
(defun org-elisp-link-follow-variable (path)
  (org-elisp-link-follow path 'variable))

;;;###autoload
(defun org-elisp-link-follow-face (path)
  (org-elisp-link-follow path 'face))

(defun org-elisp-link-follow (path element-type)
  (let ((symbol (org-elisp-link-path-to-symbol path))
        (options (org-elisp-link-path-to-options path)))
    (org-elisp-link-find-element symbol options element-type)))


;;;; Export Link
;;;;; Export Function

;; The export process consists of the following two steps.
;; 1. Convert path to Web URL
;; 2. Format for target backend

;;;###autoload
(defun org-elisp-link-export-library (path desc backend &optional info)
  (org-elisp-link-export-element path desc backend info 'library))

;;;###autoload
(defun org-elisp-link-export-function (path desc backend &optional info)
  (org-elisp-link-export-element path desc backend info 'function))

;;;###autoload
(defun org-elisp-link-export-variable (path desc backend &optional info)
  (org-elisp-link-export-element path desc backend info 'variable))

;;;###autoload
(defun org-elisp-link-export-face (path desc backend &optional info)
  (org-elisp-link-export-element path desc backend info 'face))

(defun org-elisp-link-export-element (path desc backend info element-type)
  (or
   (let ((formatter (org-elisp-link-export-formatter-get backend)))
     (when (functionp formatter)
       (let* ((symbol (org-elisp-link-path-to-symbol path))
              (options (org-elisp-link-export-make-options path info))
              ;; Convert path to URL
              (url (org-elisp-link-export-path-to-url element-type
                                                      symbol options)))
         ;; Convert link to backend format
         (funcall formatter
                  url path desc info element-type symbol options))))
   ;; Plain text
   ;; (When `org-elisp-link-export-formatter-default' is invalid
   ;;  or formatter returns nil)
   (or desc path)))

(defun org-elisp-link-export-make-options (path info)
  (nconc
   ;; Get options from PATH
   (org-elisp-link-path-to-options path)
   ;; Get options from INFO
   (org-elisp-link-export-get-options info)))

;;;;; Convert Path to Web URL

(defcustom org-elisp-link-export-path-to-url-p t
  "Non-nil means convert the path to a URL on the web.

If the buffer has a :url option, that will take precedence.
For example:
#+HTML_LINK_OPTIONS: :url nil
or
#+HTML_LINK_OPTIONS: :url t"
  :group 'org-elisp-link
  :type '(choice
          (boolean)
          (function)))

(defun org-elisp-link-export-path-to-url-p (element-type symbol options)
  "Return non-nil if path should be converted to URL."
  ;; Option: url <boolean>
  (let ((url-spec (alist-get :url options)))
    (pcase url-spec
      ("nil" nil)
      ("t" t)
      (_
       (if (functionp org-elisp-link-export-path-to-url-p)
           (funcall org-elisp-link-export-path-to-url-p
                    element-type symbol options)
         org-elisp-link-export-path-to-url-p)))))

(defcustom org-elisp-link-export-path-converter-alist
  '((library . org-elisp-link-library-web-url)
    (function . org-elisp-link-function-web-url)
    (variable . org-elisp-link-variable-web-url)
    (face . org-elisp-link-face-web-url))
  "An alist of functions that convert paths to URLs for each
 emacs lisp element type."
  :group 'org-elisp-link
  :type '(alist (cons symbol function)))

(defun org-elisp-link-export-path-to-url (element-type symbol options)
  (when (org-elisp-link-export-path-to-url-p element-type symbol options)
    (let ((to-url (alist-get element-type
                             org-elisp-link-export-path-converter-alist)))
      (when (functionp to-url)
        (funcall to-url symbol options)))))

;;;;; Formatter

(defcustom org-elisp-link-export-formatter-alist
  ;; TODO: Support other backends
  '((html . org-elisp-link-export-format-as-html))
  "Alist of formatters for each backend."
  :group 'org-elisp-link
  :type '(alist (cons symbol function)))

(defcustom org-elisp-link-export-formatter-default
  #'org-elisp-link-export-format-as-plain
  "Default formatter."
  :group 'org-elisp-link
  :type 'function)

(defun org-elisp-link-export-formatter-get (backend)
  (or
   (cl-loop for (bkend . fun) in org-elisp-link-export-formatter-alist
            when (org-export-derived-backend-p backend bkend)
            return fun)
   org-elisp-link-export-formatter-default))

;;;;; Format with Template

(defun org-elisp-link-expand-template (template params)
  "Return the result of expanding TEMPLATE using PARAMS."
  (cond
   ;; Function
   ((functionp template)
    (funcall template params))
   ;; String
   ((stringp template)
    (let ((result "")
          (pos 0))
      ;; {{{ pname }}} => pvalue
      ;; {{{ pname : fmt }}} => (format fmt pvalue)
      (while (string-match "{{{\\([^:}]+\\)\\(?::\\([^}]+\\)\\)?}}}"
                           template pos)
        (let* ((pname (match-string 1 template))
               (fmt (match-string 2 template))
               (pvalue (org-elisp-link-export-param-get pname params))
               (fmted-pvalue
                (if pvalue
                    (if fmt (format fmt pvalue) pvalue)
                  "")))
          (setq result
                (concat
                 result
                 (substring template pos (match-beginning 0))
                 fmted-pvalue)))
        (setq pos (match-end 0)))
      (setq result (concat result (substring template pos)))
      result))))

(defun org-elisp-link-export-param-get (key params)
  "Return the value of the KEY parameter in PARAMS."
  (cdr
   (assoc key params)
   ;; (or (assoc key params)
   ;;     (assoc key org-elisp-link-export-default-params))
   ))

;;;;; Format Common

(defcustom org-elisp-link-export-default-contents-template
  "{{{SYMBOL}}}"
  "Default link content template used when exporting HTML.

If link has a description part, that will be the content of the
link. This template is not used.

Specifies a template string or function to be expanded by
`org-elisp-link-expand-template'.

The parameters that can be referenced are as follows.
- SYMBOL
- PATH
- ELEMENT-TYPE

The same setting is also possible with the
`ELISP_LINK_DEFAULT_CONTENTS' option. for example:
#+ELISP_LINK_DEFAULT_CONTENTS: {{{ELEMENT-TYPE}}} {{{SYMBOL}}}"
  :group 'org-elisp-link
  :type '(choice
          (string :tag "Template")
          (function :tag "Function (params)=>string")))

(defun org-elisp-link-export-expand-contents (path desc info element-type
                                                   symbol-name
                                                   params)
  (push (cons "PATH" path) params)
  (push (cons "ELEMENT-TYPE" (symbol-name element-type)) params)
  (push (cons "SYMBOL" symbol-name)
        params)

  ;; CONTENTS: {{{SYMBOL}}}
  (push (cons "CONTENTS"
              (or desc
                  (org-elisp-link-expand-template
                   (or (plist-get info :elisp-link-default-contents)
                       org-elisp-link-export-default-contents-template)
                   params)))
        params)
  params)

(defun org-elisp-link-export-format-as-plain (_url path desc info element-type
                                                   symbol _options)
  (let ((params (org-elisp-link-export-expand-contents
                 path desc info element-type (symbol-name symbol) nil)))
    (org-elisp-link-export-param-get "CONTENTS" params)))

;;;;; Format as HTML

(defcustom org-elisp-link-export-html-link-template
  "<a href=\"{{{URL}}}\">{{{CONTENTS}}}</a>"
  "
Specifies a template string or function to be expanded by
`org-elisp-link-expand-template'.

The parameters that can be referenced are as follows.
- CONTENTS
- SYMBOL
- PATH
- ELEMENT-TYPE

The same setting is also possible with the
`ELISP_LINK_HTML_LINK' option. for example:
#+ELISP_LINK_HTML_LINK: <a href=\"{{{URL}}}\">{{{CONTENTS}}}</a>"
  :group 'org-elisp-link
  :type '(choice
          (string :tag "Template")
          (function :tag "Function (params)=>string")))

(defcustom org-elisp-link-export-html-wrapper-template
  "<code>{{{LINK}}}</code>"
  "
Specifies a template string or function to be expanded by
`org-elisp-link-expand-template'.

The parameters that can be referenced are as follows.
- LINK
- CONTENTS
- SYMBOL
- PATH
- ELEMENT-TYPE

The same setting is also possible with the
`ELISP_LINK_HTML_WRAPPER' option. for example:
#+ELISP_LINK_HTML_WRAPPER: <span class=\"code\">{{{LINK}}}</span>"
  :group 'org-elisp-link
  :type '(choice
          (string :tag "Template")
          (function :tag "Function (params)=>string")))

(defcustom org-elisp-link-export-html-wrap-description nil
  "Non-nil means wrapping the link even when it has a description part."
  :group 'org-elisp-link
  :type 'boolean)


(defun org-elisp-link-export-html-encode-attribute-text (text)
  (replace-regexp-in-string
   "\"" "&quot;"
   (org-html-encode-plain-text text)))

(defun org-elisp-link-export-format-as-html (url path desc info element-type
                                                 symbol
                                                 _options)
  (let ((params (org-elisp-link-export-expand-contents
                 ;; Escape `&' `<' `>' `"'
                 (org-elisp-link-export-html-encode-attribute-text path)
                 ;; DESC has already been escaped
                 desc
                 info element-type
                 ;; Escape `&' `<' `>' `"'
                 (org-elisp-link-export-html-encode-attribute-text
                  (symbol-name symbol))
                 nil)))

    ;; LINK: <a href="{{{URL}}}">{{{CONTENTS}}}</a>
    (push (cons "LINK"
                (if url
                    (progn
                      (push (cons "URL" url) params)
                      (org-elisp-link-expand-template
                       (or (plist-get info :elisp-link-html-link)
                           org-elisp-link-export-html-link-template)
                       params))
                  (org-elisp-link-export-param-get "CONTENTS" params)))
          params)

    ;; WRAPPER: <code>{{{LINK}}}</code>
    (if (or org-elisp-link-export-html-wrap-description
            (null desc))
        (org-elisp-link-expand-template
         (or (plist-get info :elisp-link-html-wrapper)
             org-elisp-link-export-html-wrapper-template)
         params)
      (org-elisp-link-export-param-get "LINK" params))))


;;;;; Convert Symbol to Web URL

;; TEST
;; (org-elisp-link-function-web-url 'org-mode) => "https://git.savannah.gnu.org/cgit/emacs/org-mode.git/tree/lisp/org.el?id=58c91cbf9f2510700fbbdaaa166efcb1a5582cf7#n4789"
;; (org-elisp-link-function-web-url 'message) => "https://git.savannah.gnu.org/cgit/emacs.git/tree/src/editfns.c?h=emacs-29.1#n3172"
;; (org-elisp-link-function-web-url 'widget-create) => "https://git.savannah.gnu.org/cgit/emacs.git/tree/lisp/wid-edit.el?h=emacs-29.1#n832"
;; (org-elisp-link-function-web-url 'url-retrieve) => "https://git.savannah.gnu.org/cgit/emacs.git/tree/lisp/url/url.el?h=emacs-29.1#n126"
;; (org-elisp-link-function-web-url 'vertico-mode) => "https://github.com/minad/vertico/blob/93f709d71e8908617a21ca469fd60123f5037ae4/vertico.el#L741"
;; (org-elisp-link-variable-web-url 'truncate-lines) => "https://git.savannah.gnu.org/cgit/emacs.git/tree/src/buffer.c?h=emacs-29.1#n5314"
;; (org-elisp-link-face-web-url 'org-link) => "https://git.savannah.gnu.org/cgit/emacs/org-mode.git/tree/lisp/org-faces.el?id=58c91cbf9f2510700fbbdaaa166efcb1a5582cf7#n181"
;; (org-elisp-link-library-web-url 'dired) => "https://git.savannah.gnu.org/cgit/emacs.git/tree/lisp/dired.el?h=emacs-29.2"

;; To Web URL

(defun org-elisp-link-face-web-url (symbol &optional options)
  (org-elisp-link-element-web-url symbol
                                  #'org-elisp-link-find-face-noselect
                                  options))

(defun org-elisp-link-variable-web-url (symbol &optional options)
  (org-elisp-link-element-web-url symbol
                                  #'org-elisp-link-find-variable-noselect
                                  options))

(defun org-elisp-link-function-web-url (symbol &optional options)
  (org-elisp-link-element-web-url symbol
                                  #'org-elisp-link-find-function-noselect
                                  options))

(defun org-elisp-link-library-web-url (symbol &optional options)
  (org-elisp-link-element-web-url symbol
                                  #'org-elisp-link-find-library-file-line
                                  options))

;; Element To URL

(defun org-elisp-link-element-web-url (symbol finder &optional options)
  "Return the URL on the web pointing to the definition of SYMBOL.

The location of SYMBOL in the local file system is determined by
FINDER. See `org-elisp-link-element-file-line' for FINDER.

Options for converting to URL can be specified in OPTIONS."
  (when-let ((file-line (org-elisp-link-element-file-line symbol finder options)))
    (org-elisp-link-path-globalize (car file-line) (cdr file-line) options)))


;;;;; Path Globalization

;; Converts a path to a local file to a URL on the World Wide Web.

(defcustom org-elisp-link-path-globalizers
  '(org-elisp-link-path-globalize-emacs
    org-elisp-link-path-globalize-package)
  "A list of functions that convert file name and line number to
URL on the World Wide Web.

The function receives the local file name (absolute path), line
number (starting from 1), and option alist.

The option alist contains options specified by option part in
path or by `#+HTML_LINK_OPTIONS:'."
  :group 'org-link
  :type '(repeat (function)))

(defun org-elisp-link-path-globalize (file line &optional options)
  "Return a URL on the World Wide Web that points to the LINE of the FILE.

FILE is a path to a local file that has the same content on the WWW.

LINE is a line number starting from 1."
  (let ((abs-file (expand-file-name file)))
    (seq-some (lambda (globalizer) (funcall globalizer abs-file line options))
              org-elisp-link-path-globalizers)))


(defun org-elisp-link-path-globalize-emacs (abs-file line &optional options)
  "Create a URL to a file bundled with Emacs."
  (let ((dirs `((,lisp-directory
                 . "https://git.savannah.gnu.org/cgit/emacs.git/tree/lisp/")
                (,find-function-C-source-directory
                 . "https://git.savannah.gnu.org/cgit/emacs.git/tree/src/"))))
    (cl-loop for (dir . url) in dirs
             when (and dir (string-prefix-p (expand-file-name dir) abs-file))
             return
             (concat
              url
              (file-relative-name abs-file dir)
              "?h=emacs-"
              ;; Option: emacs-version <string>
              ;; Emacs version referenced in URL.
              ;; NOTE: Line numbers are determined based on the current version.
              (alist-get :emacs-version options emacs-version)
              (when line (format "#n%d" line))))))


(defvar org-elisp-link-path-globalize-package-globalizers
  '(org-elisp-link-path-globalize-package-org
    org-elisp-link-path-globalize-package-github))

(defun org-elisp-link-path-globalize-package (abs-file line &optional options)
  "Create a URL to the file managed by package.el."
  (when-let* ((pkg-name-desc (org-elisp-link-path-globalize-package-find abs-file))
              (pkg-name (car pkg-name-desc))
              (pkg-desc (cdr pkg-name-desc))
              (pkg-dir (package-desc-dir pkg-desc))
              (rel-file (file-relative-name abs-file pkg-dir)))
    (seq-some (lambda (globalizer)
                (funcall globalizer rel-file line pkg-name pkg-desc options))
              org-elisp-link-path-globalize-package-globalizers)))

(defun org-elisp-link-path-globalize-package-find (abs-file)
  ;; TODO: package-user-dirで足切りする？ package-directory-listも？
  (cl-loop for (name . descs) in package-alist
           for desc = (cl-loop for desc in descs
                               for dir = (package-desc-dir desc)
                               when (and dir
                                         (string-prefix-p
                                          (expand-file-name dir) abs-file))
                               return desc)
           when desc
           return (cons name desc)))

(defun org-elisp-link-path-globalize-package-org (rel-file line pkg-name pkg-desc &optional _options)
  (when (eq pkg-name 'org)
    (when-let* ((pkg-extras (package-desc-extras pkg-desc))
                (pkg-commit (alist-get :commit pkg-extras)))
      (concat
       "https://git.savannah.gnu.org/cgit/emacs/org-mode.git/tree/lisp/"
       rel-file
       "?id=" pkg-commit
       (when line (format "#n%d" line))))))

(defun org-elisp-link-path-globalize-package-github (rel-file line _pkg-name pkg-desc &optional _options)
  (when-let* ((pkg-extras (package-desc-extras pkg-desc))
              (pkg-url (alist-get :url pkg-extras))
              (pkg-commit (alist-get :commit pkg-extras)))
    (when (string-match "\\(https?://github\\.com/[^/]+/[^/]+\\)" pkg-url)
      (concat
       (match-string 1 pkg-url) "/blob/" pkg-commit "/" rel-file
       (when line (format "#L%d" line))))))

;;;;; Export Options

;; Enables options starting with #+ELISP_LINK_.

(defvar org-elisp-link-export-common-options
  '((:elisp-link-default-contents
     "ELISP_LINK_DEFAULT_CONTENTS"
     nil org-elisp-link-export-default-contents-template t)
    (:elisp-link-options
     "ELISP_LINK_OPTIONS"
     nil "" space)))

(defvar org-elisp-link-export-html-options
  '((:elisp-link-html-link
     "ELISP_LINK_HTML_LINK"
     nil org-elisp-link-export-html-link-template t)
    (:elisp-link-html-wrapper
     "ELISP_LINK_HTML_WRAPPER"
     nil org-elisp-link-export-html-wrapper-template t)))

(defun org-elisp-link-export-set-options-alist (old-options-alist
                                                new-options-alist)
  (let ((new-option-names (mapcar #'car new-options-alist)))
    (nconc
     ;; Remove as much as possible.
     ;; If the name changes, it cannot be removed.
     (seq-remove (lambda (elem) (memq (car elem) new-option-names))
                 old-options-alist)
     ;; Concatenate new
     new-options-alist)))

(defun org-elisp-link-export-install-options-to-backend (backend-name
                                                         options-alist)
  (let ((backend (org-export-get-backend backend-name)))
    ;; Add options-alist to backend's options
    (setf (org-export-backend-options backend)
          (org-elisp-link-export-set-options-alist
           (org-export-backend-options backend)
           options-alist))))

(defun org-elisp-link-export-install-options ()
  (defvar org-export-options-alist)
  (with-eval-after-load "ox"
    (setf org-export-options-alist
          (org-elisp-link-export-set-options-alist
           org-export-options-alist
           org-elisp-link-export-common-options)))
  (with-eval-after-load "ox-html"
    (org-elisp-link-export-install-options-to-backend
     'html
     org-elisp-link-export-html-options)))

;; NOTE:
;; The following must be evaluated after the required variables have
;; already been defined.
(org-elisp-link-export-install-options)

;; #+ELISP_LINK_OPTIONS: :key1 value1 :key2 value2 ...

(defun org-elisp-link-export-get-options (info)
  "Parse #+ELISP_LINK_OPTIONS:."
  (org-elisp-link-export-parse-options
   (or (plist-get info :elisp-link-options) "")))

(defun org-elisp-link-export-parse-options (options-str)
  (let ((pos 0)
        (value-begin 0)
        key
        result)
    (while pos
      (string-match "\\(?:\\(?:\\`\\|[ \t\r\n]+\\)\\(:[-_a-zA-Z0-9]+\\)\\([ \t\r\n]+\\|\\'\\)\\|[ \t\r\n]*\\'\\)" options-str pos)
      (when key
        (push (cons (intern key)
                    (substring options-str
                               value-begin
                               (max value-begin (match-beginning 0))))
              result))
      (setq key (match-string 1 options-str)
            value-begin (match-end 0)
            pos (if key (match-end 1) nil)))
    (nreverse result)))

;;;; Store

;; TODO: Use `find-function-regexp-alist' ?
(defconst org-elisp-link-definition-types
  '((function . ("defun" "defmacro" "defsubst"
                 "cl-defun" "cl-defgeneric" "cl-defmethod"
                 "define-skeleton" "define-generic-mode" "define-derived-mode"
                 "define-minor-mode" "define-global-minor-mode"))
    (variable . ("defvar" "defconst" "defcustom"))
    (face . ("defface"))))

(defun org-elisp-link-definition-type (def-key)
  (cl-loop for (element-type . keys) in org-elisp-link-definition-types
           when (member def-key keys)
           return element-type))

(defun org-elisp-link-which-definition ()
  (ignore-errors
    (save-excursion
      (when (equal (char-after) ?\()
        (forward-char))
      (let ((pos (point)))
        (when (and (beginning-of-defun)
                   ;; inside of defun
                   (< pos
                      (or
                       (ignore-errors (save-excursion (end-of-defun) (point)))
                       (point-max))))
          ;; NOTE: Skip whitespaces and comments correctly.
          (down-list)
          (let* ((def-end (progn (forward-sexp) (point)))
                 (name-end (progn (forward-sexp) (point)))
                 (name-beg (progn (backward-sexp) (point)))
                 (def-beg (progn (backward-sexp) (point)))
                 (def (buffer-substring-no-properties def-beg def-end))
                 (element-type (org-elisp-link-definition-type def))
                 (name (buffer-substring-no-properties name-beg name-end)))
            (when (and element-type
                       (not (member (elt name 0) '(?\( ?\' ?\"))))
              (cons name element-type))))))))

(defcustom org-elisp-link-store-description-element-types nil
  "List of element types to generate description when storing."
  :group 'org-elisp-link
  :type `(checklist
          :format "%t:\n%v"
          :tag "Element Types"
          ,@(mapcar (lambda (element-type) `(const ,element-type))
                    org-elisp-link-element-types)))

;;;###autoload
(defun org-elisp-link-store ()
  "Store a link to the elisp element at the current point."
  (or (org-elisp-link-store-definitions)
      (org-elisp-link-store-library)))

;;;###autoload
(defun org-elisp-link-store-definitions ()
  "Store a link to the elisp definition at the current point."
  (when (derived-mode-p 'emacs-lisp-mode)
    (pcase (org-elisp-link-which-definition)
      ;; Function, Variable, Face
      (`(,name . ,element-type)
       (let* ((link-type (org-elisp-link-type-name element-type))
              (link (concat link-type ":" name)))
         (org-link-store-props
          :type link-type
          :link link
          :description (and (memq
                             element-type
                             org-elisp-link-store-description-element-types)
                            name)
          :element-type element-type))))))

;;;###autoload
(defun org-elisp-link-store-library ()
  "Store a link to the current elisp library."
  (when (derived-mode-p 'emacs-lisp-mode)
    (when-let* ((filename (buffer-file-name))
                (basename (file-name-base filename))
                (libloc (find-library-name basename)))
      (when (string= (expand-file-name libloc)
                     (expand-file-name filename))
        (org-link-store-props
         :type org-elisp-link-type-library
         :link (concat org-elisp-link-type-library ":" basename)
         :description (and (memq
                            'library
                            org-elisp-link-store-description-element-types)
                           (concat basename ".el"))
         :element-type 'library)))))


;;;; Activate Function

;; Hides the protocol and options parts of the link.

(defcustom org-elisp-link-hide-except-symbol t
  "Non-nil means only the symbol name is displayed when there is
 no description. Hides the protocol and option parts."
  :group 'org-elisp-link
  :type 'boolean)

;;;###autoload
(defun org-elisp-link-activate-hide-except-symbol (start end path bracket-p)
  (when (and bracket-p
             org-elisp-link-hide-except-symbol)
    (save-excursion
      (goto-char start)
      (save-match-data
        (when (looking-at "[^]:]*:")
          (let* ((protocol-end (match-end 0))
                 (symbol-end (+ protocol-end
                                (length
                                 (org-elisp-link-path-to-symbol-name path)))))
            (unless (eq (get-text-property protocol-end 'invisible) 'org-link) ;; already invisible?
              (put-text-property start protocol-end 'invisible 'org-link)
              (put-text-property symbol-end end 'invisible 'org-link))))))))


;;;; Completing Read from Minibuffer

;;;###autoload
(defun org-elisp-link-read-library-name (&optional _arg)
  (let ((path (read-library-name)))
    (concat org-elisp-link-type-library ":" path)))

;;;###autoload
(defun org-elisp-link-read-function-name (&optional _arg)
  (let* ((default (function-called-at-point))
         (default (and default (symbol-name default)))
         (path (completing-read
                (format-prompt "Function" default)
                (if (fboundp 'help--symbol-completion-table)
                    'help--symbol-completion-table
                  obarray)
                (lambda (f) (or (fboundp f) (get f 'function-documentation)))
                'confirm nil nil default)))
    (concat org-elisp-link-type-function ":" path)))

;;;###autoload
(defun org-elisp-link-read-variable-name (&optional _arg)
  (let* ((default (variable-at-point))
         (default (and (symbolp default) (symbol-name default)))
         (buffer (current-buffer))
         (path (completing-read
                (format-prompt "Variable" default)
                (if (fboundp 'help--symbol-completion-table)
                    'help--symbol-completion-table
                  obarray)
                (lambda (v)
                  (or (get v 'variable-documentation)
                      (and (not (keywordp v))
                           (buffer-local-boundp v buffer))))
                'confirm nil nil default)))
    (concat org-elisp-link-type-variable ":" path)))

;;;###autoload
(defun org-elisp-link-read-face-name (&optional _arg)
  (let ((path (symbol-name
               (read-face-name
                "Describe face"
                (or (face-at-point t) 'default) nil))))
    (concat org-elisp-link-type-face ":" path)))


;;;; Completion Table

(defvar org-elisp-link-library-files-cache nil)

(defun org-elisp-link-library-files-hash ()
  (let* ((dirs (or find-library-source-path load-path))
         (suffixes (find-library-suffixes))
         (cache-context (list dirs suffixes)))
    ;; (locate-file-completion-table dirs suffixes string predicate action)))

    ;; TODO: Ccan't notice changes in the number of files in a directory.
    ;;       Compare time?
    (if (and org-elisp-link-library-files-cache
             (equal (car org-elisp-link-library-files-cache) cache-context))
        (cdr org-elisp-link-library-files-cache)
      (let ((regexp (concat "\\`\\(.+\\)\\("
                            (mapconcat #'regexp-quote suffixes "\\|")
                            "\\)\\'"))
            (hash (make-hash-table :test #'equal)))
        (dolist (dir dirs)
          (dolist (file (directory-files dir))
            (when (string-match regexp file)
              (let ((library (match-string 1 file)))
                (unless (gethash library hash)
                  (puthash library t hash))))))
        (setq org-elisp-link-library-files-cache
              (cons (copy-tree cache-context)
                    hash))
        hash))))

;;;###autoload
(defun org-elisp-link-completion-table-library (string predicate action)
  (complete-with-action
   action
   (org-elisp-link-library-files-hash)
   string
   predicate))

;;;###autoload
(defun org-elisp-link-completion-table-function (string predicate action)
  (complete-with-action
   action
   ;;'help--symbol-completion-table
   ;;(elisp--completion-local-symbols)
   obarray
   string
   (lambda (sym)
     (and (if predicate (funcall predicate sym) t)
          (or (fboundp sym) (get sym 'function-documentation))))))

;;;###autoload
(defun org-elisp-link-completion-table-variable (string predicate action)
  (complete-with-action
   action
   ;;'help--symbol-completion-table
   ;;(elisp--completion-local-symbols)
   obarray
   string
   (lambda (sym)
     (and (if predicate (funcall predicate sym) t)
          (or (get sym 'variable-documentation)
              (and (not (keywordp sym))
                   (boundp sym)))))))

;;;###autoload
(defun org-elisp-link-completion-table-face (string predicate action)
  (complete-with-action
   action
   ;;'help--symbol-completion-table
   ;;(elisp--completion-local-symbols)
   obarray
   string
   (lambda (sym)
     (and (if predicate (funcall predicate sym) t)
          (facep sym)))))


;;;; Completion At Point Function

;; Complete path/description of link at point in org-mode.

(defvar org-elisp-link-capf-pos nil
  "Temporarily hold the result of `org-elisp-link-capf-path-parse'
 or `org-elisp-link-capf-desc-parse' function.

A list in the following format:
(TYPE-BEG TYPE-END PATH-BEG PATH-END [ DESC-BEG DESC-END ])")

(defun org-elisp-link-completion-at-point ()
  "Complete the path or description part of link in org-mode.

When point is over a link, call one of functions set to the
following properties of `org-link-parameters'.

- `:capf-path' : [[<link-type>:<path>(When point is here)
- `:capf-desc' : [[<link-type>:<path>][<description>(When point is here)
- `:completino-at-point' : If the above two properties are not present.

No arguments are passed to the function. However, before it is
called, the variable `org-elisp-link-capf-pos' is set with
information about the link to be completed.

The function set to the `:completion-at-point' property must be
processed by determining whether it is the path part or the
description part.

The function must return the same value as the function added to
`completion-at-point-functions'.

To use this, do the following in org-mode buffer:
(add-hook \\='completion-at-point-functions
          #\\='org-elisp-link-completion-at-point nil t)"
  (when-let ((org-elisp-link-capf-pos (or (org-elisp-link-capf-desc-parse)
                                          (org-elisp-link-capf-path-parse))))
    (let* ((type-beg (nth 0 org-elisp-link-capf-pos))
           (type-end (nth 1 org-elisp-link-capf-pos))
           (type (buffer-substring-no-properties type-beg type-end))
           (desc-beg (nth 4 org-elisp-link-capf-pos))
           (capf-prop (if desc-beg :capf-desc :capf-path))
           (capf (or (org-link-get-parameter type capf-prop)
                     (org-link-get-parameter type :completion-at-point))))
      ;;(message "capf=%s" capf)
      (when capf
        (funcall capf)))))

;;;;; Complete Path

(defun org-elisp-link-capf-path-parse ()
  "Return (type-beg type-end path-beg path-end) of link at point.

( [[<type>:<path>(point is in <path>) )"
  (save-excursion
    (let ((origin (point))
          path-beg path-end
          type-beg type-end)
      (when (and (skip-chars-backward "^:\n \t[") ;; TODO: Skip escape sequence
                 (eq (char-before) ?:)
                 (setq path-beg (point))
                 (goto-char (1- (point)))
                 (setq type-end (point))
                 (skip-chars-backward "-A-Za-z0-9_+")
                 (eq (char-before) ?\[)
	         (eq (char-before (1- (point))) ?\[)
                 (setq type-beg (point)))
        (goto-char origin)
        (skip-chars-forward "^]\n \t")
        (setq path-end (point))
        (list type-beg type-end path-beg path-end)))))

(defun org-elisp-link-capf-path-file ()
  "Complete <filename> of [[<link-type>:<filename> at point.

This function also works for `file+sys:' and `file+emacs:' link types.

To use this, do:
(org-link-set-parameters \"file\"
                         :capf-path #\\='org-elisp-link-capf-path-file)
(org-link-set-parameters \"file+sys\"
                         :capf-path #\\='org-elisp-link-capf-path-file)
(org-link-set-parameters \"file+emacs\"
                         :capf-path #\\='org-elisp-link-capf-path-file)

This function is completely outside the scope of this Emacs Lisp
file. This is an implementation for reference."
  (when-let ((pos (or org-elisp-link-capf-pos
                      (org-elisp-link-capf-path-parse))))
    (let ((path-beg (nth 2 pos))
          (path-end (nth 3 pos)))
      (list
       path-beg path-end
       #'read-file-name-internal
       :annotation-function
       (lambda (str) (if (string-suffix-p "/" str) " Dir" " File"))
       :company-kind
       (lambda (str) (if (string-suffix-p "/" str) 'folder 'file))
       :exclusive 'no))))

(defun org-elisp-link-capf-desc-file ()
  "Complete <filename> of [[<link-type>:<filename>][<description> at point."
  (when-let ((pos (or org-elisp-link-capf-pos
                      (org-elisp-link-capf-desc-parse))))
    (let* ((path-beg (nth 2 pos))
           (path-end (nth 3 pos))
           (desc-beg (nth 4 pos))
           (desc-end (nth 5 pos))
           (path (buffer-substring-no-properties path-beg path-end))
           (desc (and desc-beg
                      (buffer-substring-no-properties desc-beg desc-end))))
      (when (and desc (string-prefix-p desc path))
        (list
         desc-beg desc-end
         (list path)
         :company-kind (lambda (_) 'file))))))

(defun org-elisp-link-capf-path-library ()
  "Complete <library> of [[<link-type>:<library> at point."
  (when-let ((pos (or org-elisp-link-capf-pos (org-elisp-link-capf-path-parse))))
    (let ((path-beg (nth 2 pos))
          (path-end (nth 3 pos)))
      (list
       path-beg path-end
       (org-elisp-link-library-files-hash)
       :company-kind (lambda (_) 'module)
       :company-doc-buffer #'elisp--company-doc-buffer
       :company-docsig #'elisp--company-doc-string
       :company-location #'elisp--company-location
       :company-deprecated #'elisp--company-deprecated))))

(defun org-elisp-link-capf-path--symbol (predicate kind)
  "Complete <symbol> of [[<link-type>:<symbol> at point."
  (when-let ((pos (or org-elisp-link-capf-pos (org-elisp-link-capf-path-parse))))
    (let ((path-beg (nth 2 pos))
          (path-end (nth 3 pos)))
      (list
       path-beg path-end
       (elisp--completion-local-symbols)
       :predicate
       predicate
       :company-kind kind
       :company-doc-buffer #'elisp--company-doc-buffer
       :company-docsig #'elisp--company-doc-string
       :company-location #'elisp--company-location
       :company-deprecated #'elisp--company-deprecated))))

;;;###autoload
(defun org-elisp-link-capf-path-function ()
  "Complete <function> of [[<link-type>:<function> at point."
  (org-elisp-link-capf-path--symbol
   (lambda (sym)
     (when-let ((sym (intern-soft (symbol-name sym))))
       (or (fboundp sym)
           (get sym 'function-documentation))))
   #'elisp--company-kind))

;;;###autoload
(defun org-elisp-link-capf-path-variable ()
  "Complete <variable> of [[<link-type>:<variable> at point."
  (org-elisp-link-capf-path--symbol
   (lambda (sym)
     (when-let ((sym (intern-soft (symbol-name sym))))
       (or (get sym 'variable-documentation)
           (and (not (keywordp sym))
                (boundp sym)))))
   (lambda (_sym) 'variable)))

;;;###autoload
(defun org-elisp-link-capf-path-face ()
  "Complete <face> of [[<link-type>:<face> at point."
  (org-elisp-link-capf-path--symbol
   (lambda (sym)
     (when-let ((sym (intern-soft (symbol-name sym))))
       (facep sym)))
   (lambda (_sym) 'color)))

;;;;; Complete Description

(defun org-elisp-link-capf-desc-parse ()
  "Return (type-beg type-end path-beg path-end desc-beg desc-endf)
of link at point.

( [[<type>:<path>][<desc>(point is in <desc>) )"
  (save-excursion
    (let ((origin (point))
          desc-beg desc-end)
      (when (and (skip-chars-backward "^\n\t][")
                 (eq (char-before) ?\[)
                 (eq (char-before (1- (point))) ?\]))
        (setq desc-beg (point))
        (goto-char (- (point) 2))
        (when-let ((pos (org-elisp-link-capf-path-parse)))
          (goto-char origin)
          (skip-chars-forward "^\n\t]")
          (setq desc-end (point))
          (nconc pos (list desc-beg desc-end)))))))

(defun org-elisp-link-capf-desc--symbol-name (kind)
  (when-let ((pos (or org-elisp-link-capf-pos
                      (org-elisp-link-capf-desc-parse))))
    (let* ((path-beg (nth 2 pos))
           (path-end (nth 3 pos))
           (desc-beg (nth 4 pos))
           (desc-end (nth 5 pos))
           (path (buffer-substring-no-properties path-beg path-end))
           (name (org-elisp-link-path-to-symbol-name path)))
      (list
       desc-beg desc-end
       (list name)
       :company-kind kind
       :company-doc-buffer #'elisp--company-doc-buffer
       :company-docsig #'elisp--company-doc-string
       :company-location #'elisp--company-location
       :company-deprecated #'elisp--company-deprecated))))

(defun org-elisp-link-capf-desc-library ()
  (org-elisp-link-capf-desc--symbol-name (lambda (_) 'module)))

(defun org-elisp-link-capf-desc-function ()
  (org-elisp-link-capf-desc--symbol-name #'elisp--company-kind))

(defun org-elisp-link-capf-desc-variable ()
  (org-elisp-link-capf-desc--symbol-name (lambda (_) 'variable)))

(defun org-elisp-link-capf-desc-face ()
  (org-elisp-link-capf-desc--symbol-name (lambda (_) 'color)))



(provide 'org-elisp-link)
;;; org-elisp-link.el ends here

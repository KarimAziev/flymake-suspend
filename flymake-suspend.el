;;; flymake-suspend.el --- Temporarly inhibit flymake backends -*- lexical-binding: t; -*-

;; Copyright (C) 2023 Karim Aziiev <karim.aziiev@gmail.com>

;; URL: https://github.com/KarimAziev/flymake-suspend
;; Version: 0.1.0
;; Keywords: lisp convenience
;; Author: Karim Aziiev <karim.aziiev@gmail.com>
;; Package-Requires: ((emacs "25.1"))
;; SPDX-License-Identifier: GPL-3.0-or-later

;; This file is NOT part of GNU Emacs.

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 3, or (at your option)
;; any later version.
;;
;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:

;; Temporarly inhibit flymake backends

;;; Code:



(defcustom flymake-suspend-command-disablers-alist '((narrow-to-region
                                                      flymake-suspend-inhibit-backends
                                                      package-lint-flymake
                                                      elisp-flymake-checkdoc)
                                                     (el-narrow-dwim
                                                      flymake-suspend-inhibit-backends
                                                      package-lint-flymake
                                                      elisp-flymake-checkdoc)
                                                     (narrow-to-defun
                                                      flymake-suspend-inhibit-backends
                                                      package-lint-flymake
                                                      elisp-flymake-checkdoc)
                                                     (widen
                                                      flymake-suspend-restore-backends))
  "Alist of commands and corresponding handlers with args.
Every element is a cons which car is command symbol, and cdr it is a list,
where first element is a function and rest of the elements - the arguments."
  :group 'flymake
  :type '(alist
          :key-type (symbol :tag "Command")
          :value-type
          (list
           (symbol :tag "Hanlder")
           (repeat
            :inline t
            :tag "Arguments" (sexp :tag "Arguments")))))

(defvar-local flymake-suspend-suspended-backends nil)



(defun flymake-suspend-inhibit-backends (&rest backends)
  "Suspend flymake BACKENDS and put them to `flymake-suspend-suspended-backends'."
  (when-let* ((inhibited-backends (and
                                  (bound-and-true-p flymake-mode)
                                  (seq-intersection flymake-diagnostic-functions
                                                    backends))))
    (flymake-mode -1)
    (dolist (backend inhibited-backends)
      (remove-hook 'flymake-diagnostic-functions backend t)
      (push backend flymake-suspend-suspended-backends))
    (flymake-mode 1)))

(defun flymake-suspend-restore-backends ()
  "Restore backends defined in `flymake-suspend-suspended-backends'."
  (when (and (bound-and-true-p flymake-mode)
             flymake-suspend-suspended-backends)
    (flymake-mode -1)
    (let ((backend))
      (while (setq backend (pop flymake-suspend-suspended-backends))
        (add-hook 'flymake-diagnostic-functions backend nil t))
      (flymake-mode 1))))


(defun flymake-suspend-post-command-worker ()
  "Invoke command handler for `this-command'.
If `this-command' is is eq to the car of an element of
`flymake-suspend-command-disablers-alist', it will be called the
corresponding handler."
  (when-let* ((cell (assq this-command
                         flymake-suspend-command-disablers-alist)))
    (let ((worker (cadr cell))
          (args (cddr cell)))
      (apply worker args))))

;;;###autoload
(define-minor-mode flymake-suspend-mode
  "Temporarly inhibit flymake backends after some commands.
This commands is specified in `flymake-suspend-command-disablers-alist'."
  :lighter " "
  :global nil
  (if flymake-suspend-mode
      (add-hook 'post-command-hook #'flymake-suspend-post-command-worker
                nil t)
    (remove-hook 'post-command-hook #'flymake-suspend-post-command-worker 'local)))

(provide 'flymake-suspend)
;;; flymake-suspend.el ends here
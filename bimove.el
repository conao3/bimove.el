;;; bimove.el --- Move cursor using binary serch  -*- lexical-binding: t; -*-

;; Copyright (C) 2024  Naoya Yamashita

;; Author: Naoya Yamashita <conao3@gmail.com>
;; Version: 0.0.1
;; Keywords: convenience
;; Package-Requires: ((emacs "30.1"))
;; URL: https://github.com/conao3/bimove.el

;; This program is free software: you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:

;; Move cursor using binary serch.


;;; Code:

(defgroup bimove nil
  "Move cursor using binary serch."
  :group 'convenience
  :link '(url-link :tag "Github" "https://github.com/conao3/bimove.el"))

(defface bimove-high-face
  '((t :background "#BADFDB" :extend t))
  "Face for high range."
  :group 'bimove)

(defface bimove-mid-face
  '((t :background "#FCF9EA" :extend t))
  "Face for mid line."
  :group 'bimove)

(defface bimove-low-face
  '((t :background "#FFA4A4" :extend t))
  "Face for low range."
  :group 'bimove)

(declare bimove-mode)
(defvar-local bimove--line-high -1)
(defvar-local bimove--line-mid -1)
(defvar-local bimove--line-low -1)

(defun bimove--add-overlay (beg end face)
  "Add BEG to END line FACE overlay."
  (save-excursion
    (let* ((beg-pos (progn (goto-line beg) (line-beginning-position)))
           (end-pos (progn (goto-line end) (1+ (line-end-position))))
           (ov (make-overlay beg-pos end-pos)))
      (overlay-put ov 'bimove t)
      (overlay-put ov 'face face)
      ov)))

(defun bimove--add-highlight ()
  "Add overlay."
  (bimove--add-overlay bimove--line-high (1- bimove--line-mid) 'bimove-high-face)
  (bimove--add-overlay bimove--line-mid bimove--line-mid 'bimove-mid-face)
  (bimove--add-overlay (1+ bimove--line-mid) bimove--line-low 'bimove-low-face))

(defun bimove--remove-highlight ()
  "Remove overlay."
  (dolist (ov (overlays-in (point-min) (point-max)))
    (when (overlay-get ov 'bimove)
      (delete-overlay ov))))

(defun bimove--setup ()
  "Setup bimove state."
  (setq bimove--line-high (line-number-at-pos (window-start)))
  (setq bimove--line-low (line-number-at-pos (window-end)))
  (setq bimove--line-mid (/ (+ bimove--line-high bimove--line-low) 2))
  (bimove--remove-highlight)
  (bimove--add-highlight)
  (goto-line bimove--line-mid))

(defun bimove--teardown ()
  "Teardown bimove state."
  (bimove--remove-highlight)
  (setq bimove--line-high -1)
  (setq bimove--line-low -1)
  (setq bimove--line-mid -1))

(defun bimove--move (&optional lowerp)
  "Move to high if LOWERP or to low."
  (if lowerp
      (setq bimove--line-high bimove--line-mid)
    (setq bimove--line-low bimove--line-mid))
  (setq bimove--line-mid (/ (+ bimove--line-high bimove--line-low) 2))
  (goto-line bimove--line-mid)
  (bimove--remove-highlight)
  (bimove--add-highlight))

(defun bimove-high ()
  "Move to high."
  (interactive)
  (cl-assert bimove-mode nil "`bimove-mode' is disabled")
  (bimove--move))

(defun bimove-low ()
  "Move to low."
  (interactive)
  (cl-assert bimove-mode nil "`bimove-mode' is disabled")
  (bimove--move 'lowerp))

(defun bimove-quit ()
  "Quit `bimove-mode'."
  (interactive)
  (cl-assert bimove-mode nil "`bimove-mode' is disabled")
  (bimove-mode -1))

(defvar bimove-mode-map
  (let ((map (make-sparse-keymap)))
    (set-keymap-parent map special-mode-map)
    (keymap-unset map "<")
    (keymap-unset map ">")
    (keymap-unset map "DEL")
    (keymap-unset map "SPC")
    (keymap-unset map "S-SPC")
    (keymap-set map "p" #'bimove-high)
    (keymap-set map "n" #'bimove-low)
    (keymap-set map "q" #'bimove-quit)
    (keymap-set map "RET" #'bimove-quit)
    map)
  "Keymap for `bimove-mode'.")

;;;###autoload
(define-minor-mode bimove-mode
  "Enable `bimove-mode'."
  :init-value nil
  :lighter " Bimove"
  :keymap bimove-mode-map
  (if bimove-mode
      (bimove--setup)
    (bimove--teardown)))

(provide 'bimove)

;;; bimove.el ends here

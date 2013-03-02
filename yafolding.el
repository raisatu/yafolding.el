;;; yafolding.el --- Yet another folding extension for Emacs

;; Copyright (C) 2013  Zeno Zeng

;; Author: Zeno Zeng <zenoes@qq.com>
;; Keywords: 

;; This program is free software; you can redistribute it and/or modify
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

;; Folding code blocks based on indeneation

;;; Code:

;;;###autoload
(defun yafolding ()
  "floding based on indeneation"
  (interactive)
  (defun get-overlay ()
    (save-excursion
      (goto-char (line-end-position))
      (let ((overlay (car (overlays-at (- (point) 1)))))
	(if (and
	     overlay
	     (member "zeno-folding" (overlay-properties overlay)))
	    overlay))))

  (defun get-first-line-data()
    (save-excursion
      (while (and
	      (line-string-match-p "^[ \t]*$")
	      (next-line-exists-p))
	(my-next-line))
      (if (line-string-match-p "^[ {\t]*$")
	  (setq first-line-data "{"))
      (if (line-string-match-p "^[ \\(\t]*$")
	  (setq first-line-data "("))
      ))

  (defun get-last-line-data()
    (save-excursion
      (while (and
	      (line-string-match-p "^[ \t]*$")
	      (previous-line-exists-p))
	(previous-line))
      (if (line-string-match-p "^[ }\t]*$")
	  (setq last-line-data "}"))
      (if (line-string-match-p "^[ \\)\t]*$")
	  (setq last-line-data ")"))
      ))

  (defun show ()
    (save-excursion
      (delete-overlay (get-overlay))))

  (defun hide ()
    (save-excursion
      (let* ((parent-level (get-column))
	     (beg (line-end-position))
	     (end beg)
	     (first-line-data)
	     (last-line-data))
	(my-next-line)
	(get-first-line-data)
	(when (is-child)
	  (while (and (is-child)
		      (search-forward "\n" nil t nil)))
	  (unless (is-child)
	    (previous-line))
	  (setq end (line-end-position))
	  (get-last-line-data)

	  ;; 若仅仅为空行，则不处理
	  (if (string-match-p "[^ \t\n\r]+" (buffer-substring beg end))
	      (let ((new-overlay (make-overlay beg end)))
		(overlay-put new-overlay 'invisible t)
		(overlay-put new-overlay 'intangible t)
		(overlay-put new-overlay 'category "zeno-folding")

		;; for emacs-lisp-mode
		(if (and
		     (equal major-mode 'emacs-lisp-mode)
		     (not last-line-data))
		    (setq last-line-data ")"))

		(if first-line-data
		    (overlay-put new-overlay 'before-string
				 (concat first-line-data "..."))
		  (overlay-put new-overlay 'before-string "..."))
		(if last-line-data
		    (overlay-put new-overlay 'after-string last-line-data))))))))

  (defun get-column()
    (back-to-indentation)
    (current-column))

  (defun line-string-match-p(regexp)
    (string-match-p regexp
		    (buffer-substring-no-properties
		     (line-beginning-position)
		     (line-end-position))))

  (defun next-line-exists-p()
    (save-excursion
      (search-forward "\n" nil t nil)))

  (defun previous-line-exists-p()
    (save-excursion
      (search-backward "\n" nil t nil)))

  (defun is-child()
    (or (> (get-column) parent-level)
	(line-string-match-p "^[ {}\t]*$")))

  (defun my-next-line()
    (search-forward "\n" nil t nil))

  (if (get-overlay)
      (if (line-string-match-p "^[ \t]*$") ; make sure we are still at the same line
	  (progn
	    (message "at t")
	    (backward-char)
	    (show)
	    (forward-char)
	    )
	(show))
    (if (line-string-match-p "[^ \t]+")
	(hide))))


;;;###autoload
(defun yafolding-hide-all(level)
  (interactive "nLevel:")
  (defun line-string-match-p(regexp)
    (string-match-p regexp
		    (buffer-substring-no-properties
		     (line-beginning-position)
		     (line-end-position))))
  (defun get-column()
    (back-to-indentation)
    (current-column))
  (defun get-level()
    (defun iter()
      (if (<= (get-column) (car levels))
	  (progn
	    (pop levels)
	    (iter))
	(progn
	  (push (get-column) levels)
	  (length levels))))
    (if (= 0 (get-column))
	(progn
	  (setq levels '(0))
	  1)
      (iter)))
  
  (yafolding-show-all)
  ;; level => column
  (goto-char (point-min))
  (let ((levels '(0)))
    (while (search-forward "\n" nil t nil)
      (unless (line-string-match-p "^[ \t]$")
	(forward-char) ; 防止停留在overlay的最后导致重复toggle
	(when (= (get-level) level)
	  (yafolding))))))

;;;###autoload
(defun yafolding-show-all()
  (interactive)
  (let ((overlays (overlays-in (point-min) (point-max)))
	(overlay))
    (while (car overlays)
      (setq overlay (pop overlays))
      (if (member "zeno-folding" (overlay-properties overlay))
	  (delete-overlay overlay)))))



(provide 'yafolding)
;;; yafolding.el ends here

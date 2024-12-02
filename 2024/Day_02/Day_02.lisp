;;;; Day02.lisp
;;;; 2024 AOC Day 02 solution
;;;; Common Lisp solutions by Leo Laporte (with lots of help)
;;;; Started: 1 Dec 2024 9p
;;;; Finished:1 Dec 2024 9:52

;; ----------------------------------------------------------------------------
;; Prologue code for setup - same every day
;; ----------------------------------------------------------------------------

(ql:quickload '(:fiveam :iterate :cl-ppcre :trivia :serapeum :str))
(use-package :iterate) ; use iter instead of LOOP

(defpackage :day02
  (:use  #:cl :iterate)
  (:local-nicknames
   (:re :cl-ppcre)       ; regex
   (:sr :serapeum)       ; utilities
   (:tr :trivia)         ; pattern matching
   (:5a :fiveam)))       ; testing framework

(in-package :day02)

(setf 5a:*run-test-when-defined* t)  ; test as we go
(declaim (optimize (debug 3)))       ; max debugging info
;; (declaim (optimize (speed 3))     ; max speed if needed

(defparameter *data-file* "~/common-lisp/AOC/2024/Day_02/input.txt"
  "Downloaded from the AoC problem set")

#| ----------------------------------------------------------------------------
--- Part One ---

"a report only counts as safe if both of the following are true:

The levels are either all increasing or all decreasing.

Any two adjacent levels differ by at least one and at most three.

How many reports are safe?"

---------------------------------------------------------------------------- |#

(defparameter *example*
  '("7 6 4 2 1"
    "1 2 7 8 9"
    "9 7 6 2 1"
    "1 3 2 4 5"
    "8 6 4 4 1"
    "1 3 6 7 9"))

(defun parse-reports (los)
  "reads a list of strings, each containing a set of number strings,
 and returns a list of number lists"
  (let ((reports '()))
    (dolist (str los)
      (push (mapcar #'parse-integer (re:split "\\s+" str)) reports))
    (reverse reports)))

(defun safe-report? (lon)
  "returns true if the list of numbers is either increasing or decreasing and always between one and three numbers"
  (let ((direction (if (> (first lon) (second lon)) 'down 'up)))
    (iter (for (x y) on lon by #'cdr)
      (when (null y) (return-from safe-report? t))
      (when (not (equal direction (if (> x y) 'down 'up)))
        (return-from safe-report? nil))
      (when (not (< 0 (abs (- x y)) 4))
        (return-from safe-report?  nil))))
  t)

(5a:test safe-report?-t
  (let ((rpts (parse-reports *example*)))
    (5a:is-true (safe-report? (first rpts)))
    (5a:is-true (safe-report? (second rpts)))
    (5a:is-true (safe-report? (third rpts)))
    (5a:is-false (safe-report? (fourth rpts)))
    (5a:is-false (safe-report? (fifth rpts)))
    (5a:is-true (safe-report? (sixth rpts)))))

(defun Day_02-1 (report)
  (let ((rpts (parse-reports report)))
    (iter (for r in rpts)
      (summing (if (safe-report? r) 1 0)))))

(5a:test Day_02-1-test
  (5a:is (= 2 (Day_02-1 *example*))))


#| ----------------------------------------------------------------------------
--- Part Two ---

"Now, the same rules apply as before, except if removing a single level
from an unsafe report would make it safe, the report instead counts as
safe."


---------------------------------------------------------------------------- |#

(defun remove-item (index list)
  "returns a list with the item at index removed"
  (concatenate 'list (subseq list 0 index) (subseq list (1+ index))))

(5a:test remove-item-t
  (5a:is (equalp '(0 1 2 3 4) (remove-item 0 '(0 0 1 2 3 4))))
  (5a:is (equalp '(0 1 2 3 4) (remove-item 1 '(0 0 1 2 3 4))))
  (5a:is (equalp '(0 0 2 3 4) (remove-item 2 '(0 0 1 2 3 4))))
  (5a:is (equalp '(0 0 1 3 4) (remove-item 3 '(0 0 1 2 3 4))))
  (5a:is (equalp '(0 0 1 2 4) (remove-item 4 '(0 0 1 2 3 4))))
  (5a:is (equalp '(0 0 1 2 3) (remove-item 5 '(0 0 1 2 3 4)))))

(defun relaxed-safe-report? (rpt)
  (when (safe-report? rpt)
    (return-from relaxed-safe-report? t))

  (iter (for i below (length rpt))
    (when (safe-report? (remove-item i rpt))
      (return-from relaxed-safe-report? t)))

  nil)

(defun Day_02-2 (reports)
  (let ((rpts (parse-reports reports)))
    (iter (for r in rpts)
      (summing (if (relaxed-safe-report? r) 1 0)))))

(5a:test Day_02-2-test
  (5a:is (= 4 (Day_02-2 *example*))))

;; now solve the puzzle!
(time (format t "The answer to AOC 2024 Day 02 Part 1 is ~a"
              (day_02-1 (uiop:read-file-lines *data-file*))))

(time (format t "The answer to AOC 2024 Day 02 Part 2 is ~a"
              (day_02-2 (uiop:read-file-lines *data-file*))))

;; ----------------------------------------------------------------------------
;; Timings with SBCL on an M4 Pro Mac mini with 64GB RAM
;; ----------------------------------------------------------------------------

;; The answer to AOC 2024 Day 02 Part 1 is 663
;; Evaluation took:
;; 0.001 seconds of real time
;; 0.001098 seconds of total run time (0.001034 user, 0.000064 system)
;; 100.00% CPU
;; 786,208 bytes consed

;; The answer to AOC 2024 Day 02 Part 2 is 692
;; Evaluation took:
;; 0.001 seconds of real time
;; 0.001249 seconds of total run time (0.001182 user, 0.000067 system)
;; 100.00% CPU
;; 1,048,352 bytes consed

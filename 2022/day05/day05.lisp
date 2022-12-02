;;;; Day###.lisp
;;;; 2022 AOC Day ### solution
;;;; Leo Laporte, Dec 2022

(ql:quickload '(:fiveam :cl-ppcre :alexandria))

(defpackage :day###
  (:use #:cl
	#:fiveam       ; for inline testing
	#:cl-ppcre     ; regex
	#:alexandria)) ; lil utilities

(in-package :day###)

(setf fiveam:*run-test-when-defined* t) ; test when compiling test code (for quick iteration)
(declaim (optimize (debug 3)))          ; max debugging info

(defparameter *data-file* "~/cl/AOC/2022/day###/input.txt")  ; supplied data from AoC

#|
--- Part One ---

|#



#|
--- Part Two ---

|#


;; (time (format t "The answer to AOC 2022 Day ### Part 1 is ~a" (day###-1 *data-file*)))
;; (time (format t "The answer to AOC 2022 Day ### Part 2 is ~a" (day###-2 *data-file*)))

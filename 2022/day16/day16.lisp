;;;; Day16.lisp
;;;; 2022 AOC Day 16 solution
;;;; Leo Laporte, 16 Jan 2022

;; -----------------------------------------------------------------------------
;; Prologue code for setup - same every day
;; -----------------------------------------------------------------------------

(ql:quickload '(:fiveam :cl-ppcre :str))

(defpackage :day16
  (:use #:cl)
  (:local-nicknames
   (:re :cl-ppcre)
   (:5a :fiveam)))

(in-package :day16)

(setf fiveam:*run-test-when-defined* t) ; test as we go
(declaim (optimize (debug 3)))          ; max debugging info
;; (declaim (optimize (debug 0) (speed 3) (safety 0))) ; max speed if needed

(defparameter *data-file* "~/cl/AOC/2022/day16/input.txt")  ;  data from AoC

#| --------------------- Day 16: Proboscidea Volcanium -------------------------

You scan the cave for other options and discover a network of pipes and
pressure-release valves. You aren't sure how such a system got into a volcano,
but you don't have time to complain; your device produces a report (your puzzle
input) of each valve's flow rate if it were opened (in pressure per minute) and
the tunnels you could use to move between the valves.

You estimate it will take you one minute to open a single valve and one minute
to follow any tunnel from one valve to another. What is the most pressure you
could release?

NOTES:

This is really interesting. I'm not going to think about part two at
all. Focusing on the problem at hand... The valves are a symmetric directed
graph in which every path can go either way so this is a pathfinding
problem. But we can only make 30 moves to get the most pressure so it's a
longest path problem, not shortest path. It's kind of a hybrid.

Additionally, the problem input has 66 valves, but only around 16 are
unbroken. So I think that means we can think of the 0 flow rooms as just part of
a longer path.

----------------------------------------------------------------------------- |#

(defparameter *example-data*
  '("Valve AA has flow rate=0; tunnels lead to valves DD, II, BB"
    "Valve BB has flow rate=13; tunnels lead to valves CC, AA"
    "Valve CC has flow rate=2; tunnels lead to valves DD, BB"
    "Valve DD has flow rate=20; tunnels lead to valves CC, AA, EE"
    "Valve EE has flow rate=3; tunnels lead to valves FF, DD"
    "Valve FF has flow rate=0; tunnels lead to valves EE, GG"
    "Valve GG has flow rate=0; tunnels lead to valves FF, HH"
    "Valve HH has flow rate=22; tunnel leads to valve GG"
    "Valve II has flow rate=0; tunnels lead to valves AA, JJ"
    "Valve JJ has flow rate=21; tunnel leads to valve II")
  "Example data from the problem")

(defstruct valve
  name      ; name of the valve (double caps)
  rate      ; rate of flow
  tunnels)  ; list of tunnels leading away

(defparameter *valve-regex*
  (re:create-scanner
   "Valve ([A-Z]{2}) has flow rate=(\\d+); tunnels? leads? to valves? (.*)")
  "a regular expression to separate out the content from the cruft")

(defun parse-valves (los)
  (labels ((parse-valve (s)
	     (re:register-groups-bind
		 (name  (#'parse-integer rate) tunnels)
		 (*valve-regex* s)

	       (make-valve
		:name name
		:rate rate
		:tunnels (re:split ", " tunnels)))))

    (mapcar #'parse-valve los)))

(defparameter *example* (parse-valves *example-data*))
(defparameter *data* (parse-valves (uiop:read-file-lines *data-file*)))

;; some really useful tips (spoilers?) here:
;; https://www.reddit.com/r/adventofcode/comments/zo21au/comment/j0nz8df/

;; first we need to calculate the distances (in time units) between all nodes
;; with a positive flow rate (zero flow rooms are just through-points). Using
;; Floyd-Warshall algo (call that cost)

;; Make a hash of rooms, costs, and flow-rates

;; DFS of rooms

;; track: valves that have already been opened (i.e. seen rooms)
;; time remaining (or if no more valves can be opened)





(5a:test day16-1-test
  (5a:is (= 1651 (day16-1 *example*))))

#| ---------------------------------- Part Two ---------------------------------


------------------------------------------------------------------------------|#

  ;; now solve the puzzle!
  ;; (time (format t "The answer to AOC 2022 Day 16 Part 1 is ~a"
  ;;	      (day16-1 (uiop:read-file-lines *data-file*))))

  ;; (time (format t "The answer to AOC 2022 Day 16 Part 2 is ~a"
  ;;	      (day16-2 (uiop:read-file-lines *data-file*))))

  ;; -----------------------------------------------------------------------------
  ;; Timings with SBCL on M2 MacBook Air with 24GB RAM
  ;; -----------------------------------------------------------------------------

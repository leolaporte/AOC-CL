;;;; Day16.lisp
;;;; 2023 AOC Day 16 solution
;;;; Leo Laporte
;;;; 27 February - 4 March 2024

;; ----------------------------------------------------------------------------
;; Prologue code for setup - same every day
;; ----------------------------------------------------------------------------

(ql:quickload '(:fiveam :cl-ppcre :trivia))

(defpackage :day16
  (:use #:cl #:iterate)  ; use iter instead of LOOP
  (:local-nicknames
   (:re :cl-ppcre)   ; regular expressions
   (:tr :trivia)     ; pattern matching
   (:5a :fiveam)))   ; testing

(in-package :day16)

(setf 5a:*run-test-when-defined* t)  ; test as we go
(declaim (optimize (debug 3)))       ; max debugging info
;; (declaim (optimize (speed 3))     ; max speed if needed

(defparameter *data-file* "~/cl/AOC/2023/Day_16/input.txt"
  "Downloaded from the AoC problem set")

#| ----------------------------------------------------------------------------
                --- Day 16: The Floor Will Be Lava ---
                           --- Part One ---

"The beam enters in the top-left corner from the left and heading to
the right. Then, its behavior depends on what it encounters as it
moves:

- If the beam encounters empty space (.), it continues in the same
direction.

- If the beam encounters a mirror (/ or \), the beam is reflected 90
degrees depending on the angle of the mirror. For instance, a
rightward-moving beam that encounters a / mirror would continue
upward in the mirror's column, while a rightward-moving beam that
encounters a \ mirror would continue downward from the mirror's
column.

- If the beam encounters the pointy end of a splitter (| or -), the
beam passes through the splitter as if the splitter were empty
space. For instance, a rightward-moving beam that encounters a -
splitter would continue in the same direction.

- If the beam encounters the flat side of a splitter (| or -), the
beam is split into two beams going in each of the two directions the
splitter's pointy ends are pointing. For instance, a
rightward-moving beam that encounters a | splitter would split into
two beams: one that continues upward from the splitter's column and
one that continues downward from the splitter's column.

Beams do not interact with other beams; a tile can have many beams
passing through it at the same time. A tile is energized if that tile
has at least one beam pass through it, reflect in it, or split in it.

With the beam starting in the top-left heading right, how many tiles
end up being energized?"

LEO'S NOTES: Let's do the sparse hash thing again.

We can record the ENERGIZED tiles as a list. We'll also need a list of
BEAMS (since multiple beams can be created). I'll make BEAM a struct
with x y and heading.

The problem doesn't say when the processing ends, though. Is it when a
beam goes off the grid? Repeats infinitely? Once a beam is on the same
point with the same heading it will repeat infinitely so we no longer
need to track it. I'll have to keep track of where the beam has been
and what direction it's heading in in another list: VISITED with
position and heading as (cons pos dir). If I do that I don't need the
ENERGIZED list - I can just look at all the visited fields.

Also every move can result in more beams being created. So I'll have a
list of beams that are currently active and add to them when I
split. When the beam is either off the grid (never to return) or in a
repeating cycle I can stop processing it so I'll remove it from the
BEAMS list. When the list is empty the process is done and we can
count the (deduplicated) list of activated points.

Also Eric tips his hand with the last paragraph. Part two will
probably involve modifying the grid to produce more power? Which may
involve many runs through the grid. I'll keep that in mind.

One little bug: what if (0 0) is a mirror! I didn't account for that
so a little fix in the main routine.

---------------------------------------------------------------------------- |#

(defparameter *sample1-file* "~/cl/AOC/2023/Day_16/sample.txt"
  "have to do it this way because lisp treats slashes as special characters")
(defparameter *sample1* (uiop:read-file-lines *sample-file*))

(defparameter *sample2-file* "~/cl/AOC/2023/Day_16/sample2.txt"
  "have to do it this way because lisp treats slashes as special characters")
(defparameter *sample2* (uiop:read-file-lines *sample2-file*))

(defparameter *sample3-file* "~/cl/AOC/2023/Day_16/sample3.txt"
  "have to do it this way because lisp treats slashes as special characters")
(defparameter *sample3* (uiop:read-file-lines *sample3-file*))

(defparameter *visited* '()
  "GLOBAL! list of energized points")

(defparameter *beams* '()
  "GLOBAL! list of active beam structures")

(defstruct (beam)
  "a light beam (there may be many at any given time)"
  (pos (cons 0 0) :type cons) ; current location (cons ROW COL)
  (dir 'E :type symbol))      ; heading one of 'N 'E 'S 'W

(defun make-sparse-hash (los)
  "given a list of chars representing a 2D array of . / \ | or - make a
hash of all characters except . with key being the (cons row col)
coordinates of the char and the value being the char, store an
additional item for height and width: 'dim => (cons width height)"
  (let* ((width (length (first los)))
         (height (length los))
         (grid (make-hash-table :test 'equal :size (* width height))))

    (setf (gethash 'dim grid) (cons width height)) ; for range checks

    (iter (for row below height)
      (iter (for col below width)
        (let ((x (elt (nth row los) col)))
          (unless (char= x #\.)
            (setf (gethash (cons row col) grid) x)))))
    grid))

(Defun pht (hash)
  "little utility to print a hash"
  (iter (for (key value) in-hashtable hash)
    (format t "~%~A => ~A" key value)))

(defun row (pos)
  "help me remember that row is the car in a position cons"
  (car pos))

(defun col (pos)
  "help me remember that col is the cdr in a position cons"
  (cdr pos))

(defun next-pos (pos dir grid)
  "given a point, moves in the direction and returns the next point
as (cons row col) or nil if it's off the grid"
  (let ((width (car (gethash 'dim grid)))
        (height (cdr (gethash 'dim grid)))
        (new-pos (tr:match dir  ; one of...
                   ('N (cons (1- (row pos)) (col pos)))
                   ('S (cons (1+ (row pos)) (col pos)))
                   ('E (cons (row pos) (1+ (col pos))))
                   ('W (cons (row pos) (1- (col pos))))
                   (otherwise (error "Unknown direction ~A" dir)))))

    ;; make sure we're still on the grid
    (if (or (>= (row new-pos) height)
            (< (row new-pos) 0)
            (>= (col new-pos) width)
            (< (col new-pos) 0))
        nil
        new-pos)))

(5a:test next-pos-test
  (let ((grid (make-sparse-hash *sample*)))
    (5a:is (equal (next-pos (cons 0 0) 'N grid) nil))
    (5a:is (equal (next-pos (cons 3 5) 'N grid) (cons 2 5)))
    (5a:is (equal (next-pos (cons 3 5) 'E grid) (cons 3 6)))
    (5a:is (equal (next-pos (cons 3 5) 'W grid) (cons 3 4)))
    (5a:is (equal (next-pos (cons 9 9) 'S grid) nil))))

(defun next-mirror (pos dir grid)
  "given a position and direction 'N 'E 'W 'S to move on a sparse hash
grid, return the next populated position as (cons row col) or nil if
the move is off the grid, track all visited positions in VISITED as
energized"
  (let ((new-pos (next-pos pos dir grid))) ; next coordinate

    (iter
      (while (and new-pos                        ; on the grid
                  (not (gethash new-pos grid)))) ; but not on a mirror

      (push (cons new-pos dir) *visited*)        ; record visit
      (setf new-pos (next-pos new-pos dir grid)) ; keep moving

      ;; either off grid (nil) or on a mirror/splitter (cons x y)
      (finally (return new-pos)))))

(5a:test next-mirror-test
  (let ((grid (make-sparse-hash *sample*)))
    (5a:is (equal (next-mirror (cons 0 0) 'N grid) nil))
    (5a:is (equal (next-mirror (cons 2 0) 'E grid) (cons 2 5)))
    (5a:is (equal (next-mirror (cons 0 9) 'W grid) (cons 0 5)))
    (5a:is (equal (next-mirror (cons 3 8) 'S grid) nil))))

(defun next-dir (pos dir grid)
  "given a position on a mirror/splitter and a heading, return the next
heading if it's a mirror, or if it's a splitter continue on if it's
hitting it head on, or split into two beams, push the new beam on
*BEAMS* and return the new heading for the exisiting beam"
  (let ((mirror (gethash pos grid)))  ; char at position

    (cond ((char= mirror #\\)         ; change dir
           (cond ((equal dir 'N) 'W)
                 ((equal dir 'E) 'S)
                 ((equal dir 'W) 'N)
                 ((equal dir 'S) 'E)))

          ((char= mirror #\/)         ; change dir
           (cond ((equal dir 'N) 'E)
                 ((equal dir 'E) 'N)
                 ((equal dir 'W) 'S)
                 ((equal dir 'S) 'W)))

          ((char= mirror #\|)           ; split or do nothing
           (cond ((or (equal dir 'N) (equal dir 'S)) dir)
                 ((or (equal dir 'E) (equal dir 'W))
                  ;; it's a split so make a new beam going 'S
                  (push (make-beam :pos pos :dir 'S) *beams*)
                  (push (cons pos 'S) *visited*)
                  ;; and aim original beam 'N
                  'N)))

          ((char= mirror #\-)           ; split or do nothing
           (cond ((or (equal dir 'E) (equal dir 'W)) dir)
                 ((or (equal dir 'S) (equal dir 'N))
                  ;; it's a split so make a new beam going 'E
                  (push (make-beam :pos pos :dir 'E) *beams*)
                  (push (cons pos 'E) *visited*)
                  ;; and aim original beam 'W
                  'W)))

          (t (error "What is that?? ~A" mirror)))))

(5a:test next-dir-test
  (let ((grid (make-sparse-hash *sample*)))
    (5a:is (equal (next-dir (cons 5 9) 'S grid) 'E))
    (5a:is (equal (next-dir (cons 1 2) 'E grid) 'E))
    (5a:is (equal (next-dir (cons 1 2) 'W grid) 'W))
    (5a:is (equal (next-dir (cons 0 5) 'N grid) 'W))))

(defun move-one (grid)
  "given a mirror grid, move the first beam in the *BEAMS* list in its
current direction until it hits a mirror, returns to a previous pos
and heading, or goes off the grid. Remove BEAM from *BEAMS* list if
it's off the grid or repeating a previous path, otherwise move it to
the next position, update the heading, and, if indicated, make another
beam (split). Modifies the global *BEAMS* and *VISITED* lists."
  (let* ((beam (pop *beams*))         ; pop the top beam off the stack
         (pos (beam-pos beam))        ; position before moving
         (dir (beam-dir beam))        ; active beam's heading
         (new-pos (next-mirror pos dir grid))) ; the next position

    ;; is beam still on grid?
    (when (null new-pos)         ; off-grid
      (return-from move-one))    ; leave beam off stack and return

    ;; it's sitting on a mirror
    (setf (beam-pos beam) new-pos)
    (setf (beam-dir beam) (next-dir new-pos dir grid))

    ;; have we already seen this new position and heading? no need to
    ;; re-litigate. Leave the beam off the stack and get the next one
    (when (member
           (cons (beam-pos beam) (beam-dir beam)) *visited* :test #'equalp)
      (return-from move-one))

    ;; save the results of our labors
    (push (cons (beam-pos beam) (beam-dir beam)) *visited*)
    (push beam *beams*))) ; put updated beam back on stack

(defun count-energized-tiles ()
  "returns the number of unique tiles that have been visited by one or
more beams"
  (let ((energized '()))
    ;; strip direction info from visited
    (iter (for v in *visited*)
      (push (first v) energized) ; strip off dir - just get pos
      (finally (return (length
                        (remove-duplicates energized :test #'equal)))))))

(defun Day16-1 (los start-pos start-dir)
  "Given a list of strings reflecting a field of mirrors, and a starting
point and direction, return the number of energized points once all
the beams are done"
  (let ((grid (make-sparse-hash los)))

    ;; set up the globals

    ;; special case - if initial square is a mirror
    ;; process it before moving to next position
    (cond ((gethash start-pos grid) ; starting on a mirror
           (let ((new-dir (next-dir start-pos start-dir grid)))
             (setf *beams*
                   (list (make-beam :pos start-pos :dir new-dir)))
             (setf *visited*
                   (list (cons start-pos new-dir)))))

          (t ; otherwise
           (setf *beams*
                 (list (make-beam :pos start-pos :dir start-dir))) ; start point
           (setf *visited*
                 (list (cons start-pos start-dir)))))  ; first point visited

    (iter (while *beams*) ; while there are beams left
      (move-one grid)
      (finally (return (count-energized-tiles))))))

(5a:test Day16-1-test
  (5a:is (= 46 (Day16-1 *sample1* (cons 0 0) 'E)))
  (5a:is (= 51 (Day16-1 *sample1* (cons 0 3) 'S)))
  (5a:is (= 28 (Day16-1 *sample2* (cons 0 0) 'E)))
  (5a:is (= 2 (Day16-1 *sample3* (cons 0 0) 'E))))

#| ----------------------------------------------------------------------------
                           --- Part Two ---

"a collection of buttons lets you align the contraption so that the beam enters from any edge tile and heading away from that edge. (You can choose either of two directions for the beam if it starts on a corner; for instance, if the beam starts in the bottom-right corner, it can start heading either left or upward.)"

Find the initial beam configuration that energizes the largest number of tiles; how many tiles are energized in that configuration?"

LEO'S NOTES: This should be simple to brute force since there are only (+ (* 2 height) (* 2 width) 4) tests (in other word perimeter + 4)

---------------------------------------------------------------------------- |#

(defun make-perimeter-points (los)
  "given a list of strings representing a grid, return a list of (cons
pos dir) for each perimeter point on the grid"
  (let ((width (length (first los)))
        (height (length los))
        (start-points '()))

    (iter (for col below width)
      (push (cons (cons 0 col) 'S) start-points)
      (push (cons (cons (1- height) col) 'N) start-points))

    (iter (for row below height)
      (push (cons (cons row 0) 'E) start-points)
      (push (cons (cons row (1- width)) 'W) start-points))

    start-points))

(defun Day16-2 (los)
  "given a list of strings reflecting a field of mirrors and splitters,
 try every starting point on the perimeter of the field to find the
 one that returns the hightst number of energized points"
  (iter (for s in (make-perimeter-points los))
    (maximize (day16-1 los (car s) (cdr s)))))

(5a:test Day16-2-test
  (5a:is (= 51 (day16-2 *sample*))))

;; now solve the puzzle!
(time (format t "The answer to AOC 2023 Day 16 Part 1 is ~a"
              (day16-1 (uiop:read-file-lines *data-file*) (cons 0 0) 'E)))

(time (format t "The answer to AOC 2023 Day 16 Part 2 is ~a"
              (day16-2 (uiop:read-file-lines *data-file*))))

;; ----------------------------------------------------------------------------
;; Timings with SBCL on M3-Max MacBook Pro with 64GB RAM
;; ----------------------------------------------------------------------------

;; The answer to AOC 2023 Day 16 Part 1 is 7392
;; Evaluation took:
;; 0.061 seconds of real time
;; 0.061423 seconds of total run time (0.061376 user, 0.000047 system)
;; 100.00% CPU
;; 1,726,176 bytes consed

;; The answer to AOC 2023 Day 16 Part 2 is 7665
;; Evaluation took:
;; 16.293 seconds of real time
;; 16.279503 seconds of total run time (16.264539 user, 0.014964 system)
;; [ Real times consist of 0.021 seconds GC time, and 16.272 seconds non-GC time. ]
;; [ Run times consist of 0.021 seconds GC time, and 16.259 seconds non-GC time. ]
;; 99.92% CPU
;; 516,828,736 bytes consed

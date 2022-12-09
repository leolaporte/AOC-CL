;;;; day07.lisp
;;;; 2022 AOC Day 07 solution
;;;; Leo Laporte, 07 Dec 2022

;;----------------------------------------------------------------------------------------------------
;; Prologue code for setup - same every day
;;----------------------------------------------------------------------------------------------------
(ql:quickload '(:fiveam :cl-ppcre :str))

(defpackage :day07
  (:use #:cl)
  (:local-nicknames
   (:5a :fiveam)
   (:re :cl-ppcre)))

(in-package :day07)

(setf fiveam:*run-test-when-defined* t) ; test when compiling test code (for quick iteration)

(defparameter *data-file* "~/cl/AOC/2022/day07/input.txt")  ; supplied data from AoC

#| ----------------------------------------------------------------------------------------------------

--- Day 7: No Space Left On Device ---

--- Part One ---

To begin, find all of the directories with a total size of at most 100000, then calculate the
sum of their total sizes. In the example above, these directories are a and e; the sum of their
total sizes is 95437 (94853 + 584). (As in this example, this process can count files more than once!)

Find all of the directories with a total size of at most 100000. What is the sum of the total
sizes of those directories?

NOTES: Find the total size of all the directories with size <= 100,000
Seems like I need to build a tree but let's think. All I nreally need is the size
of each directory. I can represent the directory tree with a list of dirs. Each item in the
list includes name, size, and a list of sub-dirs. I don't have to keep track of filenames, just
their sizes. Or better yet, add each file to the dir size directly. This should do for part 1.
I can use the normal list manipulation tools to process the command list, then recursively sum all
the sizes into a hash table of dir->size. Let's go.
---------------------------------------------------------------------------------------------------- |#

(defparameter *test-data* ; provided in the problem description
  '("$ cd /"
    "$ ls"
    "dir a"
    "14848514 b.txt"
    "8504156 c.dat"
    "dir d"
    "$ cd a"
    "$ ls"
    "dir e"
    "29116 f"
    "2557 g"
    "62596 h.lst"
    "$ cd e"
    "$ ls"
    "584 i"
    "$ cd .."
    "$ cd .."
    "$ cd d"
    "$ ls"
    "4060174 j"
    "8033020 d.log"
    "5626152 d.ext"
    "7214296 k"))

;; (defclass tr ()
;;   ((name :initarg :name :initform (error "Must supply directory name"))
;;    (size :initarg :size :initform 0)
;;    (subs :initarg :subs :initform nil)))

(defparameter *my-test-tree* ; my own mini-tree to test the tree utilities
  '(("e" 0 nil) ; a directory with no sub-dirs and no size
    ("d" 40 nil) ; a dir with no sub-dirs a size 40
    ("c" 30 '("e")) ; a dir with sub-dir e and size 30
    ("b" 20 '("c" "d"))
    ("/" 10 '("b"))))

;; utilties for finding, adding, and updating dirs
(defun dir-find (dir tree)
  "returns the dir entry in tree"
  (assoc dir tree :test 'equalp))

(defun dir-remove (dir tree)
  "returns a tree with dir removed"
  (remove (dir-find dir tree) tree))

(defun dir-add (name cwd tree)
  "given a new dir, the current working directory and a dir tree, create the new directory
and add it to the tree while updating cwd's sub-dirs list, returns the updated tree"
  (let* ((old-cwd (dir-find cwd tree))      ; save the old cwd
	 (new-dir (list name 0 '()))        ; make the new dir, size 0 no sub-dirs. Yet.
	 (updated-cwd (list (first old-cwd) ; rebuild cwd updating the sub dir list
			    (second old-cwd)
			    (cons name (third old-cwd))))) ; add new dir to sub-dirs list
    (cons new-dir                          ; add the new dir to the tree
	  (cons updated-cwd                ; replace outdated cwd entry with updated cwd
		(dir-remove cwd tree)))))  ; remove outdated cwd entry

(5a:test dir-add-test  ; tests find and remove indirectly
  (5a:is (equal '(("f" 0 NIL) ("e" 0 ("f")) ("d" 40 NIL) ("c" 30 '("e")) ("b" 20 '("c" "d"))
		  ("/" 10 '("b")))
		(dir-add "f" "e" *my-test-tree*)))
  (5a:is (equal '(("a" 0 nil) ("/" 0 ("a"))) (dir-add "a" "/" '(("/" 0 nil))))))

(defun inc-file-size (size cwd tree)
  "adds the size of a file to the total size of the cwd"
  (let* ((old-info (dir-find cwd tree))                    ; save the old cwd info
	 (new-info (list (first old-info)                  ; create a new cwd
			 (incf (second old-info) size)     ; incrementing the size
			 (third old-info))))
    (cons new-info (dir-remove cwd tree))))                ; replace old info with new

(5a:test inc-file-size-test
  (5a:is (equal '(("a" 10 nil) ("b" 0 nil))
		(inc-file-size 10 "a" '(("a" 0 nil) ("b" 0 nil))))))

(defun dir-size (dir tree)
  "given a dir name as a string, return the size of that dir in tree"
  (let ((item (dir-find dir tree)))
    (if item            ; if tree exists
	(second item)   ; return its size
	0)))            ; otherwise 0

(5a:test dir-size-test
  (5a:is (= 10 (dir-size "b" '(("a" 20 nil) ("b" 10 nil))))))

(defun branch-size (branch tree)
  "returns the size of a tree branch including the sizes of all its subdirs"
  (+ (second branch)                        ; the size of the dir
     (sub-dir-size (third branch) tree)))   ; the sizes of all the sub-dirs

(defun sub-dir-size (sds tree)
  "given a list of dirs return the total used by all the subdirs and their subdirs (CAR/CDR recursion)"
  (cond ((null sds) 0)
	(t (+ (dir-size (first sds) tree)
	      (sub-dir-size (third (dir-find (first sds) tree)) tree)
	      (sub-dir-size (rest sds) tree)))))

(5a:test branch-size-test
  (5a:is (= 0 (branch-size (first *my-test-tree*) *my-test-tree*)))
  (5a:is (= 40 (branch-size (second *my-test-tree*) *my-test-tree*)))
  (5a:is (= 30 (branch-size (third *my-test-tree*) *my-test-tree*)))
  (5a:is (= 20 (branch-size (fourth *my-test-tree*) *my-test-tree*)))
  (5a:is (= 10 (branch-size (fifth *my-test-tree*) *my-test-tree*))))

;; the workhorse - processes all the directory commands to build a dir tree
(defun process-cmds (commands)
  "return a directory tree created by interpreting the list of commands"

  (let ((tree (list '("/" 0 nil)))   ; the root directory tree - the starting point
	(cwd (list "/")))       ; a stack of directories, (first cwd) is the current working directory

    (dolist (cmd commands tree) ; for every cmd in commands do the following, return tree
      (let ((c (re:split " " cmd)))             ; make list of words in command
	(unless (equal (second c) "ls")         ; just skip this command - there's nothing to do
	  (cond ((and (equalp (second c) "cd")
		      (equalp (third c) ".."))  ; cmd is "cd .."
		 (pop cwd))                     ; go up a dir by popping off the most recent dir

		((equalp (second c) "cd")       ; cmd is cd dir
		 (push (third c) cwd))          ; make dir the current dir

		((equalp (first c) "dir")  ; cmd is "dir x"
		 ;; add the new dir to the tree
		 (setf tree (dir-add (second c) (first cwd) tree)))

		(t ; otherwise it must be a file
		 ;; add the file's size to the directory size
		 (setf tree (inc-file-size (parse-integer (first c)) (first cwd) tree)))))))))

(5a:test dir-size-test
  (let ((tt (process-cmds *test-data*)))   ; tree generated from AoC provided instructions
    (5a:is (= 584 (branch-size (dir-find "e" tt) tt)))  ; ditto answers
    (5a:is (= 94853 (branch-size (dir-find "a" tt) tt)))
    (5a:is (= 24933642 (branch-size (dir-find "d" tt) tt)))
    (5a:is (= 48381165 (branch-size (dir-find "/" tt) tt)))))

(defun sum-dir-sizes (tree)
  "given a tree return the sums of all the directory sizes <= 100,000"
  (reduce #'+                                      ; add up remaining dirs
	  (remove-if #'(lambda (x) (> x 100000))   ; prune dirs > 100000K
		     (mapcar              ; turn tree into list of dir sizes
		      #'(lambda (branch) (branch-size branch tree)) ; get size of this branch
		      tree))))           ; start with dir tree generated with instructions

(5a:test sum-dir-sizes-test
  (5a:is (= (+ 40 30 20 30 10 40 20 30)
	    (sum-dir-sizes '(("d" 40 NIL) ("e" 30 NIL) ("a" 20 ("e")) ("/" 10 ("d" "a"))))))
  (5a:is (= (+ 100 50) ; d and / are both > 100,000
	    (sum-dir-sizes '(("d" 100001 nil) ("c" 100 nil) ("b" 50 nil) ("/" 40 ("d" "c" "b"))))))
  (5a:is (= (+ 100 50 100)
	    (sum-dir-sizes '(("d" 100001 nil) ("c" 100 nil) ("b" 50 ("c")) ("/" 40 ("b" "d")))))))

(defun day07-1 (instruction-list)
  (sum-dir-sizes
   (process-cmds instruction-list)))

(5a:test day07-1-test
  (5a:is (= 95437 (day07-1 *test-data*))))


#|
--- Part Two ---

|#

;; now solve the puzzle!
(time (format t "The answer to AOC 2022 Day 07 Part 1 is ~a"
	      (day07-1 (uiop:read-file-lines *data-file*))))


;; (time (format t "The answer to AOC 2022 Day 07 Part 2 is ~a"
;;	      (day07-2 (uiop:read-file-lines *data-file*))))

;; --------------------------------------------------------------------------------
;; Timings with SBCL on M2 MacBook Air with 24GB RAM
;; --------------------------------------------------------------------------------

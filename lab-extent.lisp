(defmacro rgb-xyz-correct-channel (chan)
  `(setf ,chan (* 100 (if (> ,chan 0.04045)
                          (expt (/ (+ ,chan 0.055) 1.055) 2.4)
                          (/ ,chan 12.92)))))

(defmacro linear-combine (wr wg wb)
  `(+ (* vr ,wr) (* vg ,wg) (* vb ,wb)))

(defparameter *ref_x*  95.047)
(defparameter *inv_ref_x* (/ 1 *ref_x*))
(declaim (type single-float *inv_ref_x*))

(defparameter *ref_y* 100.000)
(defparameter *inv_ref_y* (/ 1 *ref_y*))
(declaim (type single-float *inv_ref_y*))

(defparameter *ref_z* 108.883)
(defparameter *inv_ref_z* (/ 1 *ref_z*))
(declaim (type single-float *inv_ref_z*))

(defparameter *inv255* (/ 1 255.0))
(declaim (type single-float *inv255*))

(defun rgb-xyz (r g b) 
  (declare (unsigned-byte r g b))
  (let ((vr (* r *inv255*))
        (vg (* g *inv255*))
        (vb (* b *inv255*)))
    (declare (single-float vr vg vb))
    (rgb-xyz-correct-channel vr)
    (rgb-xyz-correct-channel vg)
    (rgb-xyz-correct-channel vb)
    (values
     (linear-combine 0.4124 0.3576 0.1805)
     (linear-combine 0.2126 0.7152 0.0722)
     (linear-combine 0.0193 0.1192 0.9505))))

(defun clip (v mi ma) 
  (if (> v ma)
      ma
      (if (< v mi)
          mi
          v)))

(defmacro xyz-rgb-correct-channel (chan)
  `(progn (setf ,chan
                (round
                 (the single-float
                      (clip
                       (the single-float
                            (* 255.0 (if (> ,chan 0.0031308)
                                         (- (* 1.055 (expt ,chan (/ 2.4)))
                                            0.055)
                                         (* 12.92 ,chan))))
                       0.0
                       255.0))))))

(defun xyz-rgb (x y z)
  (declare (single-float x y z))
  (let ((vr (* x 0.01))
        (vg (* y 0.01))
        (vb (* z 0.01)))
    (declare (single-float vr vg vb))
    (let ((vr (linear-combine 3.2406 -1.5372 -0.4986))
          (vg (linear-combine -0.9692 1.8758 0.0415))
          (vb (linear-combine 0.0557 -0.2040 1.0570)))
      (xyz-rgb-correct-channel vr)
      (xyz-rgb-correct-channel vg)
      (xyz-rgb-correct-channel vb)
      (values vr vg vb))))


(defmacro xyz-lab-correct-channel (chan)
  `(setf ,chan (if (> ,chan 0.008856)
                   (expt ,chan (/ 1 3))
                   (+ (/ 16.0 116) (* ,chan 7.787)))))

(defun xyz-lab (x y z)
  (declare (single-float x y z))
  (let ((vx (* x *inv_ref_x*))
        (vy (* y *inv_ref_y*))
        (vz (* z *inv_ref_z*)))
    (xyz-lab-correct-channel vx)
    (xyz-lab-correct-channel vy)
    (xyz-lab-correct-channel vz)
    (values (- (* 116 vy) 16)
            (* 500 (- vx vy))
            (* 200 (- vy vz)))))

(defun cube (x)
  (* x (* x x)))

(defun lab-xyz (l a b)
  (let*  ((fy (/ (+ l 16.0) 116.0))
          (fz (- fy (/ b 200.0)))
          (fx (+ fy (/ a 500.0)))
          (fx3 (cube fx))
          (fz3 (cube fz)))
    (let ((k 903.3)
          (e 0.008856))
      (let ((x (if (> fx3 e)
                   fx3
                   (/ (- (* 116.0 fx) 16) k)))
            (y (if (> l (* k e))
                   (cube fy)
                   (/ l k)))
            (z (if (> fz3 e)
                   fz3
                   (/ (- (* 116.0 fz) 16) k))))
        (values
         (* x *ref_x*)
         (* y *ref_y*)
         (* z *ref_z*))))))


(defun rgb-lab (r g b)
  (multiple-value-bind (x y z) (rgb-xyz r g b)
    (xyz-lab x y z)))

(defun lab-rgb (l a b)
  (multiple-value-bind (x y z) (lab-xyz l a b)
    (xyz-rgb x y z)))

(defun get-lab-list ()
  (loop for r from 0 to 255
     append (loop for g from 0 to 255
               append (loop for b from 0 to 255
                         collect (multiple-value-list (rgb-lab r g b))))))

(defun get-rgb-lab-extants ()
  (let ((lab-list (get-lab-list)))
    (loop for (l a b) in lab-list
       maximizing l into mal
       maximizing a into maa
       maximizing b into mab
       minimizing l into mil
       minimizing a into mia
       minimizing b into mib
       finally (return (list (list mal mil)
                             (list maa mia)
                             (list mab mib))))))

(defun square (x)
  (* x x))

(defun dist-3 (x1 y1 z1 x2 y2 z2)
  (sqrt (+ (square (- x1 x2))
           (square (- y1 y2))
           (square (- z1 z2)))))

;; using the above code, I get ((100.0 0.0) (98.254234 -86.18462) (94.48248 -107.863686))
(defparameter *rgb-lab-extants* '((100.0 0.0) (98.254234 -86.18462) (94.48248 -107.863686)))

(defun get-max-lab-distance ()
  ;; THIS IS A SUPER UGLY FUNCTION: I COULD HAVE USED MACROS TO MAKE
  ;; IT SMALLER, BUT IT WORKS
  (loop for l1 in (first *rgb-lab-extants*) maximizing
       (loop for a1 in (second *rgb-lab-extants*) maximizing
            (loop for b1 in (third *rgb-lab-extants*) maximizing
                 (loop for l2 in (first *rgb-lab-extants*) maximizing
                      (loop for a2 in (second *rgb-lab-extants*) maximizing
                           (loop for b2 in (third *rgb-lab-extants*) maximizing
                                (dist-3 l1 a1 b1 l2 a2 b2))))))))


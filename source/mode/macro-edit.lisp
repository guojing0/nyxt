;;;; SPDX-FileCopyrightText: Atlas Engineer LLC
;;;; SPDX-License-Identifier: BSD-3-Clause

(uiop:define-package :nyxt/macro-edit-mode
  (:use :common-lisp :nyxt)
  (:documentation "Mode for editing macros."))
(in-package :nyxt/macro-edit-mode)

(define-mode macro-edit-mode ()
  "Mode for creating and editing macros."
  ((name
    ""
    :documentation "The name used for the macro."
    :accessor nil)
   (functions
    (make-hash-table)
    :documentation "A hash table of functions the user has added to their
macro. The key represents a unique identifier for a command, and the value
represents a command.")))

(define-internal-page-command edit-macro ()
    (buffer "*Macro edit*" 'nyxt/macro-edit-mode:macro-edit-mode)
  "Edit a macro."
  (spinneret:with-html-string
    (:style (style buffer))
    (:h1 "Macro edit")
    (:p "Name")
    (:input :type "text" :id "macro-name")
    (:p "Commands")
    (:p (:button :class "button"
                 :onclick (ps:ps (nyxt/ps:send-lisp-url (nyxt/macro-edit-mode::add-command)))
                 "+ Add command"))
    (:div :id "commands" "")
    (:br)
    (:hr)
    (:button :class "button"
             :onclick (ps:ps (nyxt/ps:send-lisp-url '(nyxt/macro-edit-mode::save-macro)))
             "Save macro")
    (:button :class "button"
             :onclick (ps:ps (nyxt/ps:send-lisp-url '(nyxt/macro-edit-mode::evaluate-macro)))
             "Evaluate macro")))

(defmethod render-functions ((macro-editor macro-edit-mode))
  (flet ((render-functions ()
           (spinneret:with-html-string
             (:table
              (loop for key being the hash-keys of (functions macro-editor)
                    using (hash-value value)
                    collect (:tr (:td (:button :class "button"
                                               :onclick (ps:ps (nyxt/ps:send-lisp-url
                                                                `(nyxt/macro-edit-mode::remove-function
                                                                  (current-mode 'macro-edit-mode)
                                                                  ,key)))
                                               "✕"))
                                 (:td (:button :class "button"
                                               :onclick (ps:ps (nyxt/ps:send-lisp-url
                                                                `(nyxt/macro-edit-mode::command-help
                                                                  (current-mode 'macro-edit-mode)
                                                                  ,key)))
                                               "🛈"))
                                 (:td (symbol-name (name value)))))))))
    (ffi-buffer-evaluate-javascript-async
     (buffer macro-editor)
     (ps:ps
       (setf (ps:chain document (get-element-by-id "commands") |innerHTML|)
             (ps:lisp
              (render-functions)))))))

(defmethod command-help ((macro-editor macro-edit-mode) command-id)
  (nyxt::describe-command :command (name (gethash command-id (functions macro-editor)))))

(defmethod add-function ((macro-editor macro-edit-mode) command)
  (setf (gethash (parse-integer (symbol-name (gensym "")))
                 (functions macro-editor))
        command)
  (render-functions macro-editor))

(defmethod remove-function ((macro-editor macro-edit-mode) command-id)
  (remhash command-id (functions macro-editor))
  (render-functions macro-editor))

(defmethod name ((macro-editor macro-edit-mode))
  (let ((name (ffi-buffer-evaluate-javascript
               (buffer macro-editor)
               (ps:ps
                 (ps:chain document (get-element-by-id "macro-name") value)))))
    (cond ((not (str:emptyp name)) (setf (slot-value macro-editor 'name) name))
          ((slot-value macro-editor 'name) (slot-value macro-editor 'name))
          (t nil))))

(defmethod generate-macro-form ((macro-editor macro-edit-mode))
  (let ((name (intern (name macro-editor)))
        (commands (mapcar
                   (lambda (command) `(,(name command)))
                   (alexandria:hash-table-values (functions macro-editor)))))
    `(define-command-global ,name () "User generated macro form" ,@commands)))

(define-command add-command (&optional (macro-editor (current-mode 'macro-edit-mode)))
  "Add a command to the macro."
  (let ((command 
          (first
           (prompt
            :prompt "Add command"
            :sources (make-instance 'user-command-source)))))
    (add-function macro-editor command)))

(defmethod macro-form-valid-p ((macro-editor macro-edit-mode))
  (and (name macro-editor)
       (alexandria:hash-table-values (functions macro-editor))))

(define-command save-macro (&optional (macro-editor (current-mode 'macro-edit-mode)))
  "Save the macro to the auto-config.lisp file."
  (if (macro-form-valid-p macro-editor)
      (nyxt::append-configuration (generate-macro-form macro-editor))
      (echo "Macro form is invalid; check it has a title and functions.")))

(define-command evaluate-macro (&optional (macro-editor (current-mode 'macro-edit-mode)))
  "Evaluate the macro for testing."
  (if (macro-form-valid-p macro-editor)
      (progn (eval (generate-macro-form macro-editor)) (echo "Macro evaluated."))
      (echo "Macro form is invalid; check it has a title and functions.")))
